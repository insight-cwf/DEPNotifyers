#!/usr/bin/env bash

# GitHub: @captam3rica
VERSION=2.3.1

###################################################################################################
#
# This Insight Software is provided by Insight on an "AS IS" basis.
#
# INSIGHT MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE
# IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A PARTICULAR
# PURPOSE, REGARDING THE INSIGHT SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
# COMBINATION WITH YOUR PRODUCTS.
#
# IN NO EVENT SHALL INSIGHT BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY
# WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE INSIGHT
# SOFTWARE, HOWEVER, CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING
# NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF INSIGHT HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
###################################################################################################
#
#   DESCRIPTION
#
#       This script is designed to make the implementation of DEPNotify very easy with
#       limited scripting knowledge. The section below has variables that may be
#       modified to customize the end-user experience. DO NOT modify things in or below
#       the CORE LOGIC area unless major testing and validation are performed.
#
###################################################################################################
#
#   CHANGELOG
#
#	- See the CHANGELOG file at https://github.com/insight-cwf/DEPNotifyers
#
###################################################################################################

###################################################################################################
###################################### VARIABLES ##################################################
###################################################################################################

########################################################################################captam3rica
# TESTING MODE - Jamf builtin $4
###################################################################################################
# The TESTING_MODE flag will enable the following things to change:
#   - Auto removal of BOM files to reduce errors
#   - Sleep commands instead of policies or other changes being called
#   - Quit Key set to command + control + x
TESTING_MODE=true # Can be set to true or false

###################################################################################################
# Trigger to be used to call the policy
###################################################################################################
# Policies can be called be either a custom trigger or by policy id. Select either
# event, to call the policy by the custom trigger, or id to call the policy by id.
TRIGGER="event"

###################################################################################################
# POLICY ARRAY VARIABLE TO MODIFY
###################################################################################################
# The policy array must be formatted "Progress Bar text,customTrigger". These
# will be run in order as they appear below.
#
# Where applicable, updated the array with applications that are being deployed from
# Jamf during device enrollment. If the application already exists on the device then
# we want to skip that app. This can happen is cases like re-enrollment or if the
# device is pre-existing when the device is not wiped prior to enrolling.
POLICY_ARRAY=(
    # "Installing Google Chrome Browser,google-chrome,Application Name.app"
)

###################################################################################################
# (OPTIONAL) APP ICON ARRAY VARIABLE TO MODIFY
###################################################################################################
#
# The icon array must be formatted "App Name,/path/to/local/image.png". The same App
# name should be contained in both the App Icon Array and the Policy array so that the
# script can determine which icon needs to be displayed. The order of the icons in
# the icon array must match the order of the policy array above so that the right App
# icon is displayed as the App is being installed.
#
# In the example below Google Chrome is contained in both the policy array and icon
# array.
#
#   Example
#
#       - Policy array: "Installing Google Chrome Browser,google-chrome"
#       - Icon array:   "Google Chrome,/path/to/google_chrome_browser_icon.png"
#
# The icon images (png format) will need to be included in the jamf-depnotify-installer
# distribution package used to deploy DEPNotify during enrollment.
#
#   An example directory path to place the icons could be as follows where tmp is as
#   the root (/) of the file system.
#
#       tmp
#       │
#       └───depnotify
#           │
#           └───icons
#                   google_chrome_icon.png
#                   firefox_icon.png
#                   my_orgs_icon.png
#
APP_ICON_ARRAY=(
    # "Google Chrome,/tmp/depnotify/icons/google_chrome_browser_icon.png"
)

###################################################################################################
# COMPUTER NAME
###################################################################################################
# Setting the COMPUTER_NAME_ENABLE varialbe to true will rename the Mac to the device
# serial number. Otherwise the computer will be set to something like "John's MacBook"
# or "Jane's iMacPro". Alternatively, you can set the computer name via MDM.
COMPUTER_NAME_ENABLE=false

# COMPUTER NAME PREFIX
# Update the PREFIX varialbe below if you would like to prepend the Mac computer name
# with a static prefix.
PREFIX=""

###################################################################################################
# JAMF CONNECT - Jamf builtin $11
###################################################################################################
# If Jamf Connect is being used set the 11th script parameter in the Jamf script policy
# to true
# JAMF_CONNECT_ENABLED=false

###################################################################################################
# SAP PRIVILEGES APP
###################################################################################################
# Privileges.app for macOS is designed to allow users to work as a standard user for
# day-to-day use, by providing a quick and easy way to get administrator rights when
# needed. When you do need admin rights, you can get them by clicking on the Privileges
# icon in your Dock.
#
# This functionality requires that an SAP Privileges app istallaton policy be added to
# Jamf Cloud and called via jamp policy.
#
# An example package can be found in the following GitHub Repo:
SAP_PRIVILEGES_APP_ENABLED=false

###################################################################################################
# UPDATE USERNAME INVENTORY RECORD
###################################################################################################
# This functionality requires that the update-username-inventory-record.sh
# script be uploaded to Jamf and called as a policy.
#
# A copy of the script can be found here: https://github.com/captam3rica/Scripts/blob/master/jamf/update-username-inventory-record.sh
#
# If the user is created during Automated enrollment the Jamf Pro inventory
# record is updated to include this username.
#
# If the Mac is enrolled via User-Initiated enrollment the script first
# checks to see if the Jamf inventory record needs to be updated with the
# current logged in user. Next, the script checks the currently logged in
# user and the username assigned in Jamf to see if they match.  If desired,
# the script will update the Jamf Pro inventory record with the current local
# username. Otherwise, this information is logged for later review.
UPDATE_USERNAME_INVENTORY_RECORD_ENABLED=false

###################################################################################################
# BIND TO ACTIVE DIRECTORY
###################################################################################################
# This functionality requires that a Directory Binding policy be created in
# Jamf. This policy must have a customer trigger set to "directory-binding",
# and an "Execution Frequency" set to "Ongoing". Once those items are in place
# set the DIRECTORY_BINDING_ENABLED varilable below to true.
DIRECTORY_BINDING_ENABLED=false

###################################################################################################
# REBOOT ONCE ENROLLMENT IS FINISHED
###################################################################################################
# Leverages the DEPNotify Restart command to reboot the Mac after setup completes.
RESTART_ENABLED=false

###################################################################################################
# GENERAL APPEARANCE
###################################################################################################

# Flag the app to open fullscreen or as a window
# Jamf builtin $5
FULLSCREEN=true # Set variable to true or false

# Banner image can be 600px wide by 100px high. Images will be scaled to fit
# If this variable is left blank, the generic image will appear. If using
# custom Self Service branding, please see the Customized Self Service Branding
# area below.

BANNER_IMAGE_PATH="/Applications/Self Service.app/Contents/Resources/AppIcon.icns"

# Update the variable below replacing "Organization" with the actual name of your
# organization. Example "ACME Corp Inc."
YOUR_ORG_NAME_HERE="Organization"

# Main heading that will be displayed under the image If this variable is left
# blank, the generic banner will appear

BANNER_TITLE="Welcome to $YOUR_ORG_NAME_HERE"

# Paragraph text that will display under the main heading. For a new line,
# use \n If this variable is left blank, the generic message will appear.
# Leave single quotes below as double quotes will break the new lines.

MAIN_TEXT='Thanks for choosing a Mac at '$YOUR_ORG_NAME_HERE'! We want you to have a few applications and settings configured before you get started with your new Mac. This process should take 10 to 20 minutes to complete. \n \n If you need additional software or help, please visit the Self Service app in your Applications folder or on your Dock.'

# Initial Start Status text that shows as things are firing up
INITAL_START_STATUS="Initial Configuration Starting..."

# Text that will display in the progress bar
INSTALL_COMPLETE_TEXT="Configuration Complete!"

# Complete messaging to the end user can ether be a button at the bottom of the
# app with a modification to the main window text or a dropdown alert box.
# Default value set to false and will use buttons instead of dropdown messages.

# Jamf builtin $8
COMPLETE_METHOD_DROPDOWN_ALERT=false # Set variable to true or false

# Script designed to automatically logout user to start FileVault process if
# deferred enablement is detected. Text displayed if deferred status is on.
# Option for dropdown alert box

FV_ALERT_TEXT='Your Mac must logout to start the encryption process. You will be asked to enter your password and click OK or Continue a few times. Your Mac will be usable encryption takes place.'

# Options if not using dropdown alert box
FV_COMPLETE_MAIN_TEXT='Your Mac must logout to start the encryption process. You will be asked to enter your password and click OK or Continue a few times. Your Mac will be usable while encryption takes place.'

