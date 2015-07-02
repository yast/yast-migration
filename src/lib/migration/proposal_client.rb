
# ------------------------------------------------------------------------------
# Copyright (c) 2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# ------------------------------------------------------------------------------
#

require "installation/proposal_client"

module Migration
  # The proposal client for online migration
  class ProposalClient < ::Installation::ProposalClient
    include Yast
    include Yast::I18n

    def initialize
      Yast.import "Pkg"
      Yast.import "HTML"
      Yast.import "Packages"
      Yast.import "SpaceCalculation"
      Yast.import "Popup"
      Yast.import "Update"

      textdomain "migration"
    end

    # propose migration - return migration summary
    # @return [Hash] proposal result
    def make_proposal(_attrs)
      # report dependency issues in the Packages proposal
      Pkg.PkgSolve(true)
      Update.solve_errors = Pkg.PkgSolveErrors

      # recalculate the disk space usage data
      SpaceCalculation.GetPartitionInfo

      products = Pkg.ResolvableProperties("", :product, "")

      ret = {
        "preformatted_proposal" => product_summary(products),
        "help"                  => help
      }

      ret.merge(Packages.product_update_warning(products))
    end

    # handle the user feedback
    # @param [Hash] proposal parameters
    # @return [Hash] proposal result
    def ask_user(_param)
      # TRANSLATORS: popup message
      Popup.Message(_("There is nothing to configure."))
      # optimization: return :abort to avoid complete propsal re-evaluation
      { "workflow_sequence" => :abort }
    end

    # the proposal description
    # @return [Hash] proposal result
    def description
      {
        # TRANSLATORS: a summary heading
        "rich_text_title" => _("Migration Summary"),
        # TRANSLATORS: a menu entry
        "menu_title"      => _("&Migration Summary"),
        "id"              => "migration_proposal"
      }
    end

    private

    # @param [Array<Hash>] products the current libzypp products
    # @return [String] product summary text (RichText)
    def product_summary(products)
      summary_text = Packages.product_update_summary(products).map do |item|
        "<li>#{item}</li>"
      end

      HTML.ListStart + summary_text.join + HTML.ListEnd
    end

    # proposal help text
    # @return [String] help text
    def help
      # TRANSLATORS: help text
      _(
        "<p>This is an overview of the product migration.</p>\n"
      )
    end
  end
end
