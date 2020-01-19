#!/bin/sh

VERSION=1.1

###############################################################################
#
#   Removes the files and directories left behind by DEPNotify once the device
#   setup is complete. Then, removes the DEPNotify application its self.
#
#   This script can be added to the JamfCloud console as a script and called
#   within the jamf-dep-notify-enrollment script typically towards the bottom
#   of the main function once all application policies finish.
#
#   NOTE: The package used to install DEPNotify will not need to be
#         manually removed because the Packages.app will build a tmp
#         directory to install the pacakge from and will unmount it once
#         the insall is complete. :)
#
#   Logs:
#
#       - /var/tmp/depnotify.log
#       - /var/tmp/dep-notify-enrollment-installer.sh.err
#       - /var/tmp/dep-notify-enrollment-installer.sh.out
#       - /var/tmp/depnotifyDebug.log
#       - /var/tmp/com.depnotify.provisioning.done
#
#   Scripts
#
#       - /tmp/dep-notify-enrollment-installer.sh
#       - /tmp/dep-notify-enrollmnet-uninstaller.sh
#
#   LaunchDaemon
#
#       - /Library/LaunchDaemons/com.captam3rica.dep-notify-enrollment.plist
#
#   Applications:
#
#       - /Applications/Utilities/DEPNotify.app
#
###############################################################################
#
#   UPDATES
#
#   v1.1
#
#       - Added addtional logging for better clarity.
#
###############################################################################


DEP_NOTIFY_TMP_DIR="/var/tmp"
DEP_NOTIFY_SCRIPTS_DIR="/tmp"
DEP_NOTIFY_DAEMON="/Library/LaunchDaemons/com.captam3rica.dep-notify-enrollment.plist"
DEP_NOTIFY_APP="/Applications/Utilities/DEPNotify.app"


logging () {
    # Logging function

    LOG_FILE="enrollment-$(date +"%Y-%m-%d").log"
    LOG_PATH="/Library/Logs/$LOG_FILE"
    DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
    /bin/echo "$DATE"$1 >> $LOG_PATH
}

logging "Starting DEPNotify cleanup"
logging "Script version $VERSION"

for thing in \
    "$DEP_NOTIFY_TMP_DIR/depnotify.log" \
    "$DEP_NOTIFY_TMP_DIR/dep-notify-enrollment-installer.sh.err" \
    "$DEP_NOTIFY_TMP_DIR/dep-notify-enrollment-installer.sh.out" \
    "$DEP_NOTIFY_TMP_DIR/depnotifyDebug.log" \
    "$DEP_NOTIFY_TMP_DIR/com.depnotify.provisioning.done" \
    "$DEP_NOTIFY_SCRIPTS_DIR/dep-notify-enrollment-installer.sh" \
    "$DEP_NOTIFY_SCRIPTS_DIR/dep-notify-enrollment-uninstaller.sh" \
    "$DEP_NOTIFY_DAEMON" \
    "$DEP_NOTIFY_APP"; do
    # Loop through and remove all files accociated with DEPNotify.

    if [ -e "$thing" ] || [ -d "$thing" ]; then
        # If a DEPNotify log file or dir exists remove it.

        logging "Attempting to remove $thing ..."

        /bin/rm -R "$thing"

        RETURN="$?"

        if [ "$RETURN" -ne 0 ]; then
            # Log that an error occured while removing a file.
            logging "ERROR: Unable to remove $thing"
            return "$RETURN"
        fi

    else
        # File or directory not found.
        logging "$thing not found ..."

    fi

done