FV_COMPLETE_BUTTON_TEXT="Logout"

# Text that will display inside the alert once policies have finished
# Option for dropdown alert box
COMPLETE_ALERT_TEXT='Your Mac is now finished with initial setup and configuration. Press Quit to get started!'

# Options if not using dropdown alert box
COMPLETE_MAIN_TEXT='Your Mac is now finished with initial setup and configuration.'

COMPLETE_BUTTON_TEXT="Get Started!"

###################################################################################################
# PLIST CONFIGURATION
###################################################################################################
# The menu.depnotify.plist contains more and more things that configure the
# DEPNotify app. You may want to save the file for purposes like verifying EULA
# acceptance or validating other options.

# Plist Save Location
# This wrapper allows variables that are created later to be used but also
# allow for configuration of where the plist is stored
info_plist_wrapper() {

    cu="$1"

    DEP_NOTIFY_USER_INPUT_PLIST="/Users/$cu/Library/Preferences/menu.nomad.DEPNotifyUserInput.plist"
}

# Status Text Alignment
# The status text under the progress bar can be configured to be left, right,
# or center
STATUS_TEXT_ALIGN="center"

# Help Button Configuration
# The help button was changed to a popup. Button will appear if title is
# populated.
HELP_BUBBLE_TITLE="Need Help?"
HELP_BUBBLE_BODY='This tool at '$YOUR_ORG_NAME_HERE' is designed to help \nwith new employee onboarding. \nIf you have issues, please give us a \ncall at 123-456-7890'

###################################################################################################
# Error Screen Text
###################################################################################################
# If testing mode is false and configuration files are present, this text will
# appear to the end user and asking them to contact IT. Limited window options
# here as the assumption is that they need to call IT. No continue or exit
# buttons will show for DEP Notify window and it will not show in fullscreen.
# IT staff will need to use Terminal or Activity Monitor to kill DEP Notify.

# Main heading that will be displayed under the image
ERROR_BANNER_TITLE="Uh oh, Something Needs Fixing!"

# Paragraph text that will display under the main heading. For a new line, use
# \n. If this variable is left blank, the generic message will appear. Leave
# single quotes below as double quotes will break the new lines.
ERROR_MAIN_TEXT='We are sorry that you are experiencing this inconvenience with your new Mac. However, we have the nerds to get you back up and running in no time! \n \n Please contact IT right away and we will take a look at your computer ASAP. \n \n Phone: 123-456-7890'

# Error status message that is displayed under the progress bar
ERROR_STATUS="Setup Failed"

###################################################################################################
# Caffeinate / No Sleep Configuration - Jamf builtin $6
###################################################################################################
# Flag script to keep the computer from sleeping. BE VERY CAREFUL WITH THIS
# FLAG! This flag could expose your data to risk by leaving an unlocked
# computer wide open. Only recommended if you are using fullscreen mode and
# have a logout taking place at the end of configuration (like for FileVault).
# Some folks may use this in workflows where IT staff are the primary people
# setting up the device. The device will be allowed to sleep again once the
# DEPNotify app is quit as caffeinate is looking at DEPNotify's process ID.
NO_SLEEP=false

###################################################################################################
# Customized Self Service Branding - Jamf builtin $7
###################################################################################################
# Flag for using the custom branding icon from Self Service and Jamf Pro
# This will override the banner image specified above. If you have changed the
# name of Self Service, make sure to modify the Self Service name below.
# Please note, custom branding is downloaded from Jamf Pro after Self Service
# has opened at least one time. The script is designed to wait until the files
# have been downloaded. This could take a few minutes depending on server and
# network resources.
SELF_SERVICE_CUSTOM_BRANDING=false # Set variable to true or false

# If using a name other than Self Service with Custom branding. Change the
# name with the SELF_SERVICE_APP_NAME variable below. Keep .app on the end
SELF_SERVICE_APP_NAME="Self Service.app"

###################################################################################################
# EULA Variables to Modify - Jamf builtin $9
###################################################################################################
# EULA configuration
EULA_ENABLED=false # Set variable to true or false

# EULA status bar text
EULA_STATUS="Waiting on completion of EULA acceptance"

# EULA button text on the main screen
EULA_BUTTON="Read and Agree to EULA"

# EULA Screen Title
EULA_MAIN_TITLE="$YOUR_ORG_NAME_HERE End User License Agreement"

# EULA Subtitle
EULA_SUBTITLE='Please agree to the following terms and conditions to start configuration of this Mac'

# Path to the EULA file you would like the user to read and agree to. It is
# best to package this up with Composer or another tool and deliver it to a
# shared area like /Users/Shared/
EULA_FILE_PATH="/Users/Shared/eula.txt"

###################################################################################################
# Registration Variables to Modify - Jamf builtin $10
###################################################################################################

# Registration window configuration
REGISTRATION_ENABLED=false # Set variable to true or false

# Registration window title
REGISTRATION_TITLE="Mac Registration at $YOUR_ORG_NAME_HERE"

# Registration status bar text
REGISTRATION_STATUS="Waiting on completion of computer registration"

# Registration window submit or finish button text
REGISTRATION_BUTTON="Register Your Mac"

# The text and pick list sections below will write the following lines out for
# end users. Use the variables below to configure what the sentence says
# Ex: Setting Computer Name to macBook0132
REGISTRATION_BEGIN_WORD="Setting"
REGISTRATION_MIDDLE_WORD="to"

# Registration window can have up to two text fields. Leaving the text display
# variable empty will hide the input box. Display text is to the side of the
# input and placeholder text is the gray text inside the input box.
# Registration window can have up to four dropdown / pick list inputs. Leaving
# the pick display variable empty will hide the dropdown / pick list.

# First Text Field
###################################################################################################
# Text Field Label
REG_TEXT_LABEL_1="Computer Name"

# Place Holder Text
REG_TEXT_LABEL_1_PLACEHOLDER="macBook0123"

# Optional flag for making the field an optional input for end user
REG_TEXT_LABEL_1_OPTIONAL="false" # Set variable to true or false

# Help Bubble for Input. If title left blank, this will not appear
REG_TEXT_LABEL_1_HELP_TITLE="Computer Name Field"
REG_TEXT_LABEL_1_HELP_TEXT='This field is sets the name of your new Mac to what is in the Computer Name box. This is important for inventory purposes.'

