# ------------------------------------------------------------------------------
# Copyright (c) 2015 SUSE LLC, All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require "yast"

Yast.import "Mode"
Yast.import "Sequencer"
Yast.import "Update"
Yast.import "Report"
Yast.import "Pkg"
Yast.import "Installation"
Yast.import "PackageCallbacks"

require "migration/finish_dialog"
require "migration/restarter"
require "migration/patches"

module Migration
  # The goal of the class is to provide main single entry point to start
  # migration work-flow. It is UI oriented sequence.
  #
  class MainWorkflow
    include Yast::Logger
    include Yast::I18n

    FIND_CONFIG_CMD = "/usr/bin/snapper --no-dbus list-configs | " \
      "grep \"^root \" >/dev/null"

    CREATE_SNAPSHOT_CMD = "/usr/bin/snapper create --type=%{snapshot_type} " \
      "--cleanup-algorithm=number --print-number --userdata important=yes " \
      "--description=\"%{description}\""

    def self.run
      workflow = new
      workflow.run
    end

    def run
      textdomain "migration"
      Yast::Mode.SetMode("update")

      begin
        Yast::Wizard.CreateDialog
        Yast::Sequencer.Run(aliases, WORKFLOW_SEQUENCE)
      ensure
        Yast::Wizard.CloseDialog
      end
    end

    private

    # remeber the "pre" snapshot id (needed for the "post" snapshot)
    attr_accessor :pre_snapshot

    WORKFLOW_SEQUENCE = {
      "ws_start"                => "start",
      "start"                   => {
        start:                   "create_pre_snapshot",
        restart_after_update:    "online_update",
        restart_after_migration: "migration_finish"
      },
      "create_pre_snapshot"     => {
        next: "create_backup"
      },
      "create_backup"           => {
        next: "online_update"
      },
      "online_update"           => {
        abort:   :abort,
        restart: "restart_after_update",
        next:    "repositories"
      },
      "restart_after_update"    => {
        restart:  :restart
      },
      "repositories"            => {
        abort:    :abort,
        rollback: "rollback",
        next:     "proposals"
      },
      "proposals"               => {
        abort: "rollback",
        next:  "perform_migration"
      },
      "rollback"                => {
        abort: :abort,
        next:  :next
      },
      "perform_migration"       => {
        abort: :abort,
        next:  "restart_after_migration"
      },
      "restart_after_migration" => {
        restart:  :restart
      },
      # note: the steps after the YaST restart use the new code from
      # the updated (migrated) yast2-migration package!!
      "migration_finish"        => {
        abort: :abort,
        next:  "create_post_snapshot"
      },
      "create_post_snapshot"    => {
        next: "finish_dialog"
      },
      "finish_dialog"           => {
        abort: :abort,
        next:  :next
      }
    }

    def aliases
      {
        "start"                   => ->() { start },
        "create_pre_snapshot"     => ->() { create_pre_snapshot },
        "create_backup"           => ->() { create_backup },
        "online_update"           => ->() { online_update },
        "restart_after_update"    => ->() { restart_yast(:restart_after_update) },
        "rollback"                => ->() { rollback },
        "perform_migration"       => ->() { perform_migration },
        "proposals"               => ->() { proposals },
        "repositories"            => ->() { repositories },
        "restart_after_migration" => ->() { restart_yast(:restart_after_migration) },
        # note: the steps after the YaST restart use the new code from
        # the updated (migrated) yast2-migration package!!
        "migration_finish"        => ->() { migration_finish },
        "create_post_snapshot"    => ->() { create_post_snapshot },
        "finish_dialog"           => ->() { finish_dialog }
      }
    end

    def create_backup
      Yast::Update.clean_backup
      Yast::Update.create_backup(
        "repos",
        [
          "/etc/zypp/repos.d",
          "/etc/zypp/credentials.d",
          "/etc/zypp/services.d"
        ]
      )

      :next
    end

    def online_update
      return :abort unless init_pkg_mgmt

      patches = Patches.new
      return :next unless patches.available?

      # TRANSLATORS: popup question, confirm installing the available updates now
      question = _("There are some online updates available to installation,\n" \
          "it is recommended to install all updates before proceeding.\n\n" \
          "Would you like to install the updates now?")
      return :next unless Yast::Popup.YesNo(question)

      ui = patches.install
      # user canceled installing patches, continue without them...
      return :next if ui == :cancel || ui == :abort

      :restart
    end

    def rollback
      Yast::WFM.CallFunction("registration_sync")
      :abort
    end

    def repositories
      Yast::WFM.CallFunction("migration_repos", [{ "enable_back" => false }])
    end

    def proposals
      Yast::WFM.CallFunction("migration_proposals", [{ "hide_export" => true }])
    end

    def perform_migration
      # disable the default snapshots created by the zypp plugin
      ENV["DISABLE_SNAPPER_ZYPP_PLUGIN"] = "1"

      # this client is located in the yast2-installation package
      Yast::WFM.CallFunction("inst_prepareprogress")
      # this client is located in the yast2-packager package
      Yast::WFM.CallFunction("inst_kickoff")
      # this client is located in the yast2-packager package
      ret = Yast::WFM.CallFunction("inst_rpmcopy")
      log.info "inst_rpmcopy result: #{ret.inspect}"
      ret
    end

    def create_pre_snapshot
      if snapper_configured?
        self.pre_snapshot = perform_snapshot(:pre, "before online migration")
      end

      :next
    end

    def create_post_snapshot
      if snapper_configured? && pre_snapshot
        perform_snapshot(:post, "after online migration", pre_snapshot)
      end

      :next
    end

    def migration_finish
      # this client is located in the yast2-registration package
      Yast::WFM.CallFunction("migration_finish")
    end

    # check whether snapper is configured
    # @return [Boolean] true if snapper is configured
    def snapper_configured?
      out = Yast::SCR.Execute(Yast::Path.new(".target.bash_output"),
        FIND_CONFIG_CMD)

      log.debug "Checking snapper config: '#{FIND_CONFIG_CMD}'"
      log.info "Found snapper config: #{out}"

      out["exit"] == 0
    end

    # create a filesystem snapshot
    # @param [Symbol, String] type the type of the snapshot (:single, :pre or :post)
    # @param [String] desc description of the snapshot for users
    # @param [Fixnum] pre_id id of the respective "pre" snapshot (needed
    #   only for "post" type snapshots)
    # @return [Fixnum,nil] id of the created snapshot (nil if failed)
    def perform_snapshot(type, desc, pre_id = nil)
      cmd = format(CREATE_SNAPSHOT_CMD, snapshot_type: type, description: desc)
      cmd << " --pre-number=#{pre_id}" if pre_id

      log.info "Creating snapshot: #{cmd}"
      out = Yast::SCR.Execute(Yast::Path.new(".target.bash_output"), cmd)

      if out["exit"] == 0
        ret = out["stdout"].to_i
        log.info "Created snapshot: #{ret}"
        return ret
      end

      log.error "Snapshot could not be created: #{out}"
      Yast::Report.Error(_("Failed to create a filesystem snapshot."))
      nil
    end

    # display the finish dialog and optionally reboot the system
    # @return [Symbol] UI user input
    def finish_dialog
      dialog = Migration::FinishDialog.new
      ret = dialog.run

      if ret == :next && dialog.reboot
        log.info "Preparing the system for reboot..."
        Restarter.instance.reboot
      end

      ret
    end

    # evaluate the starting point for the workflow, start from the beginning
    # or continue after restarting the YaST
    # return [Symbol] workflow symbol
    def start
      return :start unless Restarter.instance.restarted

      # reload the stored snapshot id (from the previous run)
      if Restarter.instance.data.is_a?(Hash)
        self.pre_snapshot = Restarter.instance.data[:pre_snapshot]
        step = Restarter.instance.data[:step]
        return step if step
      end

      log.warn "No saved step found, starting from the beginning"
      :start
    end

    # schedule YaST restart
    # @param [String] step current step in the workflow
    # @return [Symbol] workflow symbol (always :restart)
    def restart_yast(step)
      # save the snapshot for later (after restart)
      Restarter.instance.restart_yast(pre_snapshot: pre_snapshot, step: step)
      :restart
    end

    def init_pkg_mgmt
      # display progress when refreshing repositories
      Yast::PackageCallbacks.InitPackageCallbacks

      ret = Yast::Pkg.TargetInitialize(Yast::Installation.destdir) &&
        Yast::Pkg.TargetLoad &&
        Yast::Pkg.SourceRestore &&
        Yast::Pkg.SourceLoad

      Yast::Report.Error(Yast::Pkg.LastError) unless ret

      ret
    end
  end
end
