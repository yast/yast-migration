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
  # Display the "finished" dialog, allow rebooting the machine
  class FinishDialog
    include Yast::Logger
    include Yast::I18n
    include Yast::UIShortcuts

    Yast.import "UI"
    Yast.import "Wizard"
    Yast.import "Popup"
    Yast.import "Label"

    attr_reader :reboot

    # constructor
    def initialize
      textdomain "migration"

      @reboot = false
    end

    # display and run the dialog
    # @return [Symbol] user input
    def run
      Yast::Wizard.SetContents(
        # TRANSLATORS: dialog title
        _("Migration Finished"),
        dialog_content,
        help,
        # going back is not possible
        false,
        true
      )

      Yast::Wizard.SetNextButton(:next, Yast::Label.FinishButton)

      loop do
        ret = Yast::UI.UserInput

        if ret == :next
          # use a generic popup - use "reboot" button, make the "cancel" default
          @reboot = Yast::Popup.AnyQuestion(
            Yast::Popup::NoHeadline(),
            # TRANSLATORS: popup messsage
            _("The system will be restarted now to activate the changes."),
            # TRANSLATORS: a push button label, pressing the button will restart
            # the system immediately
            _("&Restart Now"),
            Yast::Label.CancelButton,
            :focus_yes
          )
        end

        return ret if [:next, :back, :cancel, :abort].include?(ret)
      end
    end

    private

    def help
      # TRANSLATORS: a short help text (the details are directly in the dialog)
      _("<p><b>Finish</b> will close the migration and you should restart " \
          "the system as soon as possible.</b>")
    end

    # the main dialog content
    # @return [Yast::Term] UI term
    def dialog_content
      VBox(
        VSpacing(1),
        RichText(Id(:details), Opt(:vstretch), message),
        VSpacing(1)
      )
    end

    def message
      # TRANSLATORS: The final congratulation displayed at the end of migration,
      # in RichText format, %s = URL link to the SUSE home page
      _("<h2>Congratulations!</h2><br>
<p>You have just successfully finished the on-line migration.<br>
The system has been upgraded, it should be restarted
as soon as possible to activate the changes.</p>
<p>Please visit us at %s.</p>
<br>
<p>Have a lot of fun!</p>
<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
Your SUSE Development Team</p>") % "http://www.suse.com"
    end
  end
end
