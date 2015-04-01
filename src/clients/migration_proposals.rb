require "migration/proposal_store"
require "installation/proposal_runner"
require "yast"

Yast.import "Wizard"

# Proposal runner expect already opened wizard dialog
Yast::Wizard.OpenNextBackDialog
::Installation::ProposalRunner.new(Migration::ProposalStore).run
