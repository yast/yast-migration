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
Yast.import "Pkg"

module Migration
  # The goal of the class is to provide main single entry point to start
  # migration work-flow. It is UI oriented sequence.
  #
  class MainWorkflow
    include Yast::Logger

    def self.run
      workflow = new
      workflow.run
    end

    def run
      Yast::Mode.SetMode("update")
      Yast::Sequencer.Run(aliases, WORKFLOW_SEQUENCE)
    end

    private

    WORKFLOW_SEQUENCE = {
      "ws_start"     => "repositories", # TODO: store state before run
      "repositories" => {
        abort: "restore",
        next:  "proposals"
      },
      "proposals"    => {
        abort: "restore",
        next:  "perform_update"
      },
      "perform_update" => {},
      "restore"      => {
        abort: :abort
      }
    }

    def aliases
      {
        "restore"        => ->() { restore_state },
        "repositories"   => ->() { repositories },
        "proposals"      => ->() { proposals },
        "perform_update" => ->() { perform_update }
      }
    end

    def restore_state
      # TODO: restore after canceling operation
      raise "Restoring state is not implemented yet"
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
    end
  end
end
