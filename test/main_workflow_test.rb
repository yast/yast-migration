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
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE GmbH.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

require_relative "test_helper"

require "migration/main_workflow"

describe Migration::MainWorkflow do
  describe ".run" do
    it "pass workflow sequence to Yast sequencer" do
      expect(Yast::Sequencer).to receive(:Run).and_return(:next)

      ::Migration::MainWorkflow.run
    end
  end
end