# Logic below was put in this section rather than in core code as folks may
# want to change what the field does. This is a function that gets called
# when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
reg_text_label_1_logic() {
    REG_TEXT_LABEL_1_VALUE=$(defaults \
        read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_TEXT_LABEL_1")

    if [ "$REG_TEXT_LABEL_1_OPTIONAL" = true ] &&
        [ "$REG_TEXT_LABEL_1_VALUE" = "" ]; then

        echo "Status: $REG_TEXT_LABEL_1 was left empty. Skipping..." >>"$DEP_NOTIFY_LOG"

        echo "$DATE: $REG_TEXT_LABEL_1 was set to optional and was left empty. Skipping..." >>"$DEP_NOTIFY_DEBUG"
        /bin/sleep 5

    else
        echo "Status: $REGISTRATION_BEGIN_WORD $REG_TEXT_LABEL_1 $REGISTRATION_MIDDLE_WORD $REG_TEXT_LABEL_1_VALUE" >>"$DEP_NOTIFY_LOG"

        if [ "$TESTING_MODE" = true ]; then
            /bin/sleep 10

        else
            "$JAMF_BINARY" setComputerName -name "$REG_TEXT_LABEL_1_VALUE"
            /bin/sleep 5
        fi
    fi
}

# Second Text Field
###################################################################################################

# Text Field Label
REG_TEXT_LABEL_2="Asset Tag"

# Place Holder Text
REG_TEXT_LABEL_2_PLACEHOLDER="81926392"

# Optional flag for making the field an optional input for end user
REG_TEXT_LABEL_2_OPTIONAL="true" # Set variable to true or false

# Help Bubble for Input. If title left blank, this will not appear
REG_TEXT_LABEL_2_HELP_TITLE="Asset Tag Field"
REG_TEXT_LABEL_2_HELP_TEXT='This field is used to give an updated asset tag to our asset management system. If you do not know your asset tag number, please skip this field.'

# Logic below was put in this section rather than in core code as folks may
# want to change what the field does. This is a function that gets called
# when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
reg_text_label_2_logic() {
    REG_TEXT_LABEL_2_VALUE=$(defaults \
        read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_TEXT_LABEL_2")

    if [ "$REG_TEXT_LABEL_2_OPTIONAL" = true ] &&
        [ "$REG_TEXT_LABEL_2_VALUE" = "" ]; then

        echo "Status: $REG_TEXT_LABEL_2 was left empty. Skipping..." >>"$DEP_NOTIFY_LOG"

        echo "$DATE: $REG_TEXT_LABEL_2 was set to optional and was left empty. Skipping..." >>"$DEP_NOTIFY_DEBUG"
        /bin/sleep 5

    else
        echo "Status: $REGISTRATION_BEGIN_WORD $REG_TEXT_LABEL_2 $REGISTRATION_MIDDLE_WORD $REG_TEXT_LABEL_2_VALUE" >>"$DEP_NOTIFY_LOG"

        if [ "$TESTING_MODE" = true ]; then
            /bin/sleep 10

        else
            "$JAMF_BINARY" recon -assetTag "$REG_TEXT_LABEL_2_VALUE"
        fi
    fi
}

# Popup 1
###################################################################################################

# Label for the popup
REG_POPUP_LABEL_1="Building"

# Array of options for the user to select
REG_POPUP_LABEL_1_OPTIONS=(
    "Amsterdam"
    "Eau Claire"
    "Minneapolis"
)

# Help Bubble for Input. If title left blank, this will not appear
REG_POPUP_LABEL_1_HELP_TITLE="Building Dropdown Field"
REG_POPUP_LABEL_1_HELP_TEXT='Please choose the appropriate building for where you normally work. This is important for inventory purposes.'

# Logic below was put in this section rather than in core code as folks may
# want to change what the field does. This is a function that gets called
# when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
reg_popup_label_1_logic() {
    REG_POPUP_LABEL_1_VALUE=$(defaults \
        read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_1")

    echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_1 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_1_VALUE" >>"$DEP_NOTIFY_LOG"

    if [ "$TESTING_MODE" = true ]; then
        /bin/sleep 10

    else
        "$JAMF_BINARY" recon -building "$REG_POPUP_LABEL_1_VALUE"
    fi
}

# Popup 2
###################################################################################################
# Label for the popup
REG_POPUP_LABEL_2="Department"

# Array of options for the user to select
REG_POPUP_LABEL_2_OPTIONS=(
    "Customer Onboarding"
    "Professional Services"
    "Sales Engineering"
)

# Help Bubble for Input. If title left blank, this will not appear
REG_POPUP_LABEL_2_HELP_TITLE="Department Dropdown Field"
REG_POPUP_LABEL_2_HELP_TEXT='Please choose the appropriate department for where you normally work. This is important for inventory purposes.'

# Logic below was put in this section rather than in core code as folks may
# want to change what the field does. This is a function that gets called
# when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
reg_popup_label_2_logic() {

    REG_POPUP_LABEL_2_VALUE=$(defaults read \
        "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_2")

    echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_2 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_2_VALUE" >>"$DEP_NOTIFY_LOG"

    if [ "$TESTING_MODE" = true ]; then
        /bin/sleep 10

    else
        "$JAMF_BINARY" recon -department "$REG_POPUP_LABEL_2_VALUE"
    fi
}

# Popup 3 - Code is here but currently unused
###################################################################################################

# Label for the popup
REG_POPUP_LABEL_3=""

# Array of options for the user to select
REG_POPUP_LABEL_3_OPTIONS=(
    "Option 1"
    "Option 2"
    "Option 3"
)

# Help Bubble for Input. If title left blank, this will not appear
REG_POPUP_LABEL_3_HELP_TITLE="Dropdown 3 Field"
REG_POPUP_LABEL_3_HELP_TEXT='This dropdown is currently not in use. All code is here ready for you to use. It can also be hidden by removing the contents of the REG_POPUP_LABEL_3 variable.'

# Logic below was put in this section rather than in core code as folks may
# want to change what the field does. This is a function that gets called
# when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
reg_popup_label_3_logic() {

    REG_POPUP_LABEL_3_VALUE=$(defaults read \
        "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_3")

    echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_3 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_3_VALUE" >>"$DEP_NOTIFY_LOG"

    if [ "$TESTING_MODE" = true ]; then
        /bin/sleep 10

    else
        /bin.sleep 10
    fi
}

# Popup 4 - Code is here but currently unused
###################################################################################################
# Label for the popup
REG_POPUP_LABEL_4=""

# Array of options for the user to select
REG_POPUP_LABEL_4_OPTIONS=(
    "Option 1"
    "Option 2"
    "Option 3"
)

# Help Bubble for Input. If title left blank, this will not appear
REG_POPUP_LABEL_4_HELP_TITLE="Dropdown 4 Field"
REG_POPUP_LABEL_4_HELP_TEXT='This dropdown is currently not in use. All code is here ready for you to use. It can also be hidden by removing the contents of the REG_POPUP_LABEL_4 variable.'

# Logic below was put in this section rather than in core code as folks may
# want to change what the field does. This is a function that gets called
# when needed later on. BE VERY CAREFUL IN CHANGING THE FUNCTION!
reg_popup_label_4_logic() {

    REG_POPUP_LABEL_4_VALUE=$(defaults read \
        "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_4")

    echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_4 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_4_VALUE" >>"$DEP_NOTIFY_LOG"

    if [ "$TESTING_MODE" = true ]; then
        /bin/sleep 10

    else
        /bin/sleep 10
    fi
}

###################################################################################################
############################ VALIDATE THE JAMF BUILTIN VARIALBES ##################################
###################################################################################################

# Pulling from Policy parameters to allow true/false flags to be set. More info can be
# found on
# https://www.jamf.com/jamf-nation/articles/146/script-parameters
# These will override what is specified in the script above.

# Testing Mode
if [ "$4" != "" ]; then TESTING_MODE="$4"; fi
# Fullscreen Mode
if [ "$5" != "" ]; then FULLSCREEN="$5"; fi
# No Sleep / Caffeinate Mode
if [ "$6" != "" ]; then NO_SLEEP="$6"; fi
# Self Service Custom Branding
if [ "$7" != "" ]; then SELF_SERVICE_CUSTOM_BRANDING="$7"; fi
# Complete method dropdown or main screen
if [ "$8" != "" ]; then COMPLETE_METHOD_DROPDOWN_ALERT="$8"; fi
# EULA Mode
if [ "$9" != "" ]; then EULA_ENABLED="$9"; fi
# Registration Mode
if [ "${10}" != "" ]; then REGISTRATION_ENABLED="${10}"; fi
# Organization name check
if [ "${11}" != "" ]; then YOUR_ORG_NAME_HERE="${11}"; fi

###################################################################################################
################################# FUNCTIONS - DO NOT MODIFY #######################################
###################################################################################################

logging() {
    # Logging function
    LOG_FILE="$SCRIPT_NAME-$(date +"%Y-%m-%d").log"
    LOG_PATH="/Library/Logs/$LOG_FILE"
    DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
    printf "$DATE $1\n" >>$LOG_PATH
}

validate_true_false_flags() {
    # Validating true/false flags that are set in the Jamf console for this DEPNotify
    # script.

    if [ "$TESTING_MODE" != true ] && [ "$TESTING_MODE" != false ]; then
        /bin/echo "$DATE: Testing configuration not set properly. Currently set to $TESTING_MODE. Please update to true or false." >>"$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Testing configuration not set properly. Currently set to $TESTING_MODE. Please update to true or false."

        # Setting Quit Key set to command + control + x (Testing Mode Only)
        echo "Command: QuitKey: x" >>"$DEP_NOTIFY_LOG"
    fi

    if [ "$FULLSCREEN" != true ] && [ "$FULLSCREEN" != false ]; then
        /bin/echo "$DATE: Fullscreen configuration not set properly. Currently set to $FULLSCREEN. Please update to true or false." >>"$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Fullscreen configuration not set properly. Currently set to $FULLSCREEN. Please update to true or false."
        exit 1
    fi

    if [ "$NO_SLEEP" != true ] && [ "$NO_SLEEP" != false ]; then
        /bin/echo "$DATE: Sleep configuration not set properly. Currently set to $NO_SLEEP. Please update to true or false." >>"$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Sleep configuration not set properly. Currently set to $NO_SLEEP. Please update to true or false."
        exit 1
    fi

    if [ "$SELF_SERVICE_CUSTOM_BRANDING" != true ] &&
        [ "$SELF_SERVICE_CUSTOM_BRANDING" != false ]; then
        /bin/echo "$DATE: Self Service Custom Branding configuration not set properly. Currently set to $SELF_SERVICE_CUSTOM_BRANDING. Please update to true or false." >>"$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Self Service Custom Branding configuration not set properly. Currently set to $SELF_SERVICE_CUSTOM_BRANDING. Please update to true or false."
        exit 1
    fi

    if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" != true ] &&
        [ "$COMPLETE_METHOD_DROPDOWN_ALERT" != false ]; then
        /bin/echo "$DATE: Completion alert method not set properly. Currently set to $COMPLETE_METHOD_DROPDOWN_ALERT. Please update to true or false." >>"$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Completion alert method not set properly. Currently set to $COMPLETE_METHOD_DROPDOWN_ALERT. Please update to true or false."
        exit 1
    fi

    if [ "$EULA_ENABLED" != true ] && [ "$EULA_ENABLED" != false ]; then
        /bin/echo "$DATE: EULA configuration not set properly. Currently set to $EULA_ENABLED. Please update to true or false." >>"$DEP_NOTIFY_DEBUG"
        logging "DEBUG: EULA configuration not set properly. Currently set to $EULA_ENABLED. Please update to true or false."
        exit 1
    fi

    if [ "$REGISTRATION_ENABLED" != true ] &&
        [ "$REGISTRATION_ENABLED" != false ]; then

        /bin/echo "$DATE: Registration configuration not set properly. Currently set to $REGISTRATION_ENABLED. Please update to true or false." >>"$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Registration configuration not set properly. Currently set to $REGISTRATION_ENABLED. Please update to true or false."
        exit 1
    fi
}

pretty_pause() {
    # Adding nice text and a brief pause for prettiness
    echo "Status: $INITAL_START_STATUS" >>"$DEP_NOTIFY_LOG"
    /bin/sleep 5
}

get_setup_assistant_process() {
    # Wait for Setup Assisant to finish before contiuing
    # Start the setup process after Apple Setup Assistant completes

    PROCESS_NAME="Setup Assistant"

    logging "Checking to see if $PROCESS_NAME is running ..."

    # Initialize setup assistant variable
    SETUP_ASSISTANT_PROCESS=""

    while [[ $SETUP_ASSISTANT_PROCESS != "" ]]; do

        logging "$PROCESS_NAME still running ... PID: $SETUP_ASSISTANT_PROCESS"
        logging "Sleeping 1 second ..."
        /bin/sleep 1
        SETUP_ASSISTANT_PROCESS=$(/usr/bin/pgrep -l "$PROCESS_NAME")

    done

    logging "$PROCESS_NAME finished ... OK"

}

check_for_jamf_connect_login() {
    # check to ensure that jamf connect login is running before moving on
    # to the next step. If Jamf Connect Login is not installed attempt to
    # install it via Jamf Console policy.

    # Counter to keep track of counting
    COUNTER=0

    # Name of custom trigger for Jamf policy
    TRIGGER="jamf-connect-login"

    AUTHCHANGER_BINARY="/usr/local/bin/authchanger"

    logging "Making sure Jamf Connect Login installed ..."

    while [ ! -f "$AUTHCHANGER_BINARY" ]; do

        logging "Jamf Connect Login has not started yet ..."

        if [ ! -f "$AUTHCHANGER_BINARY" ] && [ "$COUNTER" -eq 10 ]; then
            # If Jamf Connect Login not installed, attempt to call the Jamf
            # console policy to install it.

            logging "Waited 10 seconds for Jamf Connect Login ..."
            logging "INSTALLER: Attemting to install Jamf Connect Login via Jamf policy ..."

            "$JAMF_BINARY" policy -event "$TRIGGER" |
                /usr/bin/sed -e "s/^/$DATE/" |
                /usr/bin/tee -a "$LOG_PATH" >/dev/null 2>&1

        fi
        logging "Waiting 1 seconds before checking again ..."
        /bin/sleep 1
        # Reset authchanger binary variable so that the while loop catches it.
        AUTHCHANGER_BINARY="/usr/local/bin/authchanger"

        # Increment the counter
        COUNTER=$((COUNTER + 1))

    done
    logging "Found Jamf Connect Login ..."
}

rosetta2_install() {
    # Install rosetta 2
    # Checks the architecture and installs Rosetta2 if arm64 is found.
    arch=$(/usr/bin/arch)
    if [ "$arch" == "arm64" ]; then
        logging "Running on Apple Silicon ..."
        logging "Installing Rosetta2 for compatibility with Intel-based apps ..."
        /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi
}

check_for_dep_notify_app() {
    # check to ensure that DEPNotify is isntalled before moving on to the next
    # step.
    # If it is not installed attempt to reinstall it using a policy in Jamf Pro.

    # Counter to keep track of Counting
    COUNTER=0

    # Name of custom trigger for Jamf policy
    TRIGGER="install-dep-notify"

    APP_NAME="DEPNotify.app"

    # Updated the ability to find an app using the builtin find binary.
    find_app=$(/usr/bin/find "/Applications" -maxdepth 2 -iname "$APP_NAME")

    # DN_APP="/Applications/Utilities/DEPNotify.app"
    logging "Making sure DEPNotify.app installed ..."

    while [[ ! -d $find_app ]]; do

        logging "DEPNotify has not been installed yet ..."

        if [ ! -d "$find_app" ] && [ "$COUNTER" -eq 5 ]; then
            # If Jamf Connect Login not installed, attempt to call the Jamf
            # console policy to install it.

            logging "Waited 5 seconds for DEPNotify ..."
            logging "INSTALLER: Attemting to install DEPNotify via Jamf policy ..."

            "$JAMF_BINARY" policy -event "$TRIGGER" |
                /usr/bin/sed -e "s/^/$DATE/" |
                /usr/bin/tee -a "$LOG_PATH" >/dev/null 2>&1
        fi

        logging "Waiting 1 seconds before checking again ..."
        /bin/sleep 1

        find_app=$(/usr/bin/find "/Applications" -iname "$APP_NAME" --maxdepth 2)
        COUNTER=$((COUNTER + 1))

    done
    logging "Found $APP_NAME ..."
}

get_current_user() {
    # Return the current user
    printf '%s' "show State:/Users/ConsoleUser" |
        /usr/sbin/scutil |
        /usr/bin/awk '/Name :/ && ! /loginwindow/ {print $3}'
}

get_current_user_uid() {
    # Check to see if the current console user uid is greater than 501
    # Loop until either the 501 or 502 user is found.

    # Get the current console user again
    cu="$1"

    logging "Getting current user UID ..."

    cu_uid=$(/usr/bin/dscl . -list /Users UniqueID | /usr/bin/grep "$cu" |
        /usr/bin/awk '{print $2}' |
        /usr/bin/sed -e 's/^[ \t]*//')

    while [[ $cu_uid -lt 501 ]]; do

        logging "Current user is not logged in ... WAITING"
        /bin/sleep 1

        # Get the current console user again
        cu=get_current_user

        cu_uid=$(/usr/bin/dscl . -list /Users UniqueID | /usr/bin/grep "$cu" |
            /usr/bin/awk '{print $2}' |
            /usr/bin/sed -e 's/^[ \t]*//')

        if [[ $cu_uid -lt 501 ]]; then
            logging "Current user: $cu with UID ..."
        fi
    done

    printf "%s\n" "$cu_uid"
}

get_finder_process() {
    # Check to see if the Finder is running yet. If it is, continue. Nice for
    # instances where the user is not setting up a username during the Setup
    # Assistant process.

    logging "Checking to see if the Finder process is running ..."
    echo "$DATE Checking to see if the Finder process is running ..."
    FINDER_PROCESS=$(/usr/bin/pgrep -l "Finder" 2>/dev/null)

    RESPONSE=$?

    logging "Finder PID: $FINDER_PROCESS"
    echo "Finder PID: $FINDER_PROCESS"

    while [[ $RESPONSE -ne 0 ]]; do

        logging "Finder PID not found. Assuming device is sitting \
            at the login window ..."
        echo "$DATE: Finder PID not found. Assuming device is sitting \
            at the login window ..."

        /bin/sleep 1

        FINDER_PROCESS=$(/usr/bin/pgrep -l "Finder" 2>/dev/null)
        RESPONSE=$?

        if [[ $FINDER_PROCESS != "" ]]; then
            logging "Finder PID: $FINDER_PROCESS"
            echo "$DATE: Finder PID: $FINDER_PROCESS"
        fi
    done
}

self_service_custom_branding() {
    # If SELF_SERVICE_CUSTOM_BRANDING is set to true. Loading the updated icon
    #
    # Args:
    #   $1 - the current logged-in user.

    cu="$1"

    # Self Service Process ID
    SELF_SERVICE_PID=""

    while [ -z "$SELF_SERVICE_PID" ]; do
        # Wait for Jamf Self Service to launch

        logging "Jamf Self Service has not opened yet ..."

        # Make sure that Jamf Self Service is present in the Applications directory
        # before attempting to launch the app.
        if [ -d "/Applications/$SELF_SERVICE_APP_NAME" ]; then
            logging "Attempting to open Jamf Self Service ..."

            # Seeing if this resolves LSOpenURLsWithRole() failed with error -10810
            /usr/bin/open -a "/Applications/$SELF_SERVICE_APP_NAME" --hide
        fi

        # Sleep for a second
        /bin/sleep 3

        # Get Self Service PID again
        SELF_SERVICE_PID=$(pgrep -l "$(echo "$SELF_SERVICE_APP_NAME" |
            /usr/bin/cut -d "." -f1)" |
            /usr/bin/cut -d " " -f1)

    done

    # Loop waiting on the branding image to properly show in the users library
    CUSTOM_BRANDING_PNG="/Users/$cu/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"

    counter=1

    while [ ! -f "$CUSTOM_BRANDING_PNG" ] && [ "$counter" -le 11 ]; do
        echo "$DATE: Waiting for branding image from Jamf Pro." >>"$DEP_NOTIFY_DEBUG"
        /bin/sleep 1
        counter=$((counter + 1))
    done

    # Setting Banner Image for DEP Notify to Self Service Custom Branding
    # Make sure that the brandingimage was found. If not
    if [ -f "$CUSTOM_BRANDING_PNG" ]; then
        #statements
        BANNER_IMAGE_PATH="$CUSTOM_BRANDING_PNG"

    else
        BANNER_IMAGE_PATH="$BANNER_IMAGE_PATH"
    fi

    # Setting custom image if specified
    if [ "$BANNER_IMAGE_PATH" != "" ]; then
        echo "Command: Image: $BANNER_IMAGE_PATH" >>"$DEP_NOTIFY_LOG"
    fi

    # Setting custom title if specified
    if [ "$BANNER_TITLE" != "" ]; then
        echo "Command: MainTitle: $BANNER_TITLE" >>"$DEP_NOTIFY_LOG"
    fi

    # Setting custom main text if specified
    if [ "$MAIN_TEXT" != "" ]; then
        echo "Command: MainText: $MAIN_TEXT" >>"$DEP_NOTIFY_LOG"
    fi

    # Closing Self Service
    SELF_SERVICE_PID=$(pgrep -l "$(/bin/echo "$SELF_SERVICE_APP_NAME" |
        /usr/bin/cut -d "." -f1)" |
        /usr/bin/cut -d " " -f1)

    echo "$DATE: Self Service custom branding icon has been loaded. Killing Self Service PID $SELF_SERVICE_PID." >>"$DEP_NOTIFY_DEBUG"

    logging "Killing Jamf Self Service app ..."
    kill "$SELF_SERVICE_PID"

    /bin/sleep 3
}

general_plist_config() {
    # General Plist Configuration
    cu="$1"

    # Calling function to set the INFO_PLIST_PATH
    info_plist_wrapper "$cu"

    # The plist information below
    DEP_NOTIFY_CONFIG_PLIST="/Users/$cu/Library/Preferences/menu.nomad.DEPNotify.plist"

    if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_CONFIG_PLIST" ]; then
        # If testing mode is on, this will remove some old configuration files
        rm "$DEP_NOTIFY_CONFIG_PLIST"
    fi

    if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_USER_INPUT_PLIST" ]; then
        rm "$DEP_NOTIFY_USER_INPUT_PLIST"
    fi

    # Setting default path to the plist which stores all the user completed info
    defaults \
        write "$DEP_NOTIFY_CONFIG_PLIST" \
        pathToPlistFile "$DEP_NOTIFY_USER_INPUT_PLIST"

    # Setting status text alignment
    defaults \
        write "$DEP_NOTIFY_CONFIG_PLIST" \
        statusTextAlignment "$STATUS_TEXT_ALIGN"

    if [ "$HELP_BUBBLE_TITLE" != "" ]; then
        # Setting help button

        defaults \
            write "$DEP_NOTIFY_CONFIG_PLIST" \
            helpBubble -array-add "$HELP_BUBBLE_TITLE"

        defaults \
            write "$DEP_NOTIFY_CONFIG_PLIST" \
            helpBubble -array-add "$HELP_BUBBLE_BODY"
    fi

    # Changing Ownership of the plist file
    chown "$cu":staff "$DEP_NOTIFY_CONFIG_PLIST"
    chmod 600 "$DEP_NOTIFY_CONFIG_PLIST"
}

launch_dep_notify_app() {
    # Opening the DEPNotiy app after initial configuration
    cu="$1"

    # Updated for Big Sur due to macOS yelling before launching DEPNotify and asking
    # the end-user if they would like to open the app due to the app being downloaded
    # from the internet at some point.
    logging "Removing the quarantine bit from the DEPNotify app ..."
    sudo xattr -r -d com.apple.quarantine /Applications/Utilities/DEPNotify.app

    logging "Opening DEPNotify app ..."

    if [ "$FULLSCREEN" = true ]; then
        sudo -u "$cu" /usr/bin/open -a \
            "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG" -fullScreen

    elif [ "$FULLSCREEN" = false ]; then
        sudo -u "$cu" /usr/bin/open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"

    fi
}

caffeinate_this() {
    # Using Caffeinate binary to keep the computer awake if enabled
    if [ "$NO_SLEEP" = true ]; then
        logging "Caffeinating DEP Notify process. Process ID: $DEP_NOTIFY_PROCESS\n" >>"$DEP_NOTIFY_DEBUG"
        caffeinate -disu -w "$DEP_NOTIFY_PROCESS" &
    fi
}

get_dep_notify_process() {
    # Grabbing the DEP Notify Process ID for use later
    DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)

    until [ "$DEP_NOTIFY_PROCESS" != "" ]; do

        /bin/echo "$DATE: Waiting for DEPNotify to start to gather the process ID." >>"$DEP_NOTIFY_DEBUG"
        /bin/sleep 1
        DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)

    done

    /bin/echo "$DEP_NOTIFY_PROCESS"

    caffeinate_this "$DEP_NOTIFY_PROCESS"
}

