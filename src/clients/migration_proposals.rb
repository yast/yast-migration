require "migration/proposal_store"
require "installation/proposal_runner"
require "yast"

Yast.import "Wizard"

# Proposal runner expect already opened wizard dialog
Yast::Wizard.OpenNextBackDialog
begin
  ret = ::Installation::ProposalRunner.new(Migration::ProposalStore).run
ensure
  Yast::Wizard.CloseDialog
end

ret
