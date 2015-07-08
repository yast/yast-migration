# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2015 SUSE LINUX Products GmbH, Nuernberg, Germany.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

require_relative "test_helper"

describe Migration::ProposalClient do
  describe "#description" do
    it "returns map with \"rich_text_title\", \"menu_title\" and \"id\" keys" do
      result = subject.description

      expect(result.keys).to include("id", "menu_title", "rich_text_title")
    end
  end

  describe "#ask_user" do
    it "runs the repository manager returns the user input" do
      expect(Yast::WFM).to receive(:call).with("repositories", ["refresh-enabled"])
        .and_return(:next)
      expect(subject.ask_user({})).to include("workflow_sequence" => :next)
    end

    it "handles clicking a link from the proposal" do
      repo_id = 3
      expect(Yast::Pkg).to receive(:SourceSetEnabled).with(repo_id, false)

      expect(subject.ask_user("chosen_id" => "#{Migration::ProposalClient::LINK_PREFIX}#{repo_id}"))
        .to include("workflow_sequence" => :next)
    end
  end

  describe "#make_proposal" do
    let(:msg) { "Product <b>Foo</b> will be installed" }

    before do
      expect(Yast::Pkg).to receive(:PkgSolve)
      expect(Yast::Pkg).to receive(:PkgSolveErrors).and_return(0)
      expect(Yast::Update).to receive(:solve_errors=)
      expect(Yast::SpaceCalculation).to receive(:GetPartitionInfo)
      expect(Yast::Packages).to receive(:product_update_summary)
        .and_return([msg])
      expect(Yast::Pkg).to receive(:ResolvableProperties).with("", :product, "")
        .and_return(load_yaml_data("sles12_migration_products.yml"))
      expect(Yast::Pkg).to receive(:SourceGeneralData).with(0)
        .and_return("name" => "Repo")
    end

    it "returns a map with proposal details" do
      proposal = subject.make_proposal({})

      expect(proposal).to include("help", "preformatted_proposal")
      expect(proposal["preformatted_proposal"]).to include(msg)
    end

    it "returns a warning when an obsoleted repository is present" do
      proposal = subject.make_proposal({})
      expect(proposal["warning"]).to include("Repository <b>Repo</b> is obsolete " \
          "and should be excluded from migration")
      expect(proposal["warning_level"]).to eq(:warning)
    end
  end
end
