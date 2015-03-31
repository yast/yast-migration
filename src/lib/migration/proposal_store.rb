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
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact Novell, Inc.
#
# To contact Novell about this file by physical or electronic mail, you may find
# current contact information at www.novell.com.
# ------------------------------------------------------------------------------

require "yast"

module Migration
  # 1. Provides access to metadata of proposal parts (clients), as defined in the control file elements
  # /productDefines/proposals/proposal: https://github.com/yast/yast-installation-control/blob/master/control/control.rnc
  # 2. Handles all calls to the parts (clients).
  class ProposalStore < Installation::ProposalStore
    include Yast::Logger
    include Yast::I18n

    # @ param[String] proposal_mode one of initial, service, network, hardware,
    #   uml, ... or anything else
    def initialize(proposal_mode)
      textdomain "installation"

      @proposal_mode = proposal_mode

      @proposal_headline = _("Migration proposal")
      @proposal_text_domain = "textdomain"
      @proposal_names = [ "one", "two", "three" ]
      @proposal_properties = { "key" => "value" }
      @modules_order = []
    end
    
    # @return [String] translated headline
    def headline
      @proposal_headline
    end

    # @return [Array<String>] proposal names in execution order, including
    #    the "_proposal" suffix
    def proposal_names
      @proposal_names
    end

    # returns single list of modules presentation order or list of tabs with list of modules
    def presentation_order
      return @modules_order if @modules_order

      tabs? ? order_with_tabs : order_without_tabs
    end

    # Makes proposal for all proposal clients.
    # @param callback Called after each client/part, to report progress. Gets
    #   part name and part result as arguments
    def make_proposals(force_reset: false, language_changed: false, callback: Proc.new)
      @link2submod = {}

      proposal_names.each do |submod|
        proposal_map = make_proposal(submod, force_reset:      force_reset,
                                             language_changed: language_changed)

        callback.call(submod, proposal_map)

        # update link map
        (proposal_map["links"] || []).each do |link|
          @link2submod[link] = submod
        end

        if proposal_map["language_changed"]
          @descriptions = nil # invalid descriptions cache
          return make_proposals(force_reset: force_reset, language_changed: true)
        end

        break if proposal_map["warning_level"] == :fatal
      end
    end

    # Calls all clients/parts to retrieve the description
    # @return [Hash{String => Hash}] map client/part names to hashes with keys
    # "id", "menu_title" "rich_text_title" http://www.rubydoc.info/github/yast/yast-yast2/Installation/ProposalClient:description
    def descriptions
      return @descriptions if @descriptions

      missing_no = 1
      @id_mapping = {}
      @descriptions = proposal_names.each_with_object({}) do |client, res|
        description = Yast::WFM.CallFunction(client, ["Description", {}])
        if !description["id"]
          log.warn "proposal client #{client} missing key 'id' in #{description}"

          description["id"] = "module_#{missing_no}"
          missing_no += 1
        end

        @id_mapping[description["id"]] = client

        res[client] = description
      end
    end

    # @return [String] an id provided by the description API
    def id_for(client)
      descriptions[client]["id"]
    end

    def title_for(client)
      descriptions[client]["rich_text_title"] ||
        descriptions[client]["rich_text_raw_title"] ||
        client
    end

    # Calls `ask_user`, to change a setting interactively (if link is the
    # heading for the part) or noninteractively (if it is a "shortcut")
    def handle_link(link)
      client = @id_mapping[link]
      client ||= @link2submod[link]

      if !client
        log.error "unknown link #{link}. Broken proposal client?"
        return nil
      end

      data = {
        "has_next"  => false,
        "chosen_id" => link
      }

      Yast::WFM.CallFunction(client, ["AskUser", data])
    end

  private

    def global_help
      case @proposal_mode
      when "initial"
        if Yast::Mode.installation
          # Help text for installation proposal
          # General part ("You can change values...") is added as the next paragraph.
          _(
            "<p>\n" \
              "Select <b>Install</b> to perform a new installation with the values displayed.\n" \
              "</p>\n"
            )
        else # so update
          # Help text for update proposal
          # General part ("You can change values...") is added as the next paragraph.
          _(
            "<p>\n" \
              "Select <b>Update</b> to perform an update with the values displayed.\n" \
              "</p>\n"
          )
        end
      when "network"
        # Help text for network configuration proposal
        # General part ("You can change values...") is added as the next paragraph.
        _(
          "<p>\n" \
            "Put the network settings into effect by pressing <b>Next</b>.\n" \
            "</p>\n"
        )
      when "service"
        # Help text for service configuration proposal
        # General part ("You can change values...") is added as the next paragraph.
        _(
          "<p>\n" \
            "Put the service settings into effect by pressing <b>Next</b>.\n" \
            "</p>\n"
        )
      when "hardware"
        # Help text for hardware configuration proposal
        # General part ("You can change values...") is added as the next paragraph.
        _(
          "<p>\n" \
            "Put the hardware settings into effect by pressing <b>Next</b>.\n" \
            "</p>\n"
        )
      when "uml"
        # Proposal in uml module
        _("<P><B>UML Installation Proposal</B></P>") \
        # help text
        _(
          "<P>UML (User Mode Linux) installation allows you to start independent\nLinux virtual machines in the host system.</P>"
        )
      else
        if properties["help"] && !properties["help"].empty?
          # Proposal help from control file module
          Yast::Builtins.dgettext(
            @proposal_text_domain
            properties["help"]
          )
        else
          # Generic help text for other proposals (not basic installation or
          # hardhware configuration.
          # General part ("You can change values...") is added as the next paragraph.
          _(
            "<p>\n" \
              "To use the settings as displayed, press <b>Next</b>.\n" \
              "</p>\n"
          )
        end
      end
    end

  
    def properties
      @proposal_properties
    end

    def order_without_tabs
      @modules_order.sort_by! { |m| m[1] || 50 } # second element is presentation order

      @modules_order.map!(&:first)

      @modules_order
    end

  end
end
