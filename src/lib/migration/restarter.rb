
require "yast"

require "singleton"

module Migration
  # this class handles restarting the YaST module during online migration
  class Restarter
    include Singleton

    Yast.import "Installation"
    Yast.import "Directory"

    REBOOT_FILE = Yast::Installation.reboot_file
    RESTART_FILE = Yast::Installation.restart_file
    # the generic restart file is removed by the yast script before starting
    # YaST again, we need an extra file to distinguish restart and full start
    MIGRATION_RESTART = Yast::Directory.vardir + "/migration_restarted"

    attr_reader :restarted

    # read the restart flag and remove it immediately to avoid
    # possible restart loop
    def initialize
      @restarted = File.exist?(MIGRATION_RESTART)

      clear_restart
    end

    # set the restart flag
    def restart_yast
      File.write(RESTART_FILE, "")
      File.write(MIGRATION_RESTART, "")
    end

    def reboot
      File.write(REBOOT_FILE, "")
    end

    def clear_reboot
      File.unlink(REBOOT_FILE) if File.exist?(REBOOT_FILE)
    end

    # clear the set restart flags
    def clear_restart
      File.unlink(RESTART_FILE) if File.exist?(RESTART_FILE)
      File.unlink(MIGRATION_RESTART) if File.exist?(MIGRATION_RESTART)
    end
  end
end
