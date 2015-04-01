require "migration/proposal_store"
require "installation/proposal_runner"
require "yast"

Yast.import "Wizard"

Yast::Wizard.OpenNextBackDialog
::Installation::ProposalRunner.new(Migration::ProposalStore).run