status_bar_gen() {
    # SETTING THE STATUS BAR
    # Counter is for making the determinate look nice. Starts at one and adds
    # more based on EULA, register, or other options.
    ADDITIONAL_OPTIONS_COUNTER=1

    if [ "$EULA_ENABLED" = true ]; then ((ADDITIONAL_OPTIONS_COUNTER++)); fi

    if [ "$REGISTRATION_ENABLED" = true ]; then
        ((ADDITIONAL_OPTIONS_COUNTER++))

        if [ "$REG_TEXT_LABEL_1" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++))
        fi

        if [ "$REG_TEXT_LABEL_2" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++))
        fi

        if [ "$REG_POPUP_LABEL_1" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++))
        fi

        if [ "$REG_POPUP_LABEL_2" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++))
        fi

        if [ "$REG_POPUP_LABEL_3" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++))
        fi

        if [ "$REG_POPUP_LABEL_4" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++))
        fi

    fi

    # Increment status counter for submitting Jamf inventory at end of DEPNotify
    ADDITIONAL_OPTIONS_COUNTER=$((ADDITIONAL_OPTIONS_COUNTER++))

    # Checking policy array and adding the count from the additional options
    # above.
    ARRAY_LENGTH="$((${#POLICY_ARRAY[@]} + ADDITIONAL_OPTIONS_COUNTER))"
    echo "Command: Determinate: $ARRAY_LENGTH" >>"$DEP_NOTIFY_LOG"
}

