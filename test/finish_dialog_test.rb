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

describe Migration::FinishDialog do
  describe ".run" do
    it "displays the finish message" do
      # check the displayed content
      expect(Yast::Wizard).to receive(:SetContents) do |_title, content, _help, _back, _next|
        term = content.nested_find do |t|
          t.respond_to?(:value) && t.value == :RichText &&
            t.params[2].match(/Congratulations!/)
        end

        expect(term).to_not eq(nil)
      end

      # user pressed the "Abort" button
      allow(Yast::UI).to receive(:UserInput).and_return(:abort)
      subject.class.run
    end

    it "when aborted reboot flag is not set and return :abort" do
      # check the displayed content
      allow(Yast::Wizard).to receive(:SetContents)

      # user pressed the "Abort" button
      expect(Yast::UI).to receive(:UserInput).and_return(:abort)

      expect(subject.class.run).to eq(:abort)
      expect(subject.reboot).to eq(false)
    end

    it "displays a confirmation when reboot is requested" do
      allow(Yast::Wizard).to receive(:SetContents)

      # user pressed the "Next" button
      expect(Yast::UI).to receive(:UserInput).and_return(:next)
      allow(Yast::UI).to receive(:QueryWidget).with(:reboot, :Value).and_return(true)

      expect(Yast::Popup).to receive(:ContinueCancel).and_return(true)

      expect(subject.run).to eq(:next)
      expect(subject.reboot).to eq(true)
    end

    it "goes back when reboot is rejected" do
      allow(Yast::Wizard).to receive(:SetContents)

      # user pressed the "Next" button
      allow(Yast::UI).to receive(:UserInput).and_return(:next)
      # reboot is disabled at the second attempt
      allow(Yast::UI).to receive(:QueryWidget).with(:reboot, :Value).and_return(true, false)

      expect(Yast::Popup).to receive(:ContinueCancel).and_return(false)

      expect(subject.run).to eq(:next)
      expect(subject.reboot).to eq(false)
    end

  end
end
