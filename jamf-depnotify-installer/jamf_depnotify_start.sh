#!/usr/bin/env sh

####################################################################################################
#
# This Insight Software is provided by Insight on an "AS IS" basis.
#
# INSIGHT MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED 
# WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A PARTICULAR # PURPOSE, 
# REGARDING THE INSIGHT SOFTWARE OR ITS USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR 
# PRODUCTS.
#
# IN NO EVENT SHALL INSIGHT BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL 
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
# MODIFICATION AND/OR DISTRIBUTION OF THE INSIGHT SOFTWARE, HOWEVER, CAUSED AND WHETHER UNDER 
# THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF INSIGHT 
# HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
####################################################################################################
#
# Start DEPNotify Script
#
# Author: Alex Fajerman (alex.fajerman@insight.com)
# Creation date: 2022-03-04
# Last modified date: 2022-05-05
#
####################################################################################################
#
# DESCRIPTION
#
# Master script for DEPNotify. Used for Mac enrollments in Jamf.
#
####################################################################################################
#
# CHANGELOG
#
# - Talk to Alex Fajerman about changes and updates to this script
#
####################################################################################################

####################################################################################################
# VARIABLES
####################################################################################################
# General
Version=4.0
Here=$(/usr/bin/dirname "$0")
ScriptName=$(/usr/bin/basename "$0" | /usr/bin/awk -F "." '{print $1}')

# Organization
OrgName="Your Organization"
JamfURL="https://yourorganization.jamfcloud.com"

# Logging Control
EnrollmentLogFile="$ScriptName-$(date +"%Y-%m-%d").log"
EnrollmentLogPath="/Library/Logs/$EnrollmentLogFile"

# Local System Info
CurrentUser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
SystemArch=$(/usr/bin/arch)
SerialNumber=$(/usr/sbin/ioreg -c IOPlatformExpertDevice -d 2 | /usr/bin/awk '/IOPlatformSerialNumber/ { gsub(/\"/, ""); print $NF;}')
InstallLogFile="install.log"
InstallLogPath="/var/log"

# DEPNotify Logs, Files and BOMs
DEPNotifyTmpPath="/var/tmp"
DEPNotifyLogFile="$DEPNotifyTmpPath/depnotify.log"
DEPNotifyDebugLogFile="$DEPNotifyTmpPath/depnotifyDebug.log"
DEPNotifyNewPlist="/Users/$CurrentUser/Library/Preferences/menu.nomad.DEPNotify.plist"
DEPNotifyDoneBOM="$DEPNotifyTmpPath/com.depnotify.provisioning.done"
DEPNotifyLogoutBOM="$DEPNotifyTmpPath/com.depnotify.provisioning.logout"
DEPNotifyRestartBOM="$DEPNotifyTmpPath/com.depnotify.provisioning.restart"
DEPNotifyAgreeBOM="$DEPNotifyTmpPath/com.depnotify.agreement.done"
DEPNotifyRegistrationDoneBOM="$DEPNotifyTmpPath/com.depnotify.registration.done"

# DEPNotify PreStage Install Files
DEPNotifyScriptsPath="/tmp"
DEPNotifyEnrollmentStartScript="$DEPNotifyScriptsPath/depnotify-start-enrollment-installer.sh"
DEPNotifyEnrollmentInstallerError="$DEPNotifyTmpPath/depnotify-start-enrollment-installer.sh.err"
DEPNotifyEnrollmentInstallerOut="$DEPNotifyTmpPath/depnotify-start-enrollment-installer.sh.out"
DEPNotifyLaunchDaemonPath="/Library/LaunchDaemons"
DEPNotifyLaunchDaemonFile="$DEPNotifyLaunchDaemonPath/com.insight.depnotify-start-enrollment.plist"

# Binaries
DefaultsBinary="/usr/bin/defaults"
DEPNotifyApp="DEPNotify.app"
DEPNotifyPath="/Applications/Utilities/$DEPNotifyApp"
JamfBinary="/usr/local/bin/jamf"
AuthchangerBinary="/usr/local/bin/authchanger"

# Jamf Script Parameter Defaults
TestingMode=true
FullScreen=false
EnableNoSleep=true

