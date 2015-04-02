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

require "migration/proposal_store"

# to get the _() method
module Yast
  extend Yast::I18n
  textdomain "migration"

  describe Migration::ProposalStore do
    subject { Migration::ProposalStore.new(nil) }

    describe ".headline" do
      it "returns a headline" do
        expect(subject.headline).to eq(Yast._("Migration proposal"))
      end
    end

    describe ".proposal_names" do
      it "returns an update proposal" do
        expect(subject.proposal_names).to eq ["update_proposal"]
      end
    end

    describe ".presentation_order" do
      it "returns a presentation order" do
        expect(subject.presentation_order).to eq ["update_proposal"]
      end
    end

    describe ".help_text" do
      before do
        # mock getting descriptions as we do not want in build to depend on all
        # yast modules from which we use proposal clients
        allow(subject).to receive(:descriptions).and_return("update_proposal" => {
                                                              "id"              => "update",
                                                              "help"            => "my nice help",
                                                              "rich_text_title" => "my cool title"
                                                            })
      end

      it "returns the right help text" do
        help_string = Yast._(
          "<p>\n" \
          "To start online migration, press <b>Next</b>.\n" \
          "</p>\n"
        )
        expect(subject.help_text.start_with?(help_string)).to eq true
      end
    end

    describe ".icon" do
      it "returns 'yast-software'" do
        expect(subject.icon).to eq "yast-software"
      end
    end

    describe ".tabs?" do
      it "returns false" do
        expect(subject.tabs?).to eq false
      end
    end
  end
end
