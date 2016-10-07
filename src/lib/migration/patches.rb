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

require "yast"

module Migration
  # This class handles patch evaluation and installation.
  # Prerequisite: The package management has been already initialized
  #   before using this class.
  class Patches
    include Yast::Logger

    Yast.import "Pkg"
    Yast.import "PackagesUI"

    # all patch types, see Pkg.Resolvable{Count,Preselect}Patches documentation
    KIND_ALL = :all
    KIND_SW_MGMT = :affects_pkg_manager
    KIND_INTERACTIVE = :interactive
    KIND_REBOOT = :reboot_needed
    KIND_RELOGIN = :relogin_needed

    attr_reader :patch_type

    # constructor
    # @param [Symbol] patch_type requested patch type to use, one of the KIND_* constant
    def initialize(patch_type = KIND_SW_MGMT)
      accepted_types = [KIND_ALL, KIND_SW_MGMT, KIND_INTERACTIVE, KIND_REBOOT, KIND_RELOGIN]

      if !accepted_types.include?(patch_type)
        raise ArgumentError, "Unknown patch type: #{patch_type}"
      end

      @patch_type = patch_type
    end

    # Is any patch of the *patch_type* available to install?
    # @return [Boolean] true if any patch of the requested type is available
    def available?
      only_requires do
        count = Yast::Pkg.ResolvableCountPatches(patch_type)
        log.info "Found #{patch_type} available patches: #{count}"

        count > 0
      end
    end

    # install the available patches
    # @return [Symbol] UI symbol
    def install
      only_requires do
        preselect
        # run the patch selector GUI to review/confirm the patch installation
        ui = Yast::PackagesUI.RunPackageSelector("mode" => :youMode)
        log.info "Package selector result: #{ui}"

        if ui == :cancel
          # reset all changes
          Yast::Pkg.PkgReset
          return ui
        end

        # run the patch installation
        # this client is located in the yast2-packager package
        Yast::WFM.CallFunction("inst_rpmcopy")
      end
    end

  private

    # preselect the available patches
    def preselect
      count = Yast::Pkg.ResolvablePreselectPatches(patch_type)
      log.info "Preselected #{patch_type.inspect} patches: #{count}"
    end

    # set the "only requires" solver flags and run the passed block,
    # the original solver flags are restored at the end
    def only_requires(&_block)
      flags_backup = Yast::Pkg.GetSolverFlags

      # ignore recommends
      Yast::Pkg.SetSolverFlags("ignoreAlreadyRecommended" => true, "onlyRequires" => true)

      # evaluate the patch statuses
      Yast::Pkg.PkgSolve(true)

      yield
    ensure
      # restore the original solver flags back
      log.info "Restoring original solver config: #{flags_backup}"
      Yast::Pkg.SetSolverFlags(flags_backup)
    end
  end
end