# Error Screen Branding
ErrorBannerTitle="Uh oh, Something Needs Fixing!"
ErrorMainText="Configuration has failed. Please refer to the log files at $EnrollmentLogPath and $DEPNotifyDebugFile for more info."
ErrorStatus="Configuration Failed"

# DEPNotify Install
DEPNotifyInstallFromURL=true
DEPNotifyDownloadURL="https://files.nomad.menu/DEPNotify.pkg"
DownloadDir="/var/tmp"
DEPNotifyPkg="DEPNotify.pkg"
DEPNotifyPolicy="install-depnotify"

# Computer Naming
EnableSetComputerName=true
ComputerNamePrefix=""
EnableCustomComputerName=false
ArrayCustomComputerNames=()
ArrayCustomComputerSerials=()

# Appearance and Branding
PolicyDefaultIcon="/System/Library/CoreServices/Install in Progress.app/Contents/Resources/Installer.icns"
EnableCustomIcon=false
CustomIconLocation=""
CustomIconPath="/Users/Shared/Icons"
CustomIconFile="icon.png"
BannerTitle="Welcome to $OrgName"
MainText="Thank you for choosing a Mac at $OrgName! Your Mac is now being configured; this process could take 30 to 45 minutes to complete. \n \n If you need additional software or help, please visit the Self Service app in the Applications folder or on the Dock."
InitialStartStatus="Initial Configuration Starting"
InstallCompleteText="Configuration Complete!"
CompletionMainText="Your Mac has finished configuration. Please click the Restart button to reboot your Mac. Thank you!"
CompletionButtonText="Restart Now"
StatusTextAlignment="center"

# Help Bubble Configuration
EnableHelpBubble=true
HelpContactName="IT Support"
HelpContactInfo="123-456-7890"
HelpBubbleTitle="Need Help?"
HelpBubbleBody="If you encounter issues with enrollment, please contact ${HelpContactName} at ${HelpContactInfo}."

# Policies Array
# Format: "Label Text (required),event or id (required),Jamf custom trigger or ID# (required),/path/to/icon.png (optional)"
#
# Examples:
#	"Installing Microsoft Word,event,install-microsoft-word"
#	"Installing Zoom,id,100"
#	"Running Custom Policy,event,run-policy,/Users/Shared/MyFiles/MyIcon.png"
PolicyArray=(
)

# Jamf Connect Login Window Management
ResetJamfConnectLogin=false

# Stub File Management
CreateEnrollmentCompleteStub=true
EnrollmentCompleteStubFile="/Users/Shared/.enrollment_complete"
CreateMigrationCompleteStub=false
MigrationCompleteStubFile="/Users/Shared/.migration_complete"

# Jamf Recon Management
UpdateUsernameInventoryRecord=true

# Restart Control
EnableMDMRestart=false
MDMRestartCommandPolicy="mdm-restart"
EnableRestartTimer=true
RestartTimer=30
RestartTimerText="Your Mac has finished configuration and will restart in $RestartTimer seconds. Thank you!"

####################################################################################################
# JAMF BUILT-IN VARIABLES VALIDATION
####################################################################################################
# Testing Mode
if [[ "$4" != "" ]]; then TestingMode="$4"; fi
# Fullscreen Mode
if [[ "$5" != "" ]]; then Fullscreen="$5"; fi
# No Sleep / Caffeinate Mode
if [[ "$6" != "" ]]; then EnableNoSleep="$6"; fi

####################################################################################################
# FUNCTIONS
####################################################################################################
# General
get_timestamp() {
	if [[ $1 == "START" ]]; then
		TimestampInfo="START"
	elif [[ $1 == "INFO" ]]; then
		TimestampInfo="INFO"
	elif [[ $1 == "WARN" ]]; then
		TimestampInfo="WARN"
	elif [[ $1 == "ERROR" ]]; then
		TimestampInfo="ERROR"
	elif [[ $1 == "DEBUG" ]]; then
		TimestampInfo="DEBUG"
	elif [[ $1 == "FINISH" ]]; then
		TimestampInfo="FINISH"
	else
		TimestampInfo="INFO"
	fi
	echo $(date +"[[%b %d, %Y %Z %T $TimestampInfo]]: ")
}

