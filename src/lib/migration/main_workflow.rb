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

Yast.import "Sequencer"

module Migration
  # The goal of the class is to provide main single entry point to start
  # migration work-flow. It is UI oriented sequence.
  #
  class MainWorkflow
    include Yast::Logger

    # array of migration steps, each step contain client and its args
    MIGRATION_STEPS = [
      {
        client: "repositories",
        args:   [:sw_single_mode]
      }
    ]
    def self.run
      workflow = new
      workflow.run
    end

    def run
      Yast::Sequencer.Run(aliases, WORKFLOW_SEQUENCE)
    end

    private

    WORKFLOW_SEQUENCE = {
      "ws_start"     => "repositories", # TODO: store state before run
      "repositories" => {
        abort: "restore",
        next:  :next
      },
      "restore"      => {
        abort: :abort
      }
    }

    def aliases
      {
        "restore"      => ->() { restore_state },
        "repositories" => ->() { repositories }
      }
    end

    def restore_state
      # TODO: restore after canceling operation
      raise "Restoring state is not implemented yet"
    end

    def repositories
      Yast::WFM.CallFunction("repositories", [:sw_single_mode])
    end
  end
end
