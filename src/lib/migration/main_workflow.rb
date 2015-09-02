# ------------------------------------------------------------------------------
# Copyright (c) 2015 SUSE GmbH, All Rights Reserved.
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
# this program; if not, contact SUSE GmbH.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require "yast"

Yast.import "Mode"
Yast.import "Sequencer"
Yast.import "Update"
Yast.import "Report"

require "migration/finish_dialog"
require "migration/restarter"

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
      "--cleanup-algorithm=number --print-number " \
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
      "ws_start"             => "start",
      "start"                => {
        start:   "create_pre_snapshot",
        restart: "migration_finish"
      },
      "create_pre_snapshot"  => {
        next: "create_backup"
      },
      "create_backup"        => {
        next: "repositories"
      },
      "repositories"         => {
        abort: "restore",
        next:  "proposals"
      },
      "proposals"            => {
        abort: "restore",
        next:  "perform_update"
      },
      "perform_update"       => {
        abort: :abort,
        next:  "restart_yast"
      },
      "restore"              => {
        abort: :abort
      },
      "restart_yast"         => {
        next:  :next
      },
      # note: the steps after the YaST restart use the new code from
      # the updated (migrated) yast2-migration package!!
      "migration_finish"     => {
        abort: :abort,
        next:  "create_post_snapshot"
      },
      "create_post_snapshot" => {
        next: "finish_dialog"
      },
      "finish_dialog"        => {
        abort: :abort,
        next:  :next
      }
    }

    def aliases
      {
        "start"                => ->() { start },
        "create_pre_snapshot"  => ->() { create_pre_snapshot },
        "create_backup"        => ->() { create_backup },
        "restore"              => ->() { restore_state },
        "perform_update"       => ->() { perform_update },
        "proposals"            => ->() { proposals },
        "repositories"         => ->() { repositories },
        "restart_yast"         => ->() { restart_yast },
        # note: the steps after the YaST restart use the new code from
        # the updated (migrated) yast2-migration package!!
        "migration_finish"     => ->() { migration_finish },
        "create_post_snapshot" => ->() { create_post_snapshot },
        "finish_dialog"        => ->() { finish_dialog }
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

    def restore_state
      Yast::Update.restore_backup

      :abort
    end

    def repositories
      Yast::WFM.CallFunction("migration_repos", [{ "enable_back" => false }])
    end

    def proposals
      Yast::WFM.CallFunction("migration_proposals", [{ "hide_export" => true }])
    end

    def perform_update
      Yast::WFM.CallFunction("inst_prepareprogress")
      Yast::WFM.CallFunction("inst_kickoff")
      Yast::WFM.CallFunction("inst_rpmcopy")

      :next
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
      end

      :restart
    end

    # schedule YaST restart
    # return [Symbol] workflow symbol (always :next)
    def restart_yast
      # save the snapshot for later (after restart)
      Restarter.instance.restart_yast(pre_snapshot: pre_snapshot)
      :next
    end
  end
end