logging() {
	# Logging function
	
	if [[ $2 == "START" ]]; then
		LogInfo="START"
	elif [[ $2 == "INFO" ]]; then
		LogInfo="INFO"
	elif [[ $2 == "WARN" ]]; then
		LogInfo="WARN"
	elif [[ $2 == "ERROR" ]]; then
		LogInfo="ERROR"
	elif [[ $2 == "DEBUG" ]]; then
		LogInfo="DEBUG"
	elif [[ $2 == "FINISH" ]]; then
		LogInfo="FINISH"
	else
		LogInfo="INFO"
	fi
	printf "$(date +"[[%b %d, %Y %Z %T $LogInfo]]: ")$1\n" >> "$EnrollmentLogPath"
}

logging_header() {
	logging "" "START"
	logging "--- START DEVICE ENROLLMENT LOG ---" "START"
	logging "" "START"
	logging "$ScriptName Version $Version" "START"
	logging "" "START"
}

logging_footer() {
	logging "" "FINISH"
	logging "--- FINISH DEVICE ENROLLMENT LOG ---" "FINISH"
	logging "" "FINISH"
}

get_current_user() {
	# Return the current user
	
	/bin/echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}'
}

get_current_user_uid() {
	# Return the current user's UID
	
	/bin/echo $(/usr/bin/dscl . -list /Users UniqueID | /usr/bin/grep "$(get_current_user)" | /usr/bin/awk '{print $2}' | /usr/bin/sed -e 's/^[ \t]*//')
}

get_real_name() {
	# Returns the current user's real name
	
	/bin/echo $(id -P $(get_current_user) | cut -d : -f 8)
}

caffeinate_this() {
	# Using Caffeinate binary to keep the computer awake if enabled
	
	if [[ "$EnableNoSleep" == true ]]; then
		logging "Caffeinating DEPNotify process (PID: $DEPNotifyProcess)"
		caffeinate -disu -w "$DEPNotifyProcess" &
	fi
}

create_stub_file() {
	# Create a stub file by passing a path and file name using $1
	
	logging "Creating $1 stub file"
	/usr/bin/touch "$1"
}

# Enrollment
rosetta2_install() {
	# Checks the architecture and installs Rosetta2 if the Mac is on Apple Silicon
	
	logging "Checking to see if we're on Apple Silicon"
	if [[ "$SystemArch" == "arm64" ]]; then
		logging "Running on Apple Silicon"
		logging "Installing Rosetta 2 for compatibility with Intel-based apps"
		/usr/sbin/softwareupdate --install-rosetta --agree-to-license
	else
		logging "Not on Apple Silicon, skipping Rosetta 2"
	fi
}

generate_plist_config() {
	# Create the .plist for DEPNotify to use for various extra settings
	
	CU=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ { print $3 }')
	DEPNotifyConfigPlist="/Users/$CU/Library/Preferences/menu.nomad.DEPNotify.plist"
	logging "DEPNotify preferences file will be stored at $DEPNotifyConfigPlist"
	if [[ "$TestingMode" == true ]] && [[ -f "$DEPNotifyConfigPlist" ]]; then
		rm "$DEPNotifyConfigPlist"
	fi
	
	# Write settings for status text alignment
	logging "Plist Setting: Setting statusTextAlignment to $StatusTextAlignment"
	defaults write "$DEPNotifyConfigPlist" statusTextAlignment "$StatusTextAlignment"
	
	# Write settings for the help bubble
	if [[ "$EnableHelpBubble" == true ]]; then
		logging "Plist Setting: Setting help bubble options"
		defaults write "$DEPNotifyConfigPlist" helpBubble -array-add "$HelpBubbleTitle"
		defaults write "$DEPNotifyConfigPlist" helpBubble -array-add "$HelpBubbleBody"
	fi
	
	# Set ownership and permissions of the .plist
	logging "Setting ownership and permissions of $DEPNotifyConfigPlist"
	chown "$CU":staff "$DEPNotifyConfigPlist"
	chmod 600 "$DEPNotifyConfigPlist"
}

