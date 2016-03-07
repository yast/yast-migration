
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
require "migration/repository_checker"

module Migration
  # The proposal client for online migration
  class ProposalClient < ::Installation::ProposalClient
    include Yast
    include Yast::I18n

    # ID prefix used in the proposal links
    LINK_PREFIX = "migration--disable_repository_"

    def initialize
      Yast.import "Pkg"
      Yast.import "HTML"
      Yast.import "Packages"
      Yast.import "SpaceCalculation"
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

      add_warnings(ret, products)

      ret
    end

    # handle the user feedback
    # @param [Hash] param proposal parameters
    # @return [Hash] proposal result
    def ask_user(param)
      chosen_id = param["chosen_id"]

      # handle the link clicked in the migratin proposal
      if chosen_id && chosen_id.start_with?(LINK_PREFIX)
        disable_repo(chosen_id)
        { "workflow_sequence" => :next }
      else
        # run the repository manager, refresh enabled repositories so they
        # are up-to-date
        ret = WFM.call("repositories", ["refresh-enabled"])
        { "workflow_sequence" => ret }
      end
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

    # check the current products for possible issues, add product warnings
    # to the proposal summary
    # @param [Hash] proposal the proposal summary (the value is modified)
    # @param [Array<Hash>] products list of the current products (from libzypp)
    def add_warnings(proposal, products)
      package_warnings = Packages.product_update_warning(products)
      repo_warnings = check_repositories(products)

      # merge the warnings
      warning = package_warnings["warning"].to_s + repo_warnings["warning"].to_s
      return if warning.empty?

      proposal["warning"] = warning

      warning_level = package_warnings["warning_level"] ||
        repo_warnings["warning_level"]
      proposal["warning_level"] = warning_level if warning_level

      links = repo_warnings["links"]
      proposal["links"] = links if links
    end

    # create a product summary for migration proposal
    # @param [Array<Hash>] products the current libzypp products
    # @return [String] product summary text (RichText)
    def product_summary(products)
      summary_text = Packages.product_update_summary(products).map do |item|
        "<li>#{item}</li>"
      end

      HTML.ListStart + summary_text.join + HTML.ListEnd
    end

    # check for obsolete repositories
    # @param [Array<Hash>] products the current libzypp products
    # @return [Hash] warning for the proposal summary, an empty Hash is returned
    #   if everything is OK
    def check_repositories(products)
      warnings = []
      links = []

      checker = RepositoryChecker.new(products)
      checker.obsolete_product_repos.each do |repo|
        msg, link = warning_for_repo(repo)
        warnings << msg
        links << link
      end

      proposal_warning(warnings, links)
    end

    # create a warning masse for an obsolete repository
    # @param [Fixnum] repo the repository ID
    # @return [Array] a pair [message, link_name]
    def warning_for_repo(repo)
      repo_data = Pkg.SourceGeneralData(repo)
      link = "#{LINK_PREFIX}#{repo}"

      # TRANSLATORS: A warning message displayed in the migration proposal
      # %{name} is a repository name, %{link} is a hidden internal identifier
      msg = _("Warning: Repository <b>%{name}</b> is obsolete and should be excluded " \
          "from migration.<br>It is highly recommended to disable this repository. "\
          "(<a href=\"%{link}\">Disable</a>)") % { name: repo_data["name"], link: link }

      [msg, link]
    end

    # create proposal warning
    # @return [Hash] hash for the proposal summary
    def proposal_warning(warnings, links)
      return {} if warnings.empty?

      {
        "warning"       => warnings.join,
        "warning_level" => :warning,
        "links"         => links
      }
    end

    # handle clicking the "Disable" link
    # @param [String] link clicked link ID
    def disable_repo(link)
      log.info "Activated link: #{link}"

      link.match(/^#{LINK_PREFIX}(\d+)/)
      repo = Regexp.last_match(1).to_i

      log.info "Disabling repository #{repo}"
      Pkg.SourceSetEnabled(repo, false)

      # disable the old repo permanently to not possibly mess the system later
      Pkg.SourceSaveAll
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
