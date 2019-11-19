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
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require_relative "test_helper"
require "migration/proposal_client"

describe Migration::ProposalClient do
  describe "#description" do
    it "returns map with \"rich_text_title\", \"menu_title\" and \"id\" keys" do
      result = subject.description

      expect(result.keys).to include("id", "menu_title", "rich_text_title")
    end
  end

  describe "#ask_user" do
    it "runs the repository manager and returns the user input" do
      expect(Yast::WFM).to receive(:call).with("repositories", ["refresh-enabled"])
        .and_return(:next)
      expect(subject.ask_user({})).to include("workflow_sequence" => :next)
    end

    it "disables the respective repository when clicking the 'Disable' link in the proposal" do
      repo_id = 3
      expect(Yast::Pkg).to receive(:SourceSetEnabled).with(repo_id, false)

      expect(subject.ask_user("chosen_id" => "#{Migration::ProposalClient::LINK_PREFIX}#{repo_id}"))
        .to include("workflow_sequence" => :next)
    end
  end

  describe "#make_proposal" do
    let(:msg) { "Product <b>Foo</b> will be installed" }
    let(:products) { load_yaml_data("sles12_migration_products.yml").map do |p|
      Y2Packager::Resolvable.new(p)
    end
    }

    before do
      expect(Yast::Pkg).to receive(:PkgSolve)
      expect(Yast::Pkg).to receive(:PkgSolveErrors).and_return(0)
      expect(Yast::Update).to receive(:solve_errors=)
      expect(Yast::SpaceCalculation).to receive(:GetPartitionInfo)
      expect(Yast::Packages).to receive(:product_update_summary)
        .and_return([msg])
      expect(Y2Packager::Resolvable).to receive(:find).with(kind: :product)
        .and_return(products)
      expect(Yast::Pkg).to receive(:SourceGeneralData).with(0)
        .and_return("name" => "Repo")
    end

    it "returns a map with proposal details" do
      expect(Yast::Packages).to receive(:product_update_warning).and_return({})
      proposal = subject.make_proposal({})

      expect(proposal).to include("help", "preformatted_proposal")
      expect(proposal["preformatted_proposal"]).to include(msg)
    end

    it "returns a warning when an obsoleted repository is present" do
      warning_string = "warning string"
      expect(Yast::Packages).to receive(:product_update_warning).and_return(
                                  "warning_level" => :warning,
                                  "warning" => warning_string)
      proposal = subject.make_proposal({})
      expect(proposal["warning"]).to include(warning_string)
      expect(proposal["warning_level"]).to eq(:warning)
    end
  end
end