check_for_depnotify() {
	# Check to ensure that DEPNotify is installed before moving on to the next step.
	# If it is not installed attempt to reinstall it by downloading and installing it directly from Github.
	# If DEPNotify cannot be installed via policy, the script will exit 1 after 30 seconds of waiting.
	
	Counter=0
	FailCount=30
	logging "Making sure DEPNotify is installed"
	while [[ ! -e "${DEPNotifyPath}" ]]; do
		logging "DEPNotify has not been installed yet"
		if [[ ! -e "${DEPNotifyPath}" ]] && [[ "$Counter" -eq 5 ]]; then
			# If Jamf Connect is not installed, attempt to download it directly and install it.
			logging "Waited 5 seconds for DEPNotify"
			logging "Attempting to install DEPNotify"
			if [[ "${DEPNotifyInstallFromURL}" == true ]]; then
				logging "Downloading DEPNotify from ${DEPNotifyDownloadURL} using curl"
				curl -L -o "${DownloadDir}/${DEPNotifyPkg}" "${DEPNotifyDownloadURL}"
				logging "Installing DEPNotify"
				/usr/sbin/installer -pkg "${DownloadDir}/${DEPNotifyPkg}" -target /
			else
				logging "Downloading and installing DEPNotify via Jamf policy ${DEPNotifyPolicy}"
				"$JamfBinary" policy -event "${DEPNotifyPolicy}"
			fi
		fi
		logging "Waiting 1 second before checking again"
		/bin/sleep 1
		FindApp=$(/usr/bin/find "/Applications" -maxdepth 2 -iname "$DEPNotifyApp")
		Counter=$((Counter + 1))
		if [[ "$Counter" = "$FailCount" ]]; then
			logging "We waited $FailCount seconds, it did not install, aborting with exit 1" "ERROR"
			exit 1
		fi
	done
	logging "Found DEPNotify at $DEPNotifyPath"
}

depnotify_testing_check() {
	# Check and Warning if Testing Mode is off and BOM files exist
	
	logging "Script testing check"
	if [[ (-f $DEPNotifyLogFile || -f $DEPNotifyDoneBOM) && "$TestingMode" == false ]]; then
		/bin/echo "$(get_timestamp "ERROR") Testing Mode set to false but config files were found in /var/tmp. Letting user know and exiting." >>"$DEPNotifyDebugLogFile"
		mv "$DEPNotifyLogFile" "/var/tmp/depnotify_old.log"
		/bin/echo "Command: MainTitle: $ErrorBannerTitle" >> "$DEPNotifyLogFile"
		/bin/echo "Command: MainText: $ErrorMainText" >> "$DEPNotifyLogFile"
		/bin/echo "Status: $ErrorStatus" >> "$DEPNotifyLogFile"
		sudo -u "$(get_current_user)" open -a "$DEPNotifyPath" --args -path "$DEPNotifyLogFile"
		/bin/sleep 5
		exit 1
	fi
}

validate_true_false_flags() {
	# Validate true/false flags that are set in the Jamf console for this DEPNotify script
	
	if [[ "$TestingMode" != true ]] && [[ "$TestingMode" != false ]]; then
		/bin/echo "$(get_timestamp "DEBUG") Testing configuration not set properly. Currently set to $TestingMode. Please update to true or false." >>"$DEPNotifyDebugLogFile"
		logging "Testing configuration not set properly. Currently set to $TestingMode. Please update to true or false." "DEBUG"

		# Setting Quit Key set to command + control + x (Testing Mode Only)
		/bin/echo "Command: QuitKey: x" >> "$DEPNotifyLogFile"
	fi
	
	if [[ "$Fullscreen" != true ]] && [[ "$Fullscreen" != false ]]; then
		/bin/echo "$(get_timestamp "DEBUG") Fullscreen configuration not set properly. Currently set to $Fullscreen. Please update to true or false." >>"$DEPNotifyDebugLogFile"
		logging "Fullscreen configuration not set properly. Currently set to $Fullscreen. Please update to true or false." "DEBUG"
		exit 1
	fi
	
	if [[ "$EnableNoSleep" != true ]] && [[ "$EnableNoSleep" != false ]]; then
		/bin/echo "$(get_timestamp "DEBUG") Sleep configuration not set properly. Currently set to $EnableNoSleep. Please update to true or false." >>"$DEPNotifyDebugLogFile"
		logging "Sleep configuration not set properly. Currently set to $EnableNoSleep. Please update to true or false." "DEBUG"
		exit 1
	fi
}