eula_configuration() {
    # EULA Configuration
    cu="$1"
    DEP_NOTIFY_EULA_DONE="/var/tmp/com.depnotify.agreement.done"

    # If testing mode is on, this will remove EULA specific configuration
    # files
    if [ "$TESTING_MODE" = true ] &&
        [ -f "$DEP_NOTIFY_EULA_DONE" ]; then

        rm "$DEP_NOTIFY_EULA_DONE"
    fi

    # Writing title, subtitle, and EULA txt location to plist
    defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
        EULAMainTitle "$EULA_MAIN_TITLE"
    defaults write "$DEP_NOTIFY_CONFIG_PLIST" EULASubTitle "$EULA_SUBTITLE"
    defaults write "$DEP_NOTIFY_CONFIG_PLIST" pathToEULA "$EULA_FILE_PATH"

    # Setting ownership of EULA file
    chown "$cu:staff" "$EULA_FILE_PATH"
    chmod 444 "$EULA_FILE_PATH"
}

eula_logic() {
    # EULA Window Display Logic
    /bin/echo "Status: $EULA_STATUS" >>"$DEP_NOTIFY_LOG"
    /bin/echo "Command: ContinueButtonEULA: $EULA_BUTTON" >>"$DEP_NOTIFY_LOG"

    while [ ! -f "$DEP_NOTIFY_EULA_DONE" ]; do
        /bin/echo "$DATE: Waiting for user to accept EULA." >>"$DEP_NOTIFY_DEBUG"
        logging "INFO: Waiting for user to accept EULA."
        /bin/sleep 1
    done
}

