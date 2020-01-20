#!/bin/sh

VERSION=2.0

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
#       - /Library/LaunchDaemons/com.captam3rica.dep-notify-start- enrollment.plist
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
#   v2.0
#
#       - Updated to script to unload the LaunchDaemon before removing.
#
###############################################################################


DEP_NOTIFY_TMP_DIR="/var/tmp"
DEP_NOTIFY_SCRIPTS_DIR="/tmp"
DEP_NOTIFY_DAEMON="/Library/LaunchDaemons/com.captam3rica.dep-notify-start-enrollment.plist"
DEP_NOTIFY_APP="/Applications/Utilities/DEPNotify.app"


logging () {
    # Logging function

    LOG_FILE="enrollment-$(date +"%Y-%m-%d").log"
    LOG_PATH="/Library/Logs/$LOG_FILE"
    DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
    /bin/echo "$DATE"$1 >> $LOG_PATH
}


remove_depnotify_daemon (){
    # Unload and remove the LaunchDaemon

    if [ -e "$DEP_NOTIFY_DAEMON" ]; then
        # The LaunchDaemon file exists

        IS_LOADED=$(/bin/launchctl list | \
            /usr/bin/grep "dep-notify-start-enrollment" | \
            /usr/bin/awk '{print $3}')

        if [ -n "$IS_LOADED" ]; then
            # Unload the daemon
            logging "DEPNotify Cleanup: Unloading DEPNotify LaunchDaemon"
            /bin/launchctl unload "$DEP_NOTIFY_DAEMON"
        fi

        logging "DEPNotify Cleanup: Removing DEPNotify LaunchDaemon"
        /bin/rm -R "$DEP_NOTIFY_DAEMON"
    fi
}


remove_depnotify_collateral (){
    # Remove DEPNotify dependencies

    for thing in \
        "$DEP_NOTIFY_TMP_DIR/depnotify.log" \
        "$DEP_NOTIFY_TMP_DIR/dep-notify-enrollment-installer.sh.err" \
        "$DEP_NOTIFY_TMP_DIR/dep-notify-enrollment-installer.sh.out" \
        "$DEP_NOTIFY_TMP_DIR/depnotifyDebug.log" \
        "$DEP_NOTIFY_TMP_DIR/com.depnotify.provisioning.done" \
        "$DEP_NOTIFY_SCRIPTS_DIR/dep-notify-enrollment-installer.sh" \
        "$DEP_NOTIFY_SCRIPTS_DIR/dep-notify-enrollment-uninstaller.sh" \
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
}


main (){
    # Main script that calls everyting else.

    logging "-- Start DEPNotify cleanup --"
    logging "Script version $VERSION"

    remove_depnotify_daemon
    remove_depnotify_collateral

    logging "-- End DEPNotify Cleanup --"
}

# Call main
main
