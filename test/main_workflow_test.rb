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

require_relative "test_helper"

require "migration/main_workflow"

describe Migration::MainWorkflow do
  describe ".run" do
    let(:cmd_success) { { "exit" => 0 } }
    let(:snapshot_created) { { "exit" => 0, "stdout" => "146\n" } }
    let(:cmd_fail) { { "exit" => 1 } }
    let(:bash_path) { Yast::Path.new(".target.bash_output") }

    def mock_client(name, res)
      allow(Yast::WFM).to receive(:CallFunction).with(*name).and_return(res)
    end

    before do
      mock_client("migration_repos", :next)
      mock_client(["migration_proposals", [{ "hide_export" => true }]], :next)
      mock_client("inst_prepareprogress", :next)
      mock_client("inst_kickoff", :next)
      mock_client("inst_rpmcopy", :next)

      allow(Yast::Update).to receive(:clean_backup)
      allow(Yast::Update).to receive(:create_backup)
      allow(Yast::Update).to receive(:restore_backup)

      allow(Yast::SCR).to receive(:Execute).with(bash_path, /snapper .*list-configs/)
        .and_return(cmd_success)
      allow(Yast::SCR).to receive(:Execute).with(bash_path, /snapper create/).and_return(cmd_fail)
      # simulate snapper failure (to have a better code coverage)
      allow(Yast::Report).to receive(:Error).with(/Failed to create a filesystem snapshot/)

      allow(File).to receive(:write).with(Migration::Restarter::MIGRATION_RESTART, "")
      allow(File).to receive(:write).with(Migration::Restarter::RESTART_FILE, "")

      allow_any_instance_of(Migration::FinishDialog).to receive(:run).and_return(:next)
      allow_any_instance_of(Migration::FinishDialog).to receive(:reboot).and_return(false)
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

    it "creates a pre and post snapshots around the online migration" do
      expect(Yast::SCR).to receive(:Execute).with(bash_path, /snapper create .*--type=pre/)
        .and_return(snapshot_created).ordered

      mock_client("inst_rpmcopy", :next).ordered

      expect(Yast::SCR).to receive(:Execute).with(bash_path,
        /snapper create .*--type=post .*--pre-number=146/).and_return(cmd_success).ordered

      expect(subject.run).to eq :next
    end

    it "reboots the system at the end when requested" do
      allow_any_instance_of(Migration::FinishDialog).to receive(:reboot).and_return(true)
      allow_any_instance_of(Migration::Restarter).to receive(:restarted).and_return(true)
      allow_any_instance_of(Migration::Restarter).to receive(:reboot)

      expect(::Migration::MainWorkflow.run).to eq :next
    end

  end
end