configure_registration_plist() {
    # Registration Plist Configuration
    if [ "$REGISTRATION_ENABLED" = true ]; then
        DEP_NOTIFY_REGISTER_DONE="/var/tmp/com.depnotify.registration.done"

        # If testing mode is on, this will remove registration specific
        # configuration files
        if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_REGISTER_DONE" ]; then

            rm "$DEP_NOTIFY_REGISTER_DONE"
        fi

        # Main Window Text Configuration
        "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
            registrationMainTitle "$REGISTRATION_TITLE"
        "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
            registrationButtonLabel "$REGISTRATION_BUTTON"
        "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
            registrationPicturePath "$BANNER_IMAGE_PATH"

        # First Text Box Configuration
        if [ "$REG_TEXT_LABEL_1" != "" ]; then
            "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField1Label "$REG_TEXT_LABEL_1"
            "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField1Placeholder "$REG_TEXT_LABEL_1_PLACEHOLDER"
            "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField1IsOptional "$REG_TEXT_LABEL_1_OPTIONAL"

            # Code for showing the help box if configured
            if [ "$REG_TEXT_LABEL_1_HELP_TITLE" != "" ]; then
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    textField1Bubble -array-add "$REG_TEXT_LABEL_1_HELP_TITLE"
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    textField1Bubble -array-add "$REG_TEXT_LABEL_1_HELP_TEXT"
            fi
        fi

        # Second Text Box Configuration
        if [ "$REG_TEXT_LABEL_2" != "" ]; then

            "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField2Label "$REG_TEXT_LABEL_2"
            "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField2Placeholder "$REG_TEXT_LABEL_2_PLACEHOLDER"
            "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField2IsOptional "$REG_TEXT_LABEL_2_OPTIONAL"

            # Code for showing the help box if configured
            if [ "$REG_TEXT_LABEL_2_HELP_TITLE" != "" ]; then

                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    textField2Bubble -array-add "$REG_TEXT_LABEL_2_HELP_TITLE"
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    textField2Bubble -array-add "$REG_TEXT_LABEL_2_HELP_TEXT"

            fi
        fi

        # Popup 1
        if [ "$REG_POPUP_LABEL_1" != "" ]; then

            "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                popupButton1Label "$REG_POPUP_LABEL_1"

            # Code for showing the help box if configured
            if [ "$REG_POPUP_LABEL_1_HELP_TITLE" != "" ]; then

                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu1Bubble -array-add "$REG_POPUP_LABEL_1_HELP_TITLE"
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu1Bubble -array-add "$REG_POPUP_LABEL_1_HELP_TEXT"

            fi

            # Code for adding the items from the array above into the plist
            for REG_POPUP_LABEL_1_OPTION in "${REG_POPUP_LABEL_1_OPTIONS[@]}"; do
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupButton1Content -array-add "$REG_POPUP_LABEL_1_OPTION"
            done
        fi

        # Popup 2
        if [ "$REG_POPUP_LABEL_2" != "" ]; then

            "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                popupButton2Label "$REG_POPUP_LABEL_2"

            # Code for showing the help box if configured
            if [ "$REG_POPUP_LABEL_2_HELP_TITLE" != "" ]; then

                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu2Bubble -array-add "$REG_POPUP_LABEL_2_HELP_TITLE"
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu2Bubble -array-add "$REG_POPUP_LABEL_2_HELP_TEXT"

            fi

            # Code for adding the items from the array above into the plist
            for REG_POPUP_LABEL_2_OPTION in "${REG_POPUP_LABEL_2_OPTIONS[@]}"; do
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupButton2Content -array-add "$REG_POPUP_LABEL_2_OPTION"
            done
        fi

        # Popup 3
        if [ "$REG_POPUP_LABEL_3" != "" ]; then

            "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                popupButton3Label "$REG_POPUP_LABEL_3"

            # Code for showing the help box if configured
            if [ "$REG_POPUP_LABEL_3_HELP_TITLE" != "" ]; then

                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu3Bubble -array-add "$REG_POPUP_LABEL_3_HELP_TITLE"
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu3Bubble -array-add "$REG_POPUP_LABEL_3_HELP_TEXT"

            fi

            # Code for adding the items from the array above into the plist
            for REG_POPUP_LABEL_3_OPTION in "${REG_POPUP_LABEL_3_OPTIONS[@]}"; do
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupButton3Content -array-add "$REG_POPUP_LABEL_3_OPTION"
            done
        fi

        # Popup 4
        if [ "$REG_POPUP_LABEL_4" != "" ]; then

            "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                popupButton4Label "$REG_POPUP_LABEL_4"

            # Code for showing the help box if configured
            if [ "$REG_POPUP_LABEL_4_HELP_TITLE" != "" ]; then

                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu4Bubble -array-add "$REG_POPUP_LABEL_4_HELP_TITLE"
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu4Bubble -array-add "$REG_POPUP_LABEL_4_HELP_TEXT"

            fi
            # Code for adding the items from the array above into the plist
            for REG_POPUP_LABEL_4_OPTION in "${REG_POPUP_LABEL_4_OPTIONS[@]}"; do
                "$DEFAULTS" write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupButton4Content -array-add "$REG_POPUP_LABEL_4_OPTION"
            done
        fi
    fi
}

registration_window_display_logic() {

    configure_registration_plist

    # Registration Window Display Logic
    echo "Status: $REGISTRATION_STATUS" >>"$DEP_NOTIFY_LOG"
    echo "Command: ContinueButtonRegister: $REGISTRATION_BUTTON" >>"$DEP_NOTIFY_LOG"

    while [ ! -f "$DEP_NOTIFY_REGISTER_DONE" ]; do
        echo "$DATE: Waiting for user to complete registration." >>"$DEP_NOTIFY_DEBUG"
        /bin/sleep 1
    done

    # Running Logic For Each Registration Box
    if [ "$REG_TEXT_LABEL_1" != "" ]; then reg_text_label_1_logic; fi
    if [ "$REG_TEXT_LABEL_2" != "" ]; then reg_text_label_2_logic; fi
    if [ "$REG_POPUP_LABEL_1" != "" ]; then reg_popup_label_1_logic; fi
    if [ "$REG_POPUP_LABEL_2" != "" ]; then reg_popup_label_2_logic; fi
    if [ "$REG_POPUP_LABEL_3" != "" ]; then reg_popup_label_3_logic; fi
    if [ "$REG_POPUP_LABEL_4" != "" ]; then reg_popup_label_4_logic; fi
}

install_policies() {
    # Install policies by looping through the policy array defined above.

    logging "Preparing to install Jamf application policies."

    for policy in "${POLICY_ARRAY[@]}"; do
        # Loop through the policy array and install each policy

        if [[ $TESTING_MODE == true ]]; then
            logging "Test mode enabled ... INFO"
            sleep 10

        elif [[ $TESTING_MODE == false ]]; then
            # Install the given policy

            # psuedo local variables
            policy_status=$(/bin/echo "$policy" | cut -d ',' -f1)
            policy_name=$(/bin/echo "$policy" | cut -d ',' -f2)

            logging "Calling $policy_name policy."
            /bin/echo "Status: $policy_status" >>"$DEP_NOTIFY_LOG"

            "$JAMF_BINARY" policy -event "$policy_name" |
                /usr/bin/sed -e "s/^/$DATE/" |
                /usr/bin/tee -a "$LOG_PATH" >/dev/null 2>&1
        fi
    done
}

