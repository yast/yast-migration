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
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE GmbH.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
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
    it "prints a message and returns :abort user input" do
      expect(Yast::Popup).to receive(:Message)
      expect(subject.ask_user({})).to include("workflow_sequence" => :abort)
    end
  end

  describe "#make_proposal" do
    let(:msg) { "Product <b>Foo</b> will be installed" }
    it "returns a map with proposal details" do
      expect(Yast::Pkg).to receive(:PkgSolve)
      expect(Yast::Pkg).to receive(:PkgSolveErrors).and_return(0)
      expect(Yast::Update).to receive(:solve_errors=)
      expect(Yast::SpaceCalculation).to receive(:GetPartitionInfo)
      expect(Yast::Packages).to receive(:product_update_summary)
        .and_return([msg])
      expect(Yast::Pkg).to receive(:ResolvableProperties).with("", :product, "")
        .and_return([])

      proposal = subject.make_proposal({})

      expect(proposal).to include("help", "preformatted_proposal")
      expect(proposal["preformatted_proposal"]).to include(msg)
    end
  end
end
