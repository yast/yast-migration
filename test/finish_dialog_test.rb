# ------------------------------------------------------------------------------
# Copyright (c) 2015 SUSE LLC, All Rights Reserved.
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require_relative "test_helper"

require "migration/finish_dialog"

describe Migration::FinishDialog do
  describe ".run" do
    before do
      allow(Yast::Wizard).to receive(:SetContents)
    end

    it "displays the finish message" do
      # check the displayed content
      expect(Yast::Wizard).to receive(:SetContents) do |_title, content, _help, _back, _next|
        richtext = content.nested_find do |t|
          t.respond_to?(:value) && t.value == :RichText &&
            t.params[2].match(/Congratulations!/)
        end

        expect(richtext).to_not eq(nil)
      end

      # user pressed the "Abort" button
      allow(Yast::UI).to receive(:UserInput).and_return(:abort)
      subject.run
    end

    it "when aborted reboot flag is not set and return :abort" do
      # user pressed the "Abort" button
      expect(Yast::UI).to receive(:UserInput).and_return(:abort)

      expect(subject.run).to eq(:abort)
      expect(subject.reboot).to eq(false)
    end

    it "asks for reboot after pressing [Finish]" do
      # user pressed the "Next" button
      expect(Yast::UI).to receive(:UserInput).and_return(:next)
      expect(Yast::Popup).to receive(:AnyQuestion).and_return(true)

      expect(subject.run).to eq(:next)
    end

    it "sets the reboot flag when reboot is confirmed" do
      # user pressed the "Next" button
      expect(Yast::UI).to receive(:UserInput).and_return(:next)
      expect(Yast::Popup).to receive(:AnyQuestion).and_return(true)

      expect(subject.run).to eq(:next)
      expect(subject.reboot).to eq(true)
    end

    it "does not set the reboot flag when reboot is not confirmed" do
      # user pressed the "Next" button
      expect(Yast::UI).to receive(:UserInput).and_return(:next)
      expect(Yast::Popup).to receive(:AnyQuestion).and_return(false)

      expect(subject.run).to eq(:next)
      expect(subject.reboot).to eq(false)
    end

  end
end