get_setup_assistant_process() {
	# Wait for Setup Assisant to finish before continuing
	
	ProcessName="Setup Assistant"
	SetupAssistantProcess=""
	logging "Checking to see if $ProcessName is running"
	
	while [[ $SetupAssistantProcess != "" ]]; do
		logging "$ProcessName still running  PID: $SetupAssistantProcess"
		logging "Sleeping 1 second "
		/bin/sleep 1
		SetupAssistantProcess=$(/usr/bin/pgrep -l "$ProcessName")
	done
	logging "$ProcessName finished"
}

wait_for_current_user() {
	# Checks the current user's UID; if it's less than 501, loops and waits until the user is logged in. Once the UID is equal to or greater than 501, the script proceeds. This is to prevent a scenario where a system account such as SetupAssistant is still doing stuff and DEPNotify tries to start.

	CurrentUserUID=$(get_current_user_uid)
	while [[ $CurrentUserUID -lt 501 ]]; do
		logging "User is not logged in, waiting"
		/bin/sleep 1
		CurrentUserUID=$(get_current_user_uid)
	done
	logging "Current user: $(get_current_user) with UID $(get_current_user_uid)"
}

get_finder_process() {
	# Check to see if the Finder is running yet. If it is, continue. Nice for instances where the user is not setting up a username during the Setup Assistant process.
	
	logging "Checking to see if the Finder process is running"
	FinderProcess=$(/usr/bin/pgrep -l "Finder" 2>/dev/null)
	Response=$?
	logging "Finder PID: $FinderProcess"
	while [[ $Response -ne 0 ]]; do
		logging "Finder PID not found. Assuming device is sitting at the login window"
		/bin/sleep 1
		FinderProcess=$(/usr/bin/pgrep -l "Finder" 2>/dev/null)
		Response=$?
		if [[ $FinderProcess != "" ]]; then
			logging "Finder PID: $FinderProcess"
		fi
	done
}

set_computer_name() {
	# Set the computer name

	if [[ $EnableSetComputerName == true ]]; then
		# Setting a custom name
		if [[ $EnableCustomComputerName == true ]]; then
			logging "Custom naming enabled, checking Mac serial number $SerialNumber"
		
			# Check the list of known serials for a match.
			for i in "${!ArrayCustomComputerSerials[@]}"; do
				if [[ " ${ArrayCustomComputerSerials[$i]} " =~ " $SerialNumber " ]]; then
					logging "Serial $SerialNumber found in custom names list"
					MatchFound=true
					break
				else
					MatchFound=false
				fi
			done
		
			if [[ $MatchFound == true ]]; then
				# Mac SN is in the list, checking to see if there's a corresponding name.
				if [[ ${ArrayCustomComputerNames[$i]} = "" ]]; then
					logging "Serial/name match not found"
					MacName="$ComputerNamePrefix$SerialNumber"
				else
					MacName="${ArrayCustomComputerNames[$i]}"
					logging "Serial/name match found ($SerialNumber, $MacName)"
				fi
			else
				# Mac SN not matched, using the default naming scheme.
				logging "No match, defaulting to $ComputerNamePrefix$SerialNumber"
				MacName="$ComputerNamePrefix$SerialNumber"
			fi
		else
			logging "Custom Mac naming not enabled, setting name to $ComputerNamePrefix$SerialNumber"
			MacName="$ComputerNamePrefix$SerialNumber"
		fi
		logging "Setting computer name to $MacName"
		
		# Set the computer name using scutil.
		/usr/sbin/scutil --set ComputerName "$MacName"
		/usr/sbin/scutil --set LocalHostName "$MacName"
		/usr/sbin/scutil --set HostName "$MacName"
	
		# Set the computer name using Jamf binary.
		"$JamfBinary" setComputerName -name "$MacName"
		Return="$?"
	
		if [[ "$Return" -ne 0 ]]; then
			# Naming failed.
			logging "Failed to set computer name with Jamf name command"
			ReturnCode="$Return"
		fi
	
		# Flush DNS cache.
		dscacheutil -flushcache
	else
		logging "Not setting the computer name"
	fi
}

