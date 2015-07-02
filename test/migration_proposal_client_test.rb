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
