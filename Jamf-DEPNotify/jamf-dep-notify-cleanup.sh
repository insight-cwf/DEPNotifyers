#!/bin/sh

VERSION=2.1.1

###############################################################################
#
#   A script to remove the files and directories left behind by DEPNotify once
#   the device setup is complete. Then, removes the DEPNotify application its
#   self.
#
#   This script can be added to the JamfCloud console as a script policy and
#   called within the jamf-dep-notify-enrollment script typically towards the
#   bottom of the main function once all application policies finish.
#
#   NOTE: The package used to install DEPNotify will not need to be
#         manually removed because the Packages.app will build a tmp
#         directory to install the pacakge from and will unmount it once
#         the insall is complete. :)
#
#   Plist:
#
#       - /Users/username/Library/Preferences/menu.nomad.DEPNotify.plist
#
#   Logs:
#
#       - /var/tmp/depnotify.log
#       - /var/tmp/dep-notify-start-enrollment-installer.sh.err
#       - /var/tmp/dep-notify-start-enrollment-installer.sh.out
#       - /var/tmp/depnotifyDebug.log
#       - /var/tmp/com.depnotify.provisioning.done
#       - /var/tmp/com.depnotify.provisioning.restart
#       = /var/tmp/com.depnotify.registration.done
#       - /var/tmp/com.depnotify.agreement.done
#
#   Scripts
#
#       - /tmp/dep-notify-start-enrollment-installer.sh
#
#   LaunchDaemon
#
#       - /Library/LaunchDaemons/com.captam3rica.dep-notify-start- enrollment.plist
#
#   Applications:
#
#       - /Applications/Utilities/DEPNotify.app
#
#   Misc:
#
#       - /Users/Shared/eula.txt
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
#   v2.1
#
#       - Updated logging.
#       - Added a few more default DEPNotify files that are installed by the
#         DEPNotify app.
#
#   v2.1.1
#
#       - Added a function that waits for the user to click the "Get Started"
#         button.
#
#####################################################################captam3rica


# Default DEPNotify file locations
DEPNOTIFY_APP="/Applications/Utilities/DEPNotify.app"
DEPNOTIFY_NEW_PLIST="/Users/username/Library/Preferences/menu.nomad.DEPNotify.plist"
DEPNOTIFY_TMP="/var/tmp"
DEPNOTIFY_LOG="$DEPNOTIFY_TMP/depnotify.log"
DEPNOTIFY_DEBUG="$DEPNOTIFY_TMP/depnotifyDebug.log"
DEPNOTIFY_DONE="$DEPNOTIFY_TMP/com.depnotify.provisioning.done"
DEPNOTIFY_RESTART="$DEPNOTIFY_TMP/com.depnotify.provisioning.restart"
DEPNOTIFY_AGR_DONE="$DEPNOTIFY_TMP/com.depnotify.agreement.done"
DEPNOTIFY_REG_DONE="$DEPNOTIFY_TMP/com.depnotify.registration.done"
DEPNOTIFY_EULA_TXT_FILE="/Users/Shared/eula.txt"

# Re-pacakged DEPNotify post-install script file locations
DEPNOTIFY_SCRIPTS_DIR="/tmp"
DEPNOTIFY_DAEMON="/Library/LaunchDaemons/com.captam3rica.dep-notify-start-enrollment.plist"
DEPNOTIFY_ENROLLMENT_STARTER="$DEPNOTIFY_SCRIPTS_DIR/dep-notify-start-enrollment-installer.sh"
DEPNOTIFY_INST_ERR="$DEPNOTIFY_TMP/dep-notify-start-enrollment-installer.sh.err"
DEPNOTIFY_INST_OUT="$DEPNOTIFY_TMP/dep-notify-start-enrollment-installer.sh.out"


logging () {
    # Logging function

    LOG_FILE="enrollment-$(date +"%Y-%m-%d").log"
    LOG_PATH="/Library/Logs/$LOG_FILE"
    DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
    /bin/echo "$DATE"$1 >> $LOG_PATH
}


wait_for_depnotify_done (){
    # Wait for the user to press the Get Started button.
    until [ -f "$DEPNOTIFY_DONE" ]; do
        logging "DEPNotify Cleanup: Waiting for $DEPNOTIFY_DONE"
        logging "DEPNotify Cleanup: The user has not clicked Get Started ..."
        logging "DEPNotify Cleanup: Waiting 1 second ..."
        /bin/sleep 1
    done
}

remove_depnotify_daemon (){
    # Unload and remove the LaunchDaemon

    if [ -e "$DEPNOTIFY_DAEMON" ]; then
        # The LaunchDaemon file exists

        IS_LOADED=$(/bin/launchctl list | \
            /usr/bin/grep "dep-notify-start-enrollment" | \
            /usr/bin/awk '{print $3}')

        if [ -n "$IS_LOADED" ]; then
            # Unload the daemon
            logging "DEPNotify Cleanup: Unloading DEPNotify LaunchDaemon"
            /bin/launchctl unload "$DEPNOTIFY_DAEMON"
        fi

        logging "DEPNotify Cleanup: Removing DEPNotify LaunchDaemon"
        /bin/rm -R "$DEPNOTIFY_DAEMON"

    else
        logging "DEPNotify Cleanup: Daemon not installed."

    fi
}


remove_depnotify_collateral (){
    # Remove DEPNotify files

    # Loop through and remove all files accociated with DEPNotify.
    for thing in \
        ${DEPNOTIFY_APP} \
        ${DEPNOTIFY_LOG} \
        ${DEPNOTIFY_DEBUG} \
        ${DEPNOTIFY_RESTART} \
        ${DEPNOTIFY_AGR_DONE} \
        ${DEPNOTIFY_REG_DONE} \
        ${DEPNOTIFY_EULA_TXT_FILE} \
        ${DEPNOTIFY_ENROLLMENT_STARTER} \
        ${DEPNOTIFY_INST_ERR} \
        ${DEPNOTIFY_INST_OUT} \
        ${DEPNOTIFY_DONE}; do

        if [ -e "$thing" ] || [ -d "$thing" ]; then
            # If a DEPNotify log file or dir exists remove it.

            logging "DEPNotify Cleanup: Attempting to remove $thing ..."

            /bin/rm -R "$thing"

            RETURN="$?"

            if [ "$RETURN" -ne 0 ]; then
                # Log that an error occured while removing a file.
                logging "DEPNotify Cleanup: ERROR: Unable to remove $thing"
                return "$RETURN"
            fi

        else
            # File or directory not found.
            logging "DEPNotify Cleanup: $thing not found ..."

        fi

    done
}


main (){
    # Main script that calls everyting else.

    logging "-- Start DEPNotify cleanup --"
    logging "DEPNotify Cleanup: Script version $VERSION"

    wait_for_depnotify_done
    remove_depnotify_daemon
    remove_depnotify_collateral

    logging "-- End DEPNotify Cleanup --"
}

# Call main
main