custom_branding() {
	# Applies branding to the DEPNotify window
	
	logging "Setting up branding for banner image, banner title and main text"
	if [[ "$EnableCustomIcon" == true ]]; then
		logging "Using a custom icon"
		if [[ $(echo $CustomIconLocation | cut -c1-4) == "http" ]]; then
			logging "Icon location is a URL"
			if [[ ! -d "$CustomIconPath" ]]; then
				logging "$CustomIconPath not found, creating"
				mkdir -p "$CustomIconPath"
			fi
			logging "Grabbing icon from $CustomIconLocation"
			curl -L -o "$CustomIconPath/$CustomIconFile" $CustomIconLocation
			if [[ -s "$CustomIconPath/$CustomIconFile" ]]; then
				logging "Custom icon successfully dowloaded to $CustomIconPath/$CustomIconFile"
				PolicyDefaultIcon="$CustomIconPath/$CustomIconFile"
			else
				logging "File is empty, deleting and using default $PolicyDefaultIcon"
				sudo rm -f "${CustomIconPath}/${CustomIconFile}"
			fi
		elif [[ $(echo $CustomIconLocation | cut -c1) == "/" ]]; then
			logging "Icon is local"
			PolicyDefaultIcon="$CustomIconLocation"
		else
			logging "Custom icon location is invalid, using $PolicyDefaultIcon"
		fi
	else
		logging "Not using a custom icon, using $PolicyDefaultIcon"
	fi
	/bin/echo "Command: Image: $PolicyDefaultIcon" >> "$DEPNotifyLogFile"
	/bin/echo "Command: MainTitle: $BannerTitle" >> "$DEPNotifyLogFile"
	/bin/echo "Command: MainText: $MainText" >> "$DEPNotifyLogFile"
}

launch_depnotify() {
	# Open the DEPNotiy app after initial configuration
	
	logging "Removing the quarantine bit from the DEPNotify app"
	sudo xattr -r -d com.apple.quarantine "${DEPNotifyPath}"
	logging "Opening DEPNotify as user $(get_current_user)"
	if [[ "$Fullscreen" == true ]]; then
		sudo -u "$(get_current_user)" /usr/bin/open -a "${DEPNotifyPath}" --args -path "$DEPNotifyLogFile" -fullScreen
	elif [[ "$Fullscreen" == false ]]; then
		sudo -u "$(get_current_user)" /usr/bin/open -a "${DEPNotifyPath}" --args -path "$DEPNotifyLogFile"
	fi
}

get_depnotify_process() {
	# Grab the DEPNotify PID and caffeinate it
	
	DEPNotifyProcess=$(pgrep -l "DEPNotify" | cut -d " " -f1)
	until [[ "$DEPNotifyProcess" != "" ]]; do
		logging "Waiting for DEPNotify to start to gather the process ID"
		/bin/echo "$(get_timestamp) Waiting for DEPNotify to start to gather the process ID" >>"$DEPNotifyDebugLogFile"
		/bin/sleep 1
		DEPNotifyProcess=$(pgrep -l "DEPNotify" | cut -d " " -f1)
	done
	caffeinate_this "$DEPNotifyProcess"
}

pretty_pause() {
	# Add initial status text and a brief pause for prettiness
	
	/bin/echo "Status: $InitialStartStatus" >> "$DEPNotifyLogFile"
	/bin/sleep 3
}

status_bar_gen() {
	# Set up the status bar
	
	AdditionalOptionsCounter=1
	
	# Increment status Counter for submitting Jamf inventory at end of DEPNotify
	AdditionalOptionsCounter=$((AdditionalOptionsCounter++))
	
	# Check policy array and add the count from the additional options above.
	PolicyArrayLength="$((${#PolicyArray[@]} + AdditionalOptionsCounter))"
	/bin/echo "Command: Determinate: $PolicyArrayLength" >> "$DEPNotifyLogFile"
}

