#!/bin/sh

###############################################################################
#
#   Post install script for DEPNotify Jamf deployment
#
#   Modified from Arek Dreyer's (@arekdreyer) post-install script fround
#   here: https://gist.github.com/arekdreyer.
#
#   This postinstall script creates the following:
#
#       A LaunchDaemon that starts a separate script to run a Jamf Pro policy
#       command
#
#       A script to wait for Jamf Pro enrollment to complete
#           - then triggers a Jamf Pro policy that triggers DEPNotify
#
#
#   Q&A
#
#       Q: Why not just call the `jamf policy -event` command from the PreStage
#          Enrollment package postinstall script?
#       A: Because the PreStage Enrollment package is installed before the jamf
#          binary is installed.
#
#       Q: Why not just have the postinstall script wait until jamf enrollment
#          is complete?
#       A: Because the postinstall script won't exit while it waits, which
#          prevents enrollment
#
#       Q: Why not just include the DEPNotify.sh script in the PreStage
#          Enrollment package?
#       A: Because every time you update it, for instance POLICY_ARRAY, you'd
#          need to re-build and re-upload the package
#
#       Q: Why not distribute the extra scripts and LaunchDaemons somewhere
#          else, instead of embedding them in this funky postinstall script?
#       A: This way you only have to download and maintain one extra thing.
#
#
#   One approach is to use the following locations and files:
#
#   LaunchDaemon:
#	  /Library/LaunchDaemons/com.captam3rica.DEPNotify-prestarter.plist
#
#   Temporary folder for the installer and scripts:
#	  /usr/local/depnotify-with-installers/
#
#   Scripts:
#
#	  /usr/local/depnotify-with-installers/dep-notify-enrollment-installer.sh
#	  /usr/local/depnotify-with-installers/dep-notify-enrollment-uninstaller.zsh
#
###############################################################################
#
#   UPDATES
#
#   2019-08-16
#
#       - Change interpreter to shell(sh) from zsh
#       - Changes to comment formatting
#       - Change variables to a CAPS_CAPS format
#       - Added complete path to binaries where applicable (i.e. - line #)
#       - Add the functionality for the Packages took to know where additional
#         resouces are located. This will allow everything to be stored in the
#         "Resources" sections of the Packages UI
#
#	2019-12-16
#
#		- Change interpreter path to /bin/sh
#		- Change installer and uninstaller to /bin/sh
#
###############################################################################

# This script must be run as root or via Jamf Pro.
# The resulting Script and LaunchDaemon will be run as root.

# The current working directory where Packages puts additional resources
# associated with the package installer.
HERE=$(/usr/bin/dirname "$0")

# Update this when the DEPNotify installer package is updated.
DEPNOTIFY_PKG_NAME="DEPNotify-1.1.5.pkg"

# You can change any of these:
INSTALLER_BASE_STRING="dep-notify-start-enrollment"
INSTALLER_SCRIPT_NAME="${INSTALLER_BASE_STRING}-installer.sh"
INSTALLER_SCRIPT_PATH="/tmp/${INSTALLER_SCRIPT_NAME}"

# Best to use /Library/LaunchDaemons for the LaunchDaemon
LAUNCH_DAEMON_NAME="com.captam3rica.${INSTALLER_BASE_STRING}.plist"
LAUNCH_DAEMON_LABEL="com.captam3rica.${INSTALLER_BASE_STRING}"
LAUNCH_DAEMON_PATH="/Library/LaunchDaemons"/${LAUNCH_DAEMON_NAME}

DEPNOTIFYSTARTER_TRIGGER="start-depnotify"

# Install the package
/bin/echo "DEBUG: About to install the DEPNotify package ..." >> /tmp/debug_log.log
/bin/echo "DEBUG: Package Path: $HERE/$DEPNOTIFY_PKG_NAME ..." >> /tmp/debug_log.log
/usr/sbin/installer -pkg ${HERE}/${DEPNOTIFY_PKG_NAME} -target /

# The following will create a script that triggers the DEPNotify script to
# start. Be sure the contents are between the two "ENDOFINSTALLERSCRIPT" lines.
# NOTE: Make sure to leave a full return at the end of the Script content
# before the last "ENDOFINSTALLERSCRIPT" line.
/bin/echo "Creating ${INSTALLER_SCRIPT_PATH}."
(
/bin/cat <<ENDOFINSTALLERSCRIPT
#!/bin/sh
until [ -f /var/log/jamf.log ]
do
	/bin/echo "Waiting for jamf log to appear"
	sleep 1
done
until ( /usr/bin/grep -q enrollmentComplete /var/log/jamf.log )
do
	/bin/echo "Waiting for jamf enrollment to be complete."
	sleep 1
done
/usr/local/jamf/bin/jamf policy -event ${DEPNOTIFYSTARTER_TRIGGER}
exit 0

ENDOFINSTALLERSCRIPT
) > "${INSTALLER_SCRIPT_PATH}"

/bin/echo "Setting permissions for ${INSTALLER_SCRIPT_PATH}."
/bin/chmod 755 "${INSTALLER_SCRIPT_PATH}"
/bin/chown root:wheel "${INSTALLER_SCRIPT_PATH}"

#-----------

# The following will create the LaunchDaemon file that starts the script that
# waits for Jamf Pro enrollment then runs the jamf policy -event command to run
# your DEPNotify.sh script.
/bin/echo "Creating ${LAUNCH_DAEMON_PATH}."
(
/bin/cat <<ENDOFLAUNCHDAEMON
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${LAUNCH_DAEMON_LABEL}</string>
	<key>RunAtLoad</key>
	<true/>
	<key>UserName</key>
	<string>root</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/sh</string>
		<string>${INSTALLER_SCRIPT_PATH}</string>
	</array>
	<key>StandardErrorPath</key>
	<string>/var/tmp/${INSTALLER_SCRIPT_NAME}.err</string>
	<key>StandardOutPath</key>
	<string>/var/tmp/${INSTALLER_SCRIPT_NAME}.out</string>
</dict>
</plist>

ENDOFLAUNCHDAEMON
)  > "${LAUNCH_DAEMON_PATH}"

/bin/echo "Setting permissions for ${LAUNCH_DAEMON_PATH}."
/bin/chmod 644 "${LAUNCH_DAEMON_PATH}"
/bin/chown root:wheel "${LAUNCH_DAEMON_PATH}"

/bin/echo "Loading ${LAUNCH_DAEMON_NAME}."
/bin/launchctl load "${LAUNCH_DAEMON_PATH}"

exit 0		## Success
exit 1		## Failure