install_policies_with_icon() {
    # Install policies and display app icons.
    #
    # This function installs each policy in the policy array and applies the
    # corrosponding application icon in the app icon array to the Image in
    # DEPNotify.
    logging "Preparing to install Jamf application policies."

    for policy in "${POLICY_ARRAY[@]}"; do
        # Loop through the policy array and install each policy

        # psuedo local variables
        policy_status=$(/bin/echo "$policy" | cut -d ',' -f1)
        policy_name=$(/bin/echo "$policy" | cut -d ',' -f2)

        for icon in "${APP_ICON_ARRAY[@]}"; do
            # Loop through the app icon array and change the Image

            app_icon_name=$(/bin/echo "$icon" | cut -d ',' -f1)
            app_icon_path=$(/bin/echo "$icon" | cut -d ',' -f2)

            if [[ $TESTING_MODE == true ]]; then
                logging "Test mode enabled ... INFO"
                sleep 10

            elif [[ $TESTING_MODE == false ]]; then
                # Install the given policy

                # Check to see if the policy status string contains the app icon name.
                if printf "%s" "$policy_status" | /usr/bin/grep -q -i "$app_icon_name"; then

                    logging "Calling $policy_name policy."
                    /bin/echo "Status: $policy_status" >>"$DEP_NOTIFY_LOG"
                    logging "Changing Image to $app_icon_path"
                    /bin/echo "Command: Image: $app_icon_path" >>"$DEP_NOTIFY_LOG"

                    "$JAMF_BINARY" policy -event "$policy_name" |
                        /usr/bin/sed -e "s/^/$DATE/" |
                        /usr/bin/tee -a "$LOG_PATH" >/dev/null 2>&1

                    break
                fi
            fi
        done
    done
}

set_computer_name() {
    # Set the computer name

    # Leave this blank if a prefix is not desired
    prefix="$PREFIX"

    # Store device serial number
    serial_number=$(/usr/sbin/system_profiler SPHardwareDataType |
        /usr/bin/awk '/Serial\ Number\ \(system\)/ {print $NF}')

    name="$prefix$serial_number"

    logging "Setting computer name to: $name"

    # Set device name using scutil
    /usr/sbin/scutil --set ComputerName "$name"
    /usr/sbin/scutil --set LocalHostName "$name"
    /usr/sbin/scutil --set HostName "$name"

    # Set device name using jamf binary to make sure of the correct name
    "$JAMF" setComputerName -name "$name"
    ret="$?"

    if [ "$ret" -ne 0 ]; then
        # Naming failed
        printf "Failed to set computer name with jamf name command ...\n"
        RETURN_CODE="$ret"
    fi

}

update_username_in_jamf_cloud() {
    # Ensure that the username field is populated under the device inventory
    # record.
    logging "Calling Jamf policy to update username inventory record."
    "$JAMF_BINARY" policy -event update-username
}

directory_binding() {
    # Calls Jamf policy to bind the Mac to AD.
    logging "Calling Jamf policy to bind Mac to AD."
    "$JAMF_BINARY" policy -event directory-binding
}

enable_location_services() {
    # Enable location services
    logging "Enableing Location services ..."
    sudo -u _locationd /usr/bin/defaults \
        -currentHost write com.apple.locationd LocationServicesEnabled -int 1
}

enable_automatic_timezone() {
    # configure automatic timezone
    # This configuration will require a reboot.

    logging "Activating automatic time zone ..."

    /usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto \
        Active -bool YES

    /usr/bin/defaults write \
        /private/var/db/timed/Library/Preferences/com.apple.timed.plist \
        TMAutomaticTimeOnlyEnabled -bool YES

    /usr/bin/defaults write \
        /private/var/db/timed/Library/Preferences/com.apple.timed.plist \
        TMAutomaticTimeZoneEnabled -bool YES

    /usr/sbin/systemsetup -setusingnetworktime on
    /usr/sbin/systemsetup -gettimezone
    /usr/sbin/systemsetup -getnetworktimeserver
}

lock_login_keychain() {
    # Lock Keychain while Sleep
    logging "Keychain: Lock keychain while device is sleeping."
    sudo security set-keychain-settings -l
}

checkin_to_jamf() {
    # Force the Mac to checkin with Jamf and submit its enventory.
    logging "Submitting device inventory to Jamf ..."
    /bin/echo "Status: Submitting device inventory to Jamf" >>"$DEP_NOTIFY_LOG"
    "$JAMF_BINARY" recon
}

create_stub_file() {
    # Create a stub file
    #
    # Set the name of the stub file to your liking or pass the name of a stub
    # to this function as the $1 builtin.
    stub_file_path="/Users/Shared/$1"
    logging "Laying down $STUB_FILE_NAME stub file"
    /usr/bin/touch "$stub_file_path"
}

install_sap_privileges_app() {
    # Call jamf policy to install SAP Privileges App
    "$JAMF_BINARY" policy -event sap-privileges-installer |
        /usr/bin/sed -e "s/^/$DATE/" |
        /usr/bin/tee -a "$LOG_PATH" >/dev/null 2>&1
}

filevault_configuration_status() {
    # Check to see if FileVault Deferred enablement is active

    /bin/echo "Status: Checking FileVault" >>"$DEP_NOTIFY_LOG"

    FV_DEFERRED_STATUS=$($FDESETUP_BINARY status |
        /usr/bin/grep "Deferred" |
        /usr/bin/cut -d ' ' -f6)

    # Logic to log user out if FileVault is detected. Otherwise, app will close.
    if [ "$FV_DEFERRED_STATUS" = "active" ] && [ "$TESTING_MODE" = true ]; then
        if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
            /bin/echo "Command: Quit: This is typically where your FV_LOGOUT_TEXT would be displayed. However, TESTING_MODE is set to true and FileVault deferred status is on." >>"$DEP_NOTIFY_LOG"
        else
            /bin/echo "Command: MainText: TESTING_MODE is set to true and FileVault deferred status is on. Button effect is quit instead of logout. \n \n $FV_COMPLETE_MAIN_TEXT" >>"$DEP_NOTIFY_LOG"
            /bin/echo "Command: ContinueButton: Test $FV_COMPLETE_BUTTON_TEXT" >>"$DEP_NOTIFY_LOG"
        fi

    elif [ "$FV_DEFERRED_STATUS" = "active" ] &&
        [ "$TESTING_MODE" = false ]; then

        if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
            /bin/echo "Command: Logout: $FV_ALERT_TEXT" >>"$DEP_NOTIFY_LOG"

        else
            /bin/echo "Command: MainText: $FV_COMPLETE_MAIN_TEXT" >>"$DEP_NOTIFY_LOG"
            /bin/echo "Command: ContinueButtonLogout: $FV_COMPLETE_BUTTON_TEXT" >>"$DEP_NOTIFY_LOG"
        fi

    else
        if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
            /bin/echo "Command: Quit: $COMPLETE_ALERT_TEXT" >>"$DEP_NOTIFY_LOG"
        else
            /bin/echo "Command: MainText: $COMPLETE_MAIN_TEXT" >>"$DEP_NOTIFY_LOG"
            /bin/echo "Command: ContinueButton: $COMPLETE_BUTTON_TEXT" >>"$DEP_NOTIFY_LOG"
        fi
    fi
}

return_filevault_status() {
    # Return the status of FileVault
    # Returns active or disabled.
    fv_deferred_status=$($FDESETUP_BINARY status |
        /usr/bin/grep "Deferred" |
        /usr/bin/cut -d ' ' -f6)

    if [ "$fv_deferred_status" = "active" ]; then
        # Return active status.
        fv_deferred_status="active"
    else
        fv_deferred_status="disabled"
    fi
    printf "%s\n" "$fv_deferred_status"
}

