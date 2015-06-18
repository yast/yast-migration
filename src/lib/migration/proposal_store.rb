# encoding: utf-8

# ------------------------------------------------------------------------------
# Copyright (c) 2014 Novell, Inc. All Rights Reserved.
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

require "yast"
require "installation/proposal_store"

module Migration
  # Provides access to static metadata for update proposal.
  class ProposalStore < Installation::ProposalStore
    include Yast::Logger
    include Yast::I18n

    PROPOSAL_NAMES = ["update_proposal", "packages_proposal"]
    PROPOSAL_PROPERTIES = {
      "enable_skip" => "false"
    }
    MODULES_ORDER = PROPOSAL_NAMES

    def initialize(_unused_mode)
      textdomain "migration"

      super("migration")
    end

    # @return [String] translated headline
    def headline
      _("Migration proposal")
    end

    # @return [Array<String>] proposal names in execution order, including
    #    the "_proposal" suffix
    def proposal_names
      PROPOSAL_NAMES
    end

    # returns single list of modules presentation order or list of tabs with
    #    list of modules
    def presentation_order
      MODULES_ORDER
    end

    private

    def global_help
      _(
        "<p>\n" \
        "To start online migration, press <b>Next</b>.\n" \
        "</p>\n"
      )
    end

    def properties
      PROPOSAL_PROPERTIES
    end
  end
end
