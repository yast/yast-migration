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

require "migration/restarter"

describe Migration::Restarter do
  # create a new anonymous instance for each test to avoid test dependencies
  # see http://stackoverflow.com/a/26172556/633234
  subject { Class.new(Migration::Restarter).instance }

  before do
    allow(File).to receive(:exist?).with(Migration::Restarter::MIGRATION_RESTART)
      .and_return(false)
    allow(File).to receive(:exist?).with(Migration::Restarter::RESTART_FILE)
      .and_return(false)
  end

  describe "#restarted" do
    context "restart flag set" do
      before do
        expect(File).to receive(:exist?).with(Migration::Restarter::MIGRATION_RESTART)
          .twice.and_return(true)
      end

      it "removes the restart flag and returns true" do
        expect(File).to receive(:unlink).with(Migration::Restarter::MIGRATION_RESTART)
        expect(subject.restarted).to eq(true)
      end
    end

    context "restart flag not set" do
      it "returns false" do
        expect(File).to_not receive(:unlink).with(Migration::Restarter::MIGRATION_RESTART)
        expect(subject.restarted).to eq(false)
      end
    end
  end

  describe "#restart_yast" do
    it "set the restart flags" do
      expect(File).to receive(:write).with(Migration::Restarter::RESTART_FILE, "")
      expect(File).to receive(:write).with(Migration::Restarter::MIGRATION_RESTART, "")

      subject.restart_yast
    end
  end

  describe "#reboot" do
    it "set the reboot flag" do
      expect(File).to receive(:write).with(Migration::Restarter::REBOOT_FILE, "")
      subject.reboot
    end
  end

  describe "#clear_reboot" do
    it "clears the reboot flag if set" do
      expect(File).to receive(:exist?).with(Migration::Restarter::REBOOT_FILE)
        .and_return(true)
      expect(File).to receive(:unlink).with(Migration::Restarter::REBOOT_FILE)
      subject.clear_reboot
    end
  end

end
