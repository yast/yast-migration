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

require "singleton"
require "yaml"

module Migration
  # this class handles restarting the YaST module during online migration
  class Restarter
    include Yast::Logger
    include Singleton

    Yast.import "Installation"
    Yast.import "Directory"

    REBOOT_FILE = Yast::Installation.reboot_file
    RESTART_FILE = Yast::Installation.restart_file
    # the generic restart file is removed by the yast script before starting
    # YaST again, we need an extra file to distinguish restart and full start
    # and to pass some data between the restarts
    MIGRATION_RESTART = Yast::Directory.vardir + "/migration_restart.yml"

    attr_reader :restarted, :data

    # read the restart flag and remove it immediately to avoid
    # possible restart loop
    def initialize
      @restarted = File.exist?(MIGRATION_RESTART)
      @data = YAML.load_file(MIGRATION_RESTART) if restarted

      log.info "Initialized restart status: #{inspect}"

      clear_restart
    end

    # set the restart flag
    # @param [Object] data optional data saved in the restart file, the data will
    # be available after the restart
    def restart_yast(data = nil)
      log.info "Creating the restart file"
      File.write(RESTART_FILE, "")
      log.info "Storing restart data: #{data.inspect}"
      File.write(MIGRATION_RESTART, data.to_yaml)
    end

    # create the reboot file, yast will reboot the machine after finishing the module
    def reboot
      log.info "Creating the reboot file"
      File.write(REBOOT_FILE, "")
    end

    # clear the reboot file
    def clear_reboot
      log.info "Clearing the reboot file"
      File.unlink(REBOOT_FILE) if File.exist?(REBOOT_FILE)
    end

    # clear the set restart flags
    def clear_restart
      log.info "Clearing the restart file"
      File.unlink(RESTART_FILE) if File.exist?(RESTART_FILE)
      File.unlink(MIGRATION_RESTART) if File.exist?(MIGRATION_RESTART)
    end
  end
end