install_policies() {
	# Install policies by looping through the policy array
	
	logging "Preparing to run Jamf policies"
	for policy in "${PolicyArray[@]}"; do
		if [[ "$TestingMode" == true ]]; then
			logging "Test mode enabled"
			sleep 10
		elif [[ "$TestingMode" == false ]]; then
			PolicyStatus=$(/bin/echo "$policy" | cut -d ',' -f1)
			PolicyType=$(/bin/echo "$policy" | cut -d ',' -f2)
			PolicyName=$(/bin/echo "$policy" | cut -d ',' -f3)
			PolicyIcon=$(/bin/echo "$policy" | cut -d ',' -f4)
			logging "Calling policy $PolicyStatus"
			logging "Policy type is: $PolicyType"
			/bin/echo "Status: $PolicyStatus" >> "$DEPNotifyLogFile"
			if [[ "$PolicyIcon" = "" ]] || [[ ! -f "$PolicyIcon" ]]; then
				# Icon path/file is either not set or not found; set to PolicyDefaultIcon
				/bin/echo "Command: Image: $PolicyDefaultIcon" >> "$DEPNotifyLogFile"
			else
				# Icon found
				/bin/echo "Command: Image: $PolicyIcon" >> "$DEPNotifyLogFile"
			fi
			
			if [[ $PolicyType = "event" ]]; then
				"$JamfBinary" policy -event "$PolicyName" | /usr/bin/sed -e "s/^/$(get_timestamp) /" | /usr/bin/tee -a "$EnrollmentLogPath" >/dev/null 2>&1
			elif [[ $PolicyType = "id" ]]; then
				"$JamfBinary" policy -id "$PolicyName" | /usr/bin/sed -e "s/^/$(get_timestamp) /" | /usr/bin/tee -a "$EnrollmentLogPath" >/dev/null 2>&1
			else
				logging "Invalid policy type or no policy type specified"
			fi
		fi
	done
}

jamf_connect_login_window() {
	# Reset login window to macOS default if Jamf Connect is installed

	if [[ "$ResetJamfConnectLogin" == true ]]; then
		if [[ -e "$AuthchangerBinary" ]]; then
			logging "Invoking Jamf Connect authchanger and resetting login window to macOS default"
			"$AuthchangerBinary" -reset
		else
			logging "ResetJamfConnectLogin is set to true but authchanger binary not found at $AutchangerBinary"
		fi
	fi
}

create_enrollment_stub_file() {
	# Create the enrollment complete stub file
	
	if [[ $CreateEnrollmentCompleteStub == true ]]; then
		create_stub_file "$EnrollmentCompleteStubFile"
	fi
}

create_migration_stub_file() {
	# Create the migration complete stub file
	
	if [[ $CreateMigrationCompleteStub == true ]]; then
		create_stub_file "$MigrationCompleteStubFile"
	fi
}

checkin_to_jamf() {
	# Force the Mac to check in to Jamf and submit inventory
	
	logging "Submitting device inventory to Jamf"
	/bin/echo "Status: Submitting device inventory to Jamf" >> "$DEPNotifyLogFile"
	if [[ $UpdateUsernameInventoryRecord == true ]]; then
		"$JamfBinary" recon -endUsername "$(get_current_user)" -realname "$(get_real_name)"
	else
		"$JamfBinary" recon
	fi
}

script_completion() {
	# Set script completion text, button and restart behavior

	/bin/echo "Status: $InstallCompleteText" >> "$DEPNotifyLogFile"
	if [[ "$TestingMode" == true ]]; then
		/bin/echo "Command: ContinueButton: Quit" >> "$DEPNotifyLogFile"
	else
		if [[ $EnableRestartTimer == true ]]; then
			logging "Script Completion: Automatic Restart with $RestartTimer second delay"
			/bin/echo "Command: MainText: $RestartTimerText" >> "$DEPNotifyLogFile"
			Timer=$RestartTimer
			until [[ $Timer = 0 ]]; do
				if [[ $Timer = 1 ]]; then
					/bin/echo "Status: Restarting in $Timer second" >> "$DEPNotifyLogFile"
					sleep 1
				else
					/bin/echo "Status: Restarting in $Timer seconds" >> "$DEPNotifyLogFile"
					sleep 1
				fi
				Timer=$((Timer-1))
			done
			touch $DEPNotifyDoneBOM
			/bin/echo "Command: Quit" >> "$DEPNotifyLogFile"
		else
			logging "Script Completion: Restart with Button"
			/bin/echo "Command: MainText: $CompletionMainText" >> "$DEPNotifyLogFile"
			/bin/echo "Command: ContinueButton: $CompletionButtonText" >> "$DEPNotifyLogFile"
		fi
	fi
	logging "Setting up restart behavior"
	if [[ "$EnableMDMRestart" == true ]]; then
		logging "Restart Command: Jamf policy $MDMRestartCommandPolicy"
	else
		logging "Restart Command: shutdown -r now"
	fi
}

