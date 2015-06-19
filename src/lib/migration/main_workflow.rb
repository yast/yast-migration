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
Yast.import "Pkg"
Yast.import "Sequencer"
Yast.import "Update"
Yast.import "Report"

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
      Yast::Sequencer.Run(aliases, WORKFLOW_SEQUENCE)
    end

    private

    WORKFLOW_SEQUENCE = {
      "ws_start"        => "create_backup",
      "create_backup"   => {
        next: "repositories"
      },
      "repositories"    => {
        abort: "restore",
        next:  "proposals"
      },
      "proposals"       => {
        abort: "restore",
        next:  "create_snapshot"
      },
      "create_snapshot" => {
        next: "perform_update"
      },
      "perform_update"  => {
        next:  :next
      },
      "restore"         => {
        abort: :abort
      }
    }

    def aliases
      {
        "create_backup"   => ->() { create_backup },
        "create_snapshot" => ->() { create_snapshot },
        "restore"         => ->() { restore_state },
        "perform_update"  => ->() { perform_update },
        "proposals"       => ->() { proposals },
        "repositories"    => ->() { repositories }
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
      ret = Yast::WFM.CallFunction("repositories")
      Yast::Pkg.SourceLoad if ret != :abort

      ret
    end

    def proposals
      Yast::WFM.CallFunction("migration_proposals")
    end

    def perform_update
      Yast::WFM.CallFunction("inst_prepareprogress")
      Yast::WFM.CallFunction("inst_kickoff")
      Yast::WFM.CallFunction("inst_rpmcopy")

      :next
    end

    def create_snapshot
      perform_snapshot if snapper_configured?
      :next
    end

    def snapper_configured?
      out = Yast::SCR.Execute(Yast::Path.new(".target.bash_output"),
        FIND_CONFIG_CMD)

      log.info("Checking if Snapper is configured: \"#{FIND_CONFIG_CMD}\" " \
        "returned: #{out}")
      out["exit"] == 0
    end

    def perform_snapshot
      cmd = format(CREATE_SNAPSHOT_CMD,
        snapshot_type: :single,
        description:   "before update on migration")

      out = Yast::SCR.Execute(Yast::Path.new(".target.bash_output"), cmd)
      return :next if out["exit"] == 0

      log.error "Snapshot could not be created: #{cmd} returned: #{out}"
      Yast::Report.Error(_("Failed to create filesystem snapshot."))
    end
  end
end
