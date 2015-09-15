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

require "migration/patches"

describe Migration::Patches do

  before do
    # mock some Pkg calls
    allow(Yast::Pkg).to receive(:GetSolverFlags)
    allow(Yast::Pkg).to receive(:SetSolverFlags)
    allow(Yast::Pkg).to receive(:PkgSolve)
    allow(Yast::Pkg).to receive(:PkgReset)
    allow(Yast::Pkg).to receive(:ResolvableCountPatches).and_return(0)
    allow(Yast::Pkg).to receive(:ResolvablePreselectPatches).and_return(0)
  end

  describe "#available?" do
    it "ignores recommended packages" do
      expect(Yast::Pkg).to receive(:SetSolverFlags).with("ignoreAlreadyRecommended" => true,
                                                         "onlyRequires"             => true)
      subject.available?
    end

    it "returns true if at least one patch is available" do
      expect(Yast::Pkg).to receive(:ResolvableCountPatches).and_return(42)
      expect(subject.available?).to eq(true)
    end

    it "returns false if no patch is available" do
      expect(Yast::Pkg).to receive(:ResolvableCountPatches).and_return(0)
      expect(subject.available?).to eq(false)
    end
  end

  describe "#install" do
    before do
      expect(Yast::Pkg).to receive(:ResolvablePreselectPatches).and_return(42)
    end

    it "displays the patches to confirm the patch installation" do
      expect(Yast::PackagesUI).to receive(:RunPackageSelector).and_return(:cancel)
      subject.install
    end

    it "starts the patch installation when confirmed and returns the result" do
      expect(Yast::PackagesUI).to receive(:RunPackageSelector).and_return(:accept)
      expect(Yast::WFM).to receive(:CallFunction).with("inst_rpmcopy").and_return(:next)
      expect(subject.install).to eq(:next)
    end

    it "skips patch installation and resets the changes when patch installation is canceled" do
      expect(Yast::PackagesUI).to receive(:RunPackageSelector).and_return(:cancel)
      expect(Yast::Pkg).to receive(:PkgReset)
      expect(Yast::WFM).to_not receive(:CallFunction).with("inst_rpmcopy")
      expect(subject.install).to eq(:cancel)
    end
  end
end