dep_notify_cleanup() {
    #   Removes the files and directories left behind by DEPNotify once
    #   the device setup is complete. Then, removes the DEPNotify application its
    #   self.
    #
    #   NOTE: The package used to install DEPNotify will not need to be
    #         manually removed because Packages.app will build a tmp directory to
    #         install the pacakge from and will unmount it once the insall is complete.
    #
    # Default DEPNotify file locations
    DEPNOTIFY_APP="/Applications/Utilities/DEPNotify.app"
    DEPNOTIFY_NEW_PLIST="/Users/username/Library/Preferences/menu.nomad.DEPNotify.plist"
    DEPNOTIFY_TMP="/var/tmp"
    DEPNOTIFY_LOG="$DEPNOTIFY_TMP/depnotify.log"
    DEPNOTIFY_DEBUG="$DEPNOTIFY_TMP/depnotifyDebug.log"
    DEPNOTIFY_DONE="$DEPNOTIFY_TMP/com.depnotify.provisioning.done"
    DEPNOTIFY_LOGOUT="$DEPNOTIFY_TMP/com.depnotify.provisioning.logout"
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

    wait_for_completion() {
        # Wait for the user to press the Logout button.
        while [ ! -f "$DEPNOTIFY_LOGOUT" ] || [ ! -f "$DEPNOTIFY_DONE" ]; do
            logging "Cleanup: Waiting for Completion file ..."
            logging "Cleanup: The user has not closed the DEPNotify window ..."
            logging "Cleanup: Waiting 1 second ..."
            /bin/sleep 1
            if [ -f "$DEPNOTIFY_DONE" ]; then
                logging "Cleanup: Found $DEPNOTIFY_DONE"
                break
            fi

            if [ -f "$DEPNOTIFY_LOGOUT" ]; then
                logging "Cleanup: Found $DEPNOTIFY_LOGOUT"
                break
            fi
        done
    }

    remove_depnotify_daemon() {
        # Remove the LaunchDaemon
        # This will prevent DEPNotify from launching again after a reboot.
        if [ -e "$DEPNOTIFY_DAEMON" ]; then
            # The LaunchDaemon file exists
            logging "DEPNotify Cleanup: Removing DEPNotify LaunchDaemon"
            /bin/rm -R "$DEPNOTIFY_DAEMON"

        else
            logging "DEPNotify Cleanup: Daemon not installed."
        fi
    }

    remove_depnotify_collateral() {
        # Remove DEPNotify files
        # Loop through and remove all files accociated with DEPNotify.
        for thing in \
            ${DEPNOTIFY_APP} \
            ${DEPNOTIFY_NEW_PLIST} \
            ${DEPNOTIFY_LOG} \
            ${DEPNOTIFY_DEBUG} \
            ${DEPNOTIFY_RESTART} \
            ${DEPNOTIFY_AGR_DONE} \
            ${DEPNOTIFY_REG_DONE} \
            ${DEPNOTIFY_EULA_TXT_FILE} \
            ${DEPNOTIFY_ENROLLMENT_STARTER} \
            ${DEPNOTIFY_INST_ERR} \
            ${DEPNOTIFY_INST_OUT} \
            ${DEPNOTIFY_DONE} \
            ${DEPNOTIFY_LOGOUT}; do

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

    logging "-- Start DEPNotify cleanup --"

    # Call functions
    wait_for_completion
    remove_depnotify_daemon
    remove_depnotify_collateral

    logging "-- End DEPNotify Cleanup --"
}

###################################################################################################
################################ MAIN LOGIC - DO NOT MODIFY #######################################
###################################################################################################

main() {
    # Main function

    SCRIPT_NAME=$(/usr/bin/basename "$0" | /usr/bin/awk -F "." '{print $1}')

    # Binaries
    DEFAULTS="/usr/bin/defaults"
    DEP_NOTIFY_APP="/Applications/Utilities/DEPNotify.app"
    FDESETUP_BINARY="/usr/bin/fdesetup"
    JAMF_BINARY="/usr/local/bin/jamf"

    # Log files
    LOG_FILE="enrollment-$(date +"%Y-%m-%d").log"
    LOG_PATH="/Library/Logs/$LOG_FILE"
    DATE=$(date +"[%b %d, %Y %Z %T INFO]")
    DEP_NOTIFY_LOG="/var/tmp/depnotify.log"
    DEP_NOTIFY_DEBUG="/var/tmp/depnotifyDebug.log"
    DEP_NOTIFY_DONE="/var/tmp/com.depnotify.provisioning.done"

    # Make sure that true/false flags are set properly in Jamf and in this script.
    validate_true_false_flags

    logging ""
    logging "--- BEGIN DEVICE ENROLLMENT LOG ---"
    logging ""
    logging "$SCRIPT_NAME Version $VERSION"
    logging ""

    get_setup_assistant_process

    # See if Jamf Connect is being installed as a part of this deployment.
    if [ "$JAMF_CONNECT_ENABLED" = true ]; then
        # We are using Jamf Connect
        # If this is not enabled then there is no reason to run the function.
        check_for_jamf_connect_login
    else
        logging "Not using Jamf Connect ..."
    fi

    # Check to see if we are running on an Arm based Mac.
    logging "Checking to see if we are running on Apple Silicon"
    rosetta2_install

    check_for_dep_notify_app

    # Check to see if we are in the user space yet.
    get_finder_process

    # Grab the current logged-in user and the uid
    current_user="$(get_current_user)"
    current_user_uid="$(get_current_user_uid $current_user)"

    logging "Current User: $current_user"
    logging "Current User UID: $current_user_uid"

    # Adding Check and Warning if Testing Mode is off and BOM files exist
    if [[ (-f $DEP_NOTIFY_LOG || -f $DEP_NOTIFY_DONE) && \
        $TESTING_MODE == false ]]; then

        echo "$DATE: TESTING_MODE set to false but config files were found in /var/tmp. Letting user know and exiting." >>"$DEP_NOTIFY_DEBUG"

        mv "$DEP_NOTIFY_LOG" "/var/tmp/depnotify_old.log"

        echo "Command: MainTitle: $ERROR_BANNER_TITLE" >>"$DEP_NOTIFY_LOG"
        echo "Command: MainText: $ERROR_MAIN_TEXT" >>"$DEP_NOTIFY_LOG"
        echo "Status: $ERROR_STATUS" >>"$DEP_NOTIFY_LOG"

        sudo -u "$current_user" open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"
        sudo -u "$current_user" open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"
        sudo -u "$current_user" open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"

        /bin/sleep 5

        exit 1
    fi

    # See if the Self Service branding is enabled.
    if [ "$SELF_SERVICE_CUSTOM_BRANDING" = true ]; then
        # If this is not enabled then there is no reason to run the function.
        self_service_custom_branding "$current_user"
    fi

    general_plist_config "$current_user"
    launch_dep_notify_app "$current_user"
    get_dep_notify_process

    # Adding an alert prompt to let admins know that the script is in testing
    # mode
    if [ "$TESTING_MODE" = true ]; then
        /bin/echo "Command: Alert: DEP Notify is in TESTING_MODE. Script will not run Policies or other commands that make change to this computer." >>"$DEP_NOTIFY_LOG"
    fi

    pretty_pause
    status_bar_gen

    if [ "$EULA_ENABLED" = true ]; then
        # If this is not enabled then there is no reason to run the function.
        eula_configuration "$current_user"
        eula_logic
    fi

    if [ "$REGISTRATION_ENABLED" = true ]; then
        # If this is not enabled then there is no reason to run the function.
        registration_window_display_logic
    fi

    # Policy installation
    if [ -n "$APP_ICON_ARRAY" ]; then
        # Check to see if there is an anything in the first position of the array. If
        # so we want to install the policies and change the app icon in the DEPNotify
        # windwow as well.
        install_policies_with_icon
    else
        # Install the policies without updating the icon in DEPNotify
        install_policies
    fi

    # Check to see if we are setting the computer name in this script.
    # See beginning of script for more information
    if [ "$COMPUTER_NAME_ENABLE" = true ]; then
        set_computer_name
    fi

    # Check to see if we are updating the assigned user in the computer inventory
    # record.
    if [ "$UPDATE_USERNAME_INVENTORY_RECORD_ENABLED" = true ]; then
        # If this is not enabled then there is no reason to run the function.
        update_username_in_jamf_cloud
    fi

    # Check to see if we are binding this Mac to and Active Directory domain via Jamf
    # policy.
    if [ "$DIRECTORY_BINDING_ENABLED" = true ]; then
        # If the seconfdary option DIRECTORY_BINDING_ENABLED is set to true.
        # Call a Jamf Pro policy to bind the Mac to AD during the enrollment
        # process.
        directory_binding
    fi

    enable_location_services
    enable_automatic_timezone
    lock_login_keychain

    filevault_configuration_status

    # Check to see if we are installing SAP Privileges as a part of the deployment.
    if [ "$SAP_PRIVILEGES_APP_ENABLED" = true ]; then
        # Make sure that FileVault is enabled before installing Privileges
        logging "SAP Privileges app is being used ..."

        filevault_status="$(return_filevault_status)"
        logging "FileVault status is: $filevault_status"

        if [ "$filevault_status" = "active" ]; then
            install_sap_privileges_app
        else
            install_sap_privileges_app
        fi
    fi

    checkin_to_jamf

    # Nice completion text
    echo "Status: $INSTALL_COMPLETE_TEXT" >>"$DEP_NOTIFY_LOG"

    dep_notify_cleanup

    # Check to see if a restart policy is set for this deployment.
    if [ "$RESTART_ENABLED" = true ]; then
        # If the ENROLLMENT_COMPLETE_REBOOT setting is set to true at the top of
        # this script we will promt the user to restart.
        logging "Getting ready to restart ..."
        /bin/echo "Command: Restart: We need to restart to complete the setup ..."
    fi

    logging ""
    logging "--- END DEVICE ENROLLMENT LOG ---"
    logging ""

}

# Call the main funcion
main

exit 0
