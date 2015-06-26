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

# fake Update class to avoid loading all Update dependencies
module Yast
  # Faked Update module
  class UpdateClass
    def did_init1=(_init)
    end

    def onlyUpdateInstalled=(_mode)
    end
  end
  Update = UpdateClass.new
end

require_relative "test_helper"

require "migration/main_workflow"

describe Migration::MainWorkflow do
  describe ".run" do
    def mock_client(name, res)
      allow(Yast::WFM).to receive(:CallFunction).with(*name).and_return(res)
    end

    before do
      mock_client("migration_repos", :next)
      mock_client(["migration_proposals", [{ "hide_export" => true }]], :next)
      mock_client("inst_prepareprogress", :next)
      mock_client("inst_kickoff", :next)
      mock_client("inst_rpmcopy", :next)

      cmd_success = { "exit" => 0 }
      cmd_fail = { "exit" => 1 }
      allow(Yast::Update).to receive(:clean_backup)
      allow(Yast::Update).to receive(:create_backup)
      allow(Yast::Update).to receive(:restore_backup)
      allow(Yast::SCR).to receive(:Execute).and_return(cmd_success, cmd_fail)
    end

    it "pass workflow sequence to Yast sequencer" do
      expect(Yast::Sequencer).to receive(:Run).and_return(:next)

      ::Migration::MainWorkflow.run
    end

    it "returns :next if clicking next" do
      expect(::Migration::MainWorkflow.run).to eq :next
    end

    it "restores repositories when clicking on Cancel" do
      expect(Yast::Update).to receive(:clean_backup)
      expect(Yast::Update).to receive(:create_backup)
      expect(Yast::Update).to receive(:restore_backup)

      mock_client(["migration_proposals", [{ "hide_export" => true }]], :abort)

      expect(::Migration::MainWorkflow.run).to eq :abort
    end
  end
end