depnotify_cleanup() {
	# Remove the files and directories left behind by DEPNotify once the Mac setup is complete
	
	logging "-- Start DEPNotify Cleanup --"
	# Wait for the user to press the Restart button
	while [[ ! -f "$DEPNotifyLogoutBOM" ]] || [[ ! -f "$DEPNotifyDoneBOM" ]]; do
		logging "DEPNotify Cleanup: Waiting for Completion file"
		logging "DEPNotify Cleanup: The user has not closed the DEPNotify window"
		logging "DEPNotify Cleanup: Waiting 1 second"
		/bin/sleep 1
		if [[ -f "$DEPNotifyDoneBOM" ]]; then
			logging "DEPNotify Cleanup: Found $DEPNotifyDoneBOM"
			break
		fi
		
		if [[ -f "$DEPNotifyLogoutBOM" ]]; then
			logging "DEPNotify Cleanup: Found $DEPNotifyLogoutBOM"
			break
		fi
	done
	
	# Remove the LaunchDaemon. This will prevent DEPNotify from launching again after the restart.
	
	if [[ -e "$DEPNotifyLaunchDaemonFile" ]]; then
		logging "DEPNotify Cleanup: Removing LaunchDaemon"
		/bin/rm -R "$DEPNotifyLaunchDaemonFile"
	else
		logging "DEPNotify Cleanup: LaunchDaemon not installed"
	fi
		
	# Remove DEPNotify files. Loop through and remove all files associated with DEPNotify.
	
	for i in \
		"${DownloadDir}/${DEPNotifyPkg}" \
		${DEPNotifyPath} \
		${DEPNotifyNewPlist} \
		${DEPNotifyLogFile} \
		${DEPNotifyDebug} \
		${DEPNotifyRestartBOM} \
		${DEPNotifyAgreeBOM} \
		${DEPNotifyRegistrationDoneBOM} \
		${DEPNotifyEULATextFile} \
		${DEPNotifyEnrollmentStartScript} \
		${DEPNotifyEnrollmentInstallerError} \
		${DEPNotifyEnrollmentInstallerOut} \
		${DEPNotifyDoneBOM} \
		${DEPNotifyLogoutBOM}; do
			if [[ -e "$i" ]] || [[ -d "$i" ]]; then
				# Remove DEPNotify objects if they exist
			
				logging "DEPNotify Cleanup: Attempting to remove $i"
				/bin/rm -R "$i"
				Return="$?"
				if [[ "$Return" -ne 0 ]]; then
					# Log that an error occured while removing an object
					
					logging "DEPNotify Cleanup: Unable to remove $i" "ERROR"
					return "$Return"
				fi
			else
				# File or directory not found
				
				logging "DEPNotify Cleanup: $i not found" "WARN"
			fi
		done
	logging "-- End DEPNotify Cleanup --"
}

restart_command() {
	# Perform an MDM command restart if EnableMDMRestart is set; else, perform a regular restart
	
	if [[ "$EnableMDMRestart" == true ]]; then
		"$JamfBinary" policy -event "$MDMRestartCommandPolicy"
	else
		sudo shutdown -r now
	fi
}

####################################################################################################
# MAIN
####################################################################################################
# Set up the log header
logging_header

# Check to see if we are running on an Apple Silicon Mac and install Rosetta 2 if so
rosetta2_install

# Validate Jamf variables
validate_true_false_flags

# Get the Setup Assistant process
get_setup_assistant_process

# Wait for the current user to be logged in
wait_for_current_user

# Wait for the Finder process to be available
get_finder_process

# Check for DEPNotify; if this fails, the script exits
check_for_depnotify

# Check testing mode and existence of BOM files; exits if things are not set up correctly
depnotify_testing_check

# Generate the .plist config file
generate_plist_config

# Set the computer name
set_computer_name

# Update username in the Mac's Jamf inventory record
update_username_in_jamf

# Custom branding
custom_branding

# Launch DEPNotify
launch_depnotify

# Get DEPNotify process info and caffeinate it
get_depnotify_process

# Build the status bar
status_bar_gen

# Run policies
install_policies

# Reset the Jamf Connect login window
jamf_connect_login_window

# Create stub files
create_enrollment_stub_file
create_migration_stub_file

# Update inventory in Jamf
checkin_to_jamf

# Script completion behaviors
script_completion

# Cleanup
depnotify_cleanup

# Logging footer
logging_footer

# Restart the Mac right after the script finishes
restart_command

exit 0	# Success
exit 1	# Failure