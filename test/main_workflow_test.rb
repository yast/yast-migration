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
    # we need at least one non-default methods, otherwise ruby-bindings thinks
    # it is just namespace
    def fake_method
    end
  end
  Update = UpdateClass.new
end

require_relative "test_helper"

require "migration/main_workflow"

describe Migration::MainWorkflow do
  describe ".run" do
    def mock_client(name, res)
      allow(Yast::WFM).to receive(:CallFunction).with(name).and_return(res)
    end

    before do
      mock_client("repositories", :next)
      mock_client("migration_proposals", :next)
      mock_client("inst_prepareprogress", :next)
      mock_client("inst_kickoff", :next)
      mock_client("inst_rpmcopy", :next)

      allow(Yast::Update).to receive(:clean_backup)
      allow(Yast::Update).to receive(:create_backup)
      allow(Yast::Update).to receive(:restore_backup)
      allow(Yast::SCR).to receive(:Execute).and_return({ "exit" => 0 }, { "exit" => 1 })
    end

    it "pass workflow sequence to Yast sequencer" do
      expect(Yast::Sequencer).to receive(:Run).and_return(:next)

      ::Migration::MainWorkflow.run
    end

    it "returns :next if clicking next" do
      expect(::Migration::MainWorkflow.run).to eq :next
    end

    it "reload sources if click next on repositories" do
      expect(Yast::Pkg).to receive(:SourceLoad)
      ::Migration::MainWorkflow.run
    end

    it "restores repositories when clicking on Cancel" do
      expect(Yast::Update).to receive(:clean_backup)
      expect(Yast::Update).to receive(:create_backup)
      expect(Yast::Update).to receive(:restore_backup)

      mock_client("migration_proposals", :abort)

      expect(::Migration::MainWorkflow.run).to eq :abort
    end
  end
end
