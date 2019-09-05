#!/usr/bin/env bash

# GitHub: @captam3rica
VERSION=1.0.3

###############################################################################
#
# This Insight Software is provided by Insight on an "AS IS" basis.
#
# INSIGHT MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
# THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE, REGARDING THE INSIGHT SOFTWARE OR ITS USE AND
# OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
#
# IN NO EVENT SHALL INSIGHT BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
# OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
# MODIFICATION AND/OR DISTRIBUTION OF THE INSIGHT SOFTWARE, HOWEVER CAUSED
# AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
# STRICT LIABILITY OR OTHERWISE, EVEN IF INSIGHT HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
###############################################################################
#
#   DESCRIPTION
#
#       This script is designed to make the implementation of DEPNotify very
#       easy with limited scripting knowledge. The section below has variables
#       that may be modified to customize the end-user experience. DO NOT
#       modify things in or below the CORE LOGIC area unless major testing and
#       validation is performed.
#
###############################################################################
#
#   CHANGELOG
#
#   Version - v1.0.0
#
#       - Modified from Jamf's DEPNotify-Starter script found here
#         https://github.com/jamf/DEPNotify-Starter
#       - Initial release
#       - Converted a number of the features in this script to functions.
#       - A secondary log file is generated at /Library/Logs
#
#   Version - v1.0.1
#
#       - Added check within the check_jamf_connect_login function to attempt
#         an installation of Jamf Connect Login if after 10 seconds the Jamf
#         Connect Login binary is not found.
#
#   Version - v1.0.2
#
#       - Moved the policy array section closer to the top of the script to
#         make it a little easier to modify later.
#
#   Version - v1.0.3
#
#       - Added functionality to rename Mac
#       - Added function that calls jamf recon
#       - Added DEPNotiy status for FaultVault check and submitting device
#         inventory to Jamf console.
#
###############################################################################

#####################################################################captam3rica
# TESTING MODE
###############################################################################
# The TESTING_MODE flag will enable the following things to change:
#   - Auto removal of BOM files to reduce errors
#   - Sleep commands instead of policies or other changes being called
#   - Quit Key set to command + control + x

TESTING_MODE=true # Can be set to true or false


###############################################################################
# POLICY ARRAY VARIABLE TO MODIFY
###############################################################################
# The policy array must be formatted "Progress Bar text,customTrigger". These
# will be run in order as they appear below.
POLICY_ARRAY=(
    # "Installing Google Chrome Browser,google-chrome"
    "Installing Jamf Connect,jamf-connect-verify"
    "Installing Tools,msft-autoupdate-tool"
    "Installing Microsoft Company Portal,msft-company-portal"
    "Installing Microsoft OneDrive,msft-onedrive"
    "Installing Microsoft OneDrive KMF,macos-onedrive-kfm"
    "Installing Microsoft Outlook,msft-outlook"
    "Installing Bomgar Remote Assistant,bomgar-agent"
    "Installing Cisco VPN Client,cisco-anyconnect"
    "Installing Additional Tools,cisco-amp-agent"
    "Configurating Final Settings,disable-airdrop"
    "Configurating Final Settings,Your_Org_Name_Here-wallpaper"
)


################################################################################
# GENERAL APPEARANCE
################################################################################

# Flag the app to open fullscreen or as a window
FULLSCREEN=true # Set variable to true or false

# Banner image can be 600px wide by 100px high. Images will be scaled to fit
# If this variable is left blank, the generic image will appear. If using
# custom Self Service branding, please see the Customized Self Service Branding
# area below.

BANNER_IMAGE_PATH="/Applications/Self Service.app/Contents/Resources/AppIcon.icns"

# Main heading that will be displayed under the image If this variable is left
# blank, the generic banner will appear

BANNER_TITLE="Welcome to Your_Org_Name_Here Inc."

# Paragraph text that will display under the main heading. For a new line,
# use \n If this variable is left blank, the generic message will appear.
# Leave single quotes below as double quotes will break the new lines.

MAIN_TEXT='Thanks for choosing a Mac at Your_Org_Name_Here! We want you to have a few applications and settings configured before you get started with your new Mac. This process should take 10 to 20 minutes to complete. \n \n If you need additional software or help, please visit the Self Service app in your Applications folder or on your Dock.'

# Initial Start Status text that shows as things are firing up
INITAL_START_STATUS="Initial Configuration Starting..."

# Text that will display in the progress bar
INSTALL_COMPLETE_TEXT="Configuration Complete!"

# Complete messaging to the end user can ether be a button at the bottom of the
# app with a modification to the main window text or a dropdown alert box.
# Default value set to false and will use buttons instead of dropdown messages.

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


################################################################################
# PLIST CONFIGURATION
################################################################################
# The menu.depnotify.plist contains more and more things that configure the
# DEPNotify app. You may want to save the file for purposes like verifying EULA
# acceptance or validating other options.

# Plist Save Location
# This wrapper allows variables that are created later to be used but also
# allow for configuration of where the plist is stored
info_plist_wrapper (){

    # Call the get_current_user function
    get_current_user

    DEP_NOTIFY_USER_INPUT_PLIST="/Users/$CURRENT_USER/Library/Preferences/menu.nomad.DEPNotifyUserInput.plist"
}

# Status Text Alignment
# The status text under the progress bar can be configured to be left, right,
# or center
STATUS_TEXT_ALIGN="center"

# Help Button Configuration
# The help button was changed to a popup. Button will appear if title is
# populated.
HELP_BUBBLE_TITLE="Need Help?"
HELP_BUBBLE_BODY='This tool at Your_Org_Name_Here is designed to help \nwith new employee onboarding. \nIf you have issues, please give us a \ncall at 123-456-7890'


################################################################################
# Error Screen Text
################################################################################
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


################################################################################
# Caffeinate / No Sleep Configuration
################################################################################
# Flag script to keep the computer from sleeping. BE VERY CAREFUL WITH THIS
# FLAG! This flag could expose your data to risk by leaving an unlocked
# computer wide open. Only recommended if you are using fullscreen mode and
# have a logout taking place at the end of configuration (like for FileVault).
# Some folks may use this in workflows where IT staff are the primary people
# setting up the device. The device will be allowed to sleep again once the
# DEPNotify app is quit as caffeinate is looking at DEPNotify's process ID.
NO_SLEEP=false


################################################################################
# Customized Self Service Branding
################################################################################
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


################################################################################
# EULA Variables to Modify
################################################################################
# EULA configuration
EULA_ENABLED=false # Set variable to true or false

# EULA status bar text
EULA_STATUS="Waiting on completion of EULA acceptance"

# EULA button text on the main screen
EULA_BUTTON="Read and Agree to EULA"

# EULA Screen Title
EULA_MAIN_TITLE="Organization End User License Agreement"

# EULA Subtitle
EULA_SUBTITLE='Please agree to the following terms and conditions to start configuration of this Mac'

# Path to the EULA file you would like the user to read and agree to. It is
# best to package this up with Composer or another tool and deliver it to a
# shared area like /Users/Shared/
EULA_FILE_PATH="/Users/Shared/eula.txt"


################################################################################
# Registration Variables to Modify
################################################################################

# Registration window configuration
REGISTRATION_ENABLED=false # Set variable to true or false

# Registration window title
REGISTRATION_TITLE="Register Mac at Organization"

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
################################################################################
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
reg_text_label_1_logic (){
    REG_TEXT_LABEL_1_VALUE=$(defaults \
        read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_TEXT_LABEL_1")

    if [ "$REG_TEXT_LABEL_1_OPTIONAL" = true ] && \
        [ "$REG_TEXT_LABEL_1_VALUE" = "" ]; then

        echo "Status: $REG_TEXT_LABEL_1 was left empty. Skipping..." >> "$DEP_NOTIFY_LOG"

        echo "$DATE: $REG_TEXT_LABEL_1 was set to optional and was left empty. Skipping..." >> "$DEP_NOTIFY_DEBUG"
        /bin/sleep 5

    else
        echo "Status: $REGISTRATION_BEGIN_WORD $REG_TEXT_LABEL_1 $REGISTRATION_MIDDLE_WORD $REG_TEXT_LABEL_1_VALUE" >> "$DEP_NOTIFY_LOG"

        if [ "$TESTING_MODE" = true ]; then
            /bin/sleep 10

        else
            "$JAMF_BINARY" setComputerName -name "$REG_TEXT_LABEL_1_VALUE"
            /bin/sleep 5
        fi
    fi
}

# Second Text Field
################################################################################

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
reg_text_label_2_logic (){
    REG_TEXT_LABEL_2_VALUE=$(defaults \
        read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_TEXT_LABEL_2")

    if [ "$REG_TEXT_LABEL_2_OPTIONAL" = true ] && \
        [ "$REG_TEXT_LABEL_2_VALUE" = "" ]; then

        echo "Status: $REG_TEXT_LABEL_2 was left empty. Skipping..." >> "$DEP_NOTIFY_LOG"

        echo "$DATE: $REG_TEXT_LABEL_2 was set to optional and was left empty. Skipping..." >> "$DEP_NOTIFY_DEBUG"
        /bin/sleep 5

    else
        echo "Status: $REGISTRATION_BEGIN_WORD $REG_TEXT_LABEL_2 $REGISTRATION_MIDDLE_WORD $REG_TEXT_LABEL_2_VALUE" >> "$DEP_NOTIFY_LOG"

        if [ "$TESTING_MODE" = true ]; then
            /bin/sleep 10

        else
            "$JAMF_BINARY" recon -assetTag "$REG_TEXT_LABEL_2_VALUE"
        fi
    fi
}

# Popup 1
################################################################################

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
reg_popup_label_1_logic (){
    REG_POPUP_LABEL_1_VALUE=$(defaults \
        read "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_1")

    echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_1 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_1_VALUE" >> "$DEP_NOTIFY_LOG"

    if [ "$TESTING_MODE" = true ]; then
        /bin/sleep 10

    else
        "$JAMF_BINARY" recon -building "$REG_POPUP_LABEL_1_VALUE"
    fi
}

# Popup 2
################################################################################
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
reg_popup_label_2_logic (){

    REG_POPUP_LABEL_2_VALUE=$(defaults read \
        "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_2")

    echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_2 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_2_VALUE" >> "$DEP_NOTIFY_LOG"

    if [ "$TESTING_MODE" = true ]; then
        /bin/sleep 10

    else
        "$JAMF_BINARY" recon -department "$REG_POPUP_LABEL_2_VALUE"
    fi
}

# Popup 3 - Code is here but currently unused
################################################################################

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
reg_popup_label_3_logic (){

    REG_POPUP_LABEL_3_VALUE=$(defaults read \
        "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_3")

    echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_3 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_3_VALUE" >> "$DEP_NOTIFY_LOG"

    if [ "$TESTING_MODE" = true ]; then
        /bin/sleep 10

    else
        /bin.sleep 10
    fi
}

# Popup 4 - Code is here but currently unused
################################################################################
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
reg_popup_label_4_logic (){

    REG_POPUP_LABEL_4_VALUE=$(defaults read \
        "$DEP_NOTIFY_USER_INPUT_PLIST" "$REG_POPUP_LABEL_4")

    echo "Status: $REGISTRATION_BEGIN_WORD $REG_POPUP_LABEL_4 $REGISTRATION_MIDDLE_WORD $REG_POPUP_LABEL_4_VALUE" >> "$DEP_NOTIFY_LOG"

    if [ "$TESTING_MODE" = true ]; then
        /bin/sleep 10

    else
        /bin/sleep 10
    fi
}


###############################################################################
# FUNCTIONS
###############################################################################

logging () {
    # Logging function

    LOG_FILE="enrollment-$(date +"%Y-%m-%d").log"
    LOG_PATH="/Library/Logs/$LOG_FILE"
    DATE=$(date +"[%b %d, %Y %Z %T INFO]: ")
    /bin/echo "$DATE"$1 >> $LOG_PATH
}


validate_true_false_flags (){
    # Validating true/false flags that are set in the Jamf console for this
    # DEPNotify script.

    if [ "$TESTING_MODE" != true ] && [ "$TESTING_MODE" != false ]; then
        /bin/echo "$DATE: Testing configuration not set properly. Currently set to $TESTING_MODE. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Testing configuration not set properly. Currently set to $TESTING_MODE. Please update to true or false."
        exit 1
    fi

    if [ "$FULLSCREEN" != true ] && [ "$FULLSCREEN" != false ]; then
        /bin/echo "$DATE: Fullscreen configuration not set properly. Currently set to $FULLSCREEN. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Fullscreen configuration not set properly. Currently set to $FULLSCREEN. Please update to true or false."
        exit 1
    fi

    if [ "$NO_SLEEP" != true ] && [ "$NO_SLEEP" != false ]; then
        /bin/echo "$DATE: Sleep configuration not set properly. Currently set to $NO_SLEEP. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Sleep configuration not set properly. Currently set to $NO_SLEEP. Please update to true or false."
        exit 1
    fi

    if [ "$SELF_SERVICE_CUSTOM_BRANDING" != true ] && \
        [ "$SELF_SERVICE_CUSTOM_BRANDING" != false ]; then
        /bin/echo "$DATE: Self Service Custom Branding configuration not set properly. Currently set to $SELF_SERVICE_CUSTOM_BRANDING. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Self Service Custom Branding configuration not set properly. Currently set to $SELF_SERVICE_CUSTOM_BRANDING. Please update to true or false."
        exit 1
    fi

    if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" != true ] && \
        [ "$COMPLETE_METHOD_DROPDOWN_ALERT" != false ]; then
        /bin/echo "$DATE: Completion alert method not set properly. Currently set to $COMPLETE_METHOD_DROPDOWN_ALERT. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Completion alert method not set properly. Currently set to $COMPLETE_METHOD_DROPDOWN_ALERT. Please update to true or false."
        exit 1
    fi

    if [ "$EULA_ENABLED" != true ] && [ "$EULA_ENABLED" != false ]; then
        /bin/echo "$DATE: EULA configuration not set properly. Currently set to $EULA_ENABLED. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
        logging "DEBUG: EULA configuration not set properly. Currently set to $EULA_ENABLED. Please update to true or false."
        exit 1
    fi

    if [ "$REGISTRATION_ENABLED" != true ] && \
        [ "$REGISTRATION_ENABLED" != false ]; then

        /bin/echo "$DATE: Registration configuration not set properly. Currently set to $REGISTRATION_ENABLED. Please update to true or false." >> "$DEP_NOTIFY_DEBUG"
        logging "DEBUG: Registration configuration not set properly. Currently set to $REGISTRATION_ENABLED. Please update to true or false."
        exit 1
    fi
}


pretty_pause() {
    # Adding nice text and a brief pause for prettiness
    echo "Status: $INITAL_START_STATUS" >> "$DEP_NOTIFY_LOG"
    /bin/sleep 5
}


get_setup_assistant_process () {
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


get_finder_process (){
    # Check to see if the Finder is running yet. If it is, continue. Nice for
    # instances where the user is not setting up a username during the Setup
    # Assistant process.

    logging "Checking to see if the Finder process is running ..."
    echo "$DATE Checking to see if the Finder process is running ..."
    FINDER_PROCESS=$(/usr/bin/pgrep -l "Finder" 2> /dev/null)

    RESPONSE=$?

    logging "Finder PID: $FINDER_PROCESS"
    echo "Finder PID: $FINDER_PROCESS"

    while [[ $RESPONSE -ne 0 ]]; do

        logging "Finder PID not found. Assuming device is sitting \
            at the login window ..."

        echo "$DATE: Finder PID not found. Assuming device is sitting \
            at the login window ..."

        /bin/sleep 1

        FINDER_PROCESS=$(/usr/bin/pgrep -l "Finder" 2> /dev/null)

        RESPONSE=$?

        if [[ $FINDER_PROCESS != "" ]]; then
            logging "Finder PID: $FINDER_PROCESS"
            echo "$DATE: Finder PID: $FINDER_PROCESS"
        fi

    done

}


get_dep_notify_process (){
    # Grabbing the DEP Notify Process ID for use later
    DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)

    until [ "$DEP_NOTIFY_PROCESS" != "" ]; do

        /bin/echo "$DATE: Waiting for DEPNotify to start to gather the process ID." >> "$DEP_NOTIFY_DEBUG"
        /bin/sleep 1
        DEP_NOTIFY_PROCESS=$(pgrep -l "DEPNotify" | cut -d " " -f1)

    done

    /bin/echo "$DEP_NOTIFY_PROCESS"
}


caffeinate_this() {
    # Using Caffeinate binary to keep the computer awake if enabled
    if [ "$NO_SLEEP" = true ]; then
        /bin/echo "$DATE: Caffeinating DEP Notify process. Process ID: $DEP_NOTIFY_PROCESS" >> "$DEP_NOTIFY_DEBUG"
        caffeinate -disu -w "$DEP_NOTIFY_PROCESS"&
    fi
}


check_jamf_connect_login() {
    # check to ensure that jamf connect login is running before moving on
    # to the next step. If Jamf Connect Login is not installed attempt to
    # install it via Jamf Console policy.

    # Counter to keep track of counting
    COUNTER=0

    # Name of custom trigger for Jamf policy
    TRIGGER="jamf-connect-login"

    logging "Making sure Jamf Connect Login installed ..."
    AUTHCHANGER_BINARY="/usr/local/bin/authchanger"

    while [ ! -f "$AUTHCHANGER_BINARY" ]; do

        logging "Jamf Connect Login has not started yet ..."

        if [ ! -f "$AUTHCHANGER_BINARY" ] && [ "$COUNTER" -eq 10 ]; then
            # If Jamf Connect Login not installed, attempt to call the Jamf
            # console policy to install it.

            logging "Waited 10 seconds for Jamf Connect Login ..."
            logging "INSTALLER: Attemting to install Jamf Connect Login via Jamf policy ..."

            "$JAMF_BINARY" policy -event "$TRIGGER" | \
                /usr/bin/sed -e "s/^/$DATE/" | \
                /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1

        fi

        logging "Waiting 1 seconds before checking again ..."
        /bin/sleep 1
        AUTHCHANGER_BINARY="/usr/local/bin/authchanger"
        COUNTER=$((COUNTER+1))

    done

    logging "Found Jamf Connect Login ..."

}


check_for_dep_notify_app() {
    # check to ensure that jamf connect login is running before moving on
    # to the next step.

    logging "Making sure DEPNotify.app installed ..."
    DN_APP="/Applications/Utilities/DEPNotify.app"

    while [[ ! -d $DN_APP ]]; do
        logging "DEPNotify has not been installed yet ..."
        /bin/sleep 1
        DN_APP="/Applications/Utilities/DEPNotify.app"
    done

    logging "Found DEPNotify.app ..."
}


launch_dep_notify_app (){
    # Opening the app after initial configuration
    if [ "$FULLSCREEN" = true ]; then
        sudo -u "$CURRENT_USER" \
            open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG" -fullScreen

    elif [ "$FULLSCREEN" = false ]; then
        sudo -u "$CURRENT_USER" \
            open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"
    fi
}


jamf_binary_checker() {
    # Checks for the Jamf binary before continuing.

    while [[ ! -f /usr/local/bin/jamf ]]; do
        # Sleep for 2 seconds

        echo "$DATE: Waiting for the jamf binary to install ..."
        logging "Waiting for the jamf binary to install ..."
        /bin/sleep 2

    done

    logging "The Jamf binary is installed."
}


get_current_user() {
    # Return the current user
    CURRENT_USER=$(/usr/bin/stat -f '%Su' /dev/console)
}


get_current_user_uid() {
    # Check to see if the current console user uid is greater than 501
    # Loop until either the 501 or 502 user is found.

    # Get the current console user again
    get_current_user

    logging "Getting current user UID ..."
    echo "$DATE: Getting current user UID ..."

    CURRENT_USER_UID=$(/usr/bin/dscl . -list /Users UniqueID | \
        /usr/bin/grep "$CURRENT_USER" | \
        /usr/bin/awk '{print $2}' | \
        /usr/bin/sed -e 's/^[ \t]*//')

    echo "$DATE: Current User: $CURRENT_USER"
    logging "Current User: $CURRENT_USER"
    echo "$DATE: Current User UID: $CURRENT_USER_UID"
    logging "Current User UID: $CURRENT_USER_UID"

    while [[ $CURRENT_USER_UID -lt 501 ]]; do

        logging "Current user is not logged in ... WAITING"
        echo "$DATE: Current user is not logged in ... WAITING"

        /bin/sleep 1

        # Get the current console user again
        get_current_user

        CURRENT_USER_UID=$(/usr/bin/dscl . -list /Users UniqueID | \
            /usr/bin/grep "$CURRENT_USER" | \
            /usr/bin/awk '{print $2}' | \
            /usr/bin/sed -e 's/^[ \t]*//')

        logging "Current User: $CURRENT_USER"
        echo "$DATE: Current User: $CURRENT_USER"
        logging "Current User UID: $CURRENT_USER_UID"
        echo "$DATE Current User UID: $CURRENT_USER_UID"

        if [[ $CURRENT_USER_UID -lt 501 ]]; then
            logging "Current user: $CURRENT_USER with UID ..."
            echo "$DATE: Current user: $CURRENT_USER with UID ..."
        fi

    done

}


eula_configuration() {
    # EULA Configuration
    if [ "$EULA_ENABLED" =  true ]; then

        DEP_NOTIFY_EULA_DONE="/var/tmp/com.depnotify.agreement.done"

        # If testing mode is on, this will remove EULA specific configuration
        # files
        if [ "$TESTING_MODE" = true ] && \
            [ -f "$DEP_NOTIFY_EULA_DONE" ]; then

            rm "$DEP_NOTIFY_EULA_DONE"; fi

        # Writing title, subtitle, and EULA txt location to plist
        defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
            EULAMainTitle "$EULA_MAIN_TITLE"
        defaults write "$DEP_NOTIFY_CONFIG_PLIST" EULASubTitle "$EULA_SUBTITLE"
        defaults write "$DEP_NOTIFY_CONFIG_PLIST" pathToEULA "$EULA_FILE_PATH"

        # Setting ownership of EULA file
        chown "$CURRENT_USER:staff" "$EULA_FILE_PATH"
        chmod 444 "$EULA_FILE_PATH"
    fi
}


self_service_custom_branding() {
    # If SELF_SERVICE_CUSTOM_BRANDING is set to true. Loading the updated icon
    if [ "$SELF_SERVICE_CUSTOM_BRANDING" = true ]; then

        open -a "/Applications/$SELF_SERVICE_APP_NAME" --hide

        # Loop waiting on the branding image to properly show in the users
        # library
        CUSTOM_BRANDING_PNG="/Users/$CURRENT_USER/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"

        until [ -f "$CUSTOM_BRANDING_PNG" ]; do
            echo "$DATE: Waiting for branding image from Jamf Pro." >> "$DEP_NOTIFY_DEBUG"
            /bin/sleep 1
        done

        # Setting Banner Image for DEP Notify to Self Service Custom Branding
        BANNER_IMAGE_PATH="$CUSTOM_BRANDING_PNG"

        # Closing Self Service
        SELF_SERVICE_PID=$(pgrep -l "$(echo "$SELF_SERVICE_APP_NAME" | \
            /usr/bin/cut -d "." -f1)" | \
            /usr/bin/cut -d " " -f1)

        echo "$DATE: Self Service custom branding icon has been loaded. Killing Self Service PID $SELF_SERVICE_PID." >> "$DEP_NOTIFY_DEBUG"

        kill "$SELF_SERVICE_PID"

    fi
}


self_service_custom_branding (){
    # Setting custom image if specified
    if [ "$BANNER_IMAGE_PATH" != "" ]; then
        echo "Command: Image: $BANNER_IMAGE_PATH" >> "$DEP_NOTIFY_LOG";
    fi

    # Setting custom title if specified
    if [ "$BANNER_TITLE" != "" ]; then
        echo "Command: MainTitle: $BANNER_TITLE" >> "$DEP_NOTIFY_LOG";
    fi

    # Setting custom main text if specified
    if [ "$MAIN_TEXT" != "" ]; then
        echo "Command: MainText: $MAIN_TEXT" >> "$DEP_NOTIFY_LOG";
    fi
}


general_plist_config() {
    # General Plist Configuration

    # Calling function to set the INFO_PLIST_PATH
    info_plist_wrapper

    # The plist information below
    DEP_NOTIFY_CONFIG_PLIST="/Users/$CURRENT_USER/Library/Preferences/menu.nomad.DEPNotify.plist"

    if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_CONFIG_PLIST" ]; then
        # If testing mode is on, this will remove some old configuration files
        rm "$DEP_NOTIFY_CONFIG_PLIST";
    fi

    if [ "$TESTING_MODE" = true ] && [ -f "$DEP_NOTIFY_USER_INPUT_PLIST" ]; then
        rm "$DEP_NOTIFY_USER_INPUT_PLIST";
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
    chown "$CURRENT_USER":staff "$DEP_NOTIFY_CONFIG_PLIST"
    chmod 600 "$DEP_NOTIFY_CONFIG_PLIST"
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
        defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
            registrationMainTitle "$REGISTRATION_TITLE"
        defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
            registrationButtonLabel "$REGISTRATION_BUTTON"
        defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
            registrationPicturePath "$BANNER_IMAGE_PATH"

        # First Text Box Configuration
        if [ "$REG_TEXT_LABEL_1" != "" ]; then
            defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField1Label "$REG_TEXT_LABEL_1"
            defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField1Placeholder "$REG_TEXT_LABEL_1_PLACEHOLDER"
            defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField1IsOptional "$REG_TEXT_LABEL_1_OPTIONAL"

            # Code for showing the help box if configured
            if [ "$REG_TEXT_LABEL_1_HELP_TITLE" != "" ]; then
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    textField1Bubble -array-add "$REG_TEXT_LABEL_1_HELP_TITLE"
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    textField1Bubble -array-add "$REG_TEXT_LABEL_1_HELP_TEXT"
            fi
        fi

        # Second Text Box Configuration
        if [ "$REG_TEXT_LABEL_2" != "" ]; then

            defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField2Label "$REG_TEXT_LABEL_2"
            defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField2Placeholder "$REG_TEXT_LABEL_2_PLACEHOLDER"
            defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                textField2IsOptional "$REG_TEXT_LABEL_2_OPTIONAL"

            # Code for showing the help box if configured
            if [ "$REG_TEXT_LABEL_2_HELP_TITLE" != "" ]; then

                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    textField2Bubble -array-add "$REG_TEXT_LABEL_2_HELP_TITLE"
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    textField2Bubble -array-add "$REG_TEXT_LABEL_2_HELP_TEXT"

            fi
        fi

        # Popup 1
        if [ "$REG_POPUP_LABEL_1" != "" ]; then

            defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                popupButton1Label "$REG_POPUP_LABEL_1"

            # Code for showing the help box if configured
            if [ "$REG_POPUP_LABEL_1_HELP_TITLE" != "" ]; then

                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu1Bubble -array-add "$REG_POPUP_LABEL_1_HELP_TITLE"
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu1Bubble -array-add "$REG_POPUP_LABEL_1_HELP_TEXT"

            fi

            # Code for adding the items from the array above into the plist
            for REG_POPUP_LABEL_1_OPTION in "${REG_POPUP_LABEL_1_OPTIONS[@]}";
            do
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupButton1Content -array-add "$REG_POPUP_LABEL_1_OPTION"
            done
        fi

        # Popup 2
        if [ "$REG_POPUP_LABEL_2" != "" ]; then

            defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                popupButton2Label "$REG_POPUP_LABEL_2"

            # Code for showing the help box if configured
            if [ "$REG_POPUP_LABEL_2_HELP_TITLE" != "" ]; then

                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu2Bubble -array-add "$REG_POPUP_LABEL_2_HELP_TITLE"
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu2Bubble -array-add "$REG_POPUP_LABEL_2_HELP_TEXT"

            fi

            # Code for adding the items from the array above into the plist
            for REG_POPUP_LABEL_2_OPTION in "${REG_POPUP_LABEL_2_OPTIONS[@]}";
            do
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupButton2Content -array-add "$REG_POPUP_LABEL_2_OPTION"
            done
        fi

        # Popup 3
        if [ "$REG_POPUP_LABEL_3" != "" ]; then

            defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                popupButton3Label "$REG_POPUP_LABEL_3"

            # Code for showing the help box if configured
            if [ "$REG_POPUP_LABEL_3_HELP_TITLE" != "" ]; then

                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu3Bubble -array-add "$REG_POPUP_LABEL_3_HELP_TITLE"
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu3Bubble -array-add "$REG_POPUP_LABEL_3_HELP_TEXT"

            fi

            # Code for adding the items from the array above into the plist
            for REG_POPUP_LABEL_3_OPTION in "${REG_POPUP_LABEL_3_OPTIONS[@]}";
            do
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupButton3Content -array-add "$REG_POPUP_LABEL_3_OPTION"
            done
        fi

        # Popup 4
        if [ "$REG_POPUP_LABEL_4" != "" ]; then

            defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                popupButton4Label "$REG_POPUP_LABEL_4"

            # Code for showing the help box if configured
            if [ "$REG_POPUP_LABEL_4_HELP_TITLE" != "" ]; then

                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu4Bubble -array-add "$REG_POPUP_LABEL_4_HELP_TITLE"
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupMenu4Bubble -array-add "$REG_POPUP_LABEL_4_HELP_TEXT"

            fi
            # Code for adding the items from the array above into the plist
            for REG_POPUP_LABEL_4_OPTION in "${REG_POPUP_LABEL_4_OPTIONS[@]}";
            do
                defaults write "$DEP_NOTIFY_CONFIG_PLIST" \
                    popupButton4Content -array-add "$REG_POPUP_LABEL_4_OPTION"
            done
        fi
    fi
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
            ((ADDITIONAL_OPTIONS_COUNTER++));
        fi

        if [ "$REG_TEXT_LABEL_2" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++));
        fi

        if [ "$REG_POPUP_LABEL_1" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++));
        fi

        if [ "$REG_POPUP_LABEL_2" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++));
        fi

        if [ "$REG_POPUP_LABEL_3" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++));
        fi

        if [ "$REG_POPUP_LABEL_4" != "" ]; then
            ((ADDITIONAL_OPTIONS_COUNTER++));
        fi

    fi

    # Checking policy array and adding the count from the additional options
    # above.
    ARRAY_LENGTH="$((${#POLICY_ARRAY[@]}+ADDITIONAL_OPTIONS_COUNTER))"
    echo "Command: Determinate: $ARRAY_LENGTH" >> "$DEP_NOTIFY_LOG"
}


eula_logic (){
    # EULA Window Display Logic
    if [ "$EULA_ENABLED" = true ]; then

        echo "Status: $EULA_STATUS" >> "$DEP_NOTIFY_LOG"
        echo "Command: ContinueButtonEULA: $EULA_BUTTON" >> "$DEP_NOTIFY_LOG"

        while [ ! -f "$DEP_NOTIFY_EULA_DONE" ]; do
            echo "$DATE: Waiting for user to accept EULA." >> "$DEP_NOTIFY_DEBUG"
            logging "INFO: Waiting for user to accept EULA."
            /bin/sleep 1
        done

    fi
}


registration_window_display_logic (){
    # Registration Window Display Logic
    if [ "$REGISTRATION_ENABLED" = true ]; then
        echo "Status: $REGISTRATION_STATUS" >> "$DEP_NOTIFY_LOG"
        echo "Command: ContinueButtonRegister: $REGISTRATION_BUTTON" >> "$DEP_NOTIFY_LOG"

        while [ ! -f "$DEP_NOTIFY_REGISTER_DONE" ]; do
            echo "$DATE: Waiting for user to complete registration." >> "$DEP_NOTIFY_DEBUG"
            /bin/sleep 1
        done

        # Running Logic For Each Registration Box
        if [ "$REG_TEXT_LABEL_1" != "" ]; then reg_text_label_1_logic; fi
        if [ "$REG_TEXT_LABEL_2" != "" ]; then reg_text_label_2_logic; fi
        if [ "$REG_POPUP_LABEL_1" != "" ]; then reg_popup_label_1_logic; fi
        if [ "$REG_POPUP_LABEL_2" != "" ]; then reg_popup_label_2_logic; fi
        if [ "$REG_POPUP_LABEL_3" != "" ]; then reg_popup_label_3_logic; fi
        if [ "$REG_POPUP_LABEL_4" != "" ]; then reg_popup_label_4_logic; fi
    fi
}


install_policies () {
    # Install policies by looping through the policy array defined above.

    logging "Preparing to install Jamf application policies."

    for policy in "${POLICY_ARRAY[@]}"; do
        # Loop through the policy array and install each policy

        echo "Status: $(echo "$policy" | cut -d ',' -f1)" >> "$DEP_NOTIFY_LOG"

        logging "Policy: "$policy
        if [[ $TESTING_MODE = true ]]; then
            logging "Test mode enabled ... INFO"
            sleep 10

        elif [[ $TESTING_MODE = false ]]; then
            "$JAMF_BINARY" policy \
                -event "$(echo "$policy" | cut -d ',' -f2)" | \
        		/usr/bin/sed -e "s/^/$DATE/" | \
        		/usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
        fi
    done
}


set_computer_name () {
    # Set the computer name

    # Store device serial number
    SERIAL_NUMBER=$(/usr/sbin/system_profiler SPHardwareDataType | \
            /usr/bin/awk '/Serial\ Number\ \(system\)/ {print $NF}')

    logging "Setting computer name to: $SERIAL_NUMBER"

    # Set device name using scutil
    /usr/sbin/scutil --set ComputerName "${SERIAL_NUMBER}"
    /usr/sbin/scutil --set LocalHostName "${SERIAL_NUMBER}"
    /usr/sbin/scutil --set HostName "${SERIAL_NUMBER}"

    # Set device name using jamf binary to make sure of the correct name
    "$JAMF_BINARY" setComputerName -useSerialNumber

}


filevault_configuration() {
    # Check to see if FileVault Deferred enablement is active
    FV_DEFERRED_STATUS=$($FDESETUP_BINARY status | \
        /usr/bin/grep "Deferred" | \
        /usr/bin/cut -d ' ' -f6)

    # Logic to log user out if FileVault is detected. Otherwise, app will close.
    if [ "$FV_DEFERRED_STATUS" = "active" ] && [ "$TESTING_MODE" = true ]; then
        if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
            echo "Command: Quit: This is typically where your FV_LOGOUT_TEXT would be displayed. However, TESTING_MODE is set to true and FileVault deferred status is on." >> "$DEP_NOTIFY_LOG"
        else
            echo "Command: MainText: TESTING_MODE is set to true and FileVault deferred status is on. Button effect is quit instead of logout. \n \n $FV_COMPLETE_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
            echo "Command: ContinueButton: Test $FV_COMPLETE_BUTTON_TEXT" >> "$DEP_NOTIFY_LOG"
        fi

    elif [ "$FV_DEFERRED_STATUS" = "active" ] && \
        [ "$TESTING_MODE" = false ]; then

        if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
        echo "Command: Logout: $FV_ALERT_TEXT" >> "$DEP_NOTIFY_LOG"

        else
            echo "Command: MainText: $FV_COMPLETE_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
            echo "Command: ContinueButtonLogout: $FV_COMPLETE_BUTTON_TEXT" >> "$DEP_NOTIFY_LOG"
        fi

    else
      if [ "$COMPLETE_METHOD_DROPDOWN_ALERT" = true ]; then
        echo "Command: Quit: $COMPLETE_ALERT_TEXT" >> "$DEP_NOTIFY_LOG"
      else
        echo "Command: MainText: $COMPLETE_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
        echo "Command: ContinueButton: $COMPLETE_BUTTON_TEXT" >> "$DEP_NOTIFY_LOG"
      fi
    fi
}


checkin_to_jamf() {
    # Force the Mac to checkin with Jamf and submit its enventory.
    "$JAMF_BINARY" recon
}


reboot_me() {
    # Rebooting to complete provisioning
    "$JAMF_BINARY" policy -event enrollment-complete-reboot | \
        /usr/bin/sed -e "s/^/$DATE/" | \
        /usr/bin/tee -a "$LOG_PATH" > /dev/null 2>&1
}


###############################################################################
###############################################################################
####   MAING SCRIPT: DO NOT EDIT BELOW THIS LINE
###############################################################################
###############################################################################


# CONSTENT VARIABLES
# DEFAULTS_BINARY="/usr/bin/defaults"
FDESETUP_BINARY="/usr/bin/fdesetup"
# IFCONFIG="/sbin/ifconfig"
JAMF_BINARY="/usr/local/bin/jamf"
# NETWORKSETUP="/usr/sbin/networksetup"
# OSASCRIPT_BINARY="/usr/bin/osascript"
# PMSET="/usr/bin/pmset"

# Log files
LOG_FILE="enrollment-$(date +"%Y-%m-%d").log"
LOG_PATH="/Library/Logs/$LOG_FILE"
DATE=$(date +"[%b %d, %Y %Z %T INFO]")
DEP_NOTIFY_APP="/Applications/Utilities/DEPNotify.app"
DEP_NOTIFY_LOG="/var/tmp/depnotify.log"
DEP_NOTIFY_DEBUG="/var/tmp/depnotifyDebug.log"
DEP_NOTIFY_DONE="/var/tmp/com.depnotify.provisioning.done"


# Pulling from Policy parameters to allow true/false flags to be set. More
# info can be found on
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


#
# Standard Testing Mode Enhancements
#

if [ "$TESTING_MODE" = true ]; then

    # Removing old config file if present (Testing Mode Only)
    if [ -f "$DEP_NOTIFY_LOG" ]; then rm "$DEP_NOTIFY_LOG"; fi
    if [ -f "$DEP_NOTIFY_DONE" ]; then rm "$DEP_NOTIFY_DONE"; fi
    if [ -f "$DEP_NOTIFY_DEBUG" ]; then rm "$DEP_NOTIFY_DEBUG"; fi

    # Setting Quit Key set to command + control + x (Testing Mode Only)
    echo "Command: QuitKey: x" >> "$DEP_NOTIFY_LOG"
fi


main() {
    # Main function

    logging ""
    logging "--- BEGIN DEVICE ENROLLMENT LOG ---"
    logging ""
    logging "Jamf DEPNotify Enrollment Script Version ${VERSION}"
    logging ""


    for func in validate_true_false_flags get_setup_assistant_process \
        check_jamf_connect_login check_for_dep_notify_app \
        get_finder_process jamf_binary_checker get_current_user_uid; do

        logging "INFO: Running $func"
        "$func"

        RET="$?"

        if [ "$RET" -ne 0 ]; then
            # An error occured. Log it.
            logging "ERROR: An error occured while running $func"
            exit "$RET"
        fi

    done


    # Adding Check and Warning if Testing Mode is off and BOM files exist
    if [[ ( -f "$DEP_NOTIFY_LOG" || -f "$DEP_NOTIFY_DONE" ) && "$TESTING_MODE" = false ]]; then

        echo "$DATE: TESTING_MODE set to false but config files were found in /var/tmp. Letting user know and exiting." >> "$DEP_NOTIFY_DEBUG"

        mv "$DEP_NOTIFY_LOG" "/var/tmp/depnotify_old.log"

        echo "Command: MainTitle: $ERROR_BANNER_TITLE" >> "$DEP_NOTIFY_LOG"
        echo "Command: MainText: $ERROR_MAIN_TEXT" >> "$DEP_NOTIFY_LOG"
        echo "Status: $ERROR_STATUS" >> "$DEP_NOTIFY_LOG"

        sudo -u "$CURRENT_USER" \
            open -a "$DEP_NOTIFY_APP" --args -path "$DEP_NOTIFY_LOG"

        /bin/sleep 5

        exit 1
    fi


    for func in self_service_custom_branding general_plist_config \
        launch_dep_notify_app; do

        logging "INFO: Running $func"
        "$func"

        RET="$?"

        if [ "$RET" -ne 0 ]; then
            # An error occured. Log it.
            logging "ERROR: An error occured while running $func"
            exit "$RET"
        fi

    done


    get_dep_notify_process
    caffeinate_this "$DEP_NOTIFY_PROCESS"

    # Adding an alert prompt to let admins know that the script is in testing
    # mode
    if [ "$TESTING_MODE" = true ]; then
        /bin/echo "Command: Alert: DEP Notify is in TESTING_MODE. Script will not run Policies or other commands that make change to this computer."  >> "$DEP_NOTIFY_LOG"
    fi


    for func in pretty_pause status_bar_gen eula_logic \
    registration_window_display_logic install_policies set_computer_name; do

        logging "INFO: Running $func"
        "$func"

        RET="$?"

        if [ "$RET" -ne 0 ]; then
            # An error occured. Log it.
            logging "ERROR: An error occured while running $func"
            exit "$RET"
        fi

    done


    logging "Enableing Location services ..."
    sudo -u _locationd /usr/bin/defaults \
        -currentHost write com.apple.locationd LocationServicesEnabled -int 1

    #Lock Keychain while Sleep
    logging "Keychain: Lock keychain while device is sleeping."
    sudo security set-keychain-settings -l


    # Check to see if FileVault needs to be configured
    echo "Status: Checking FileVault" >> "$DEP_NOTIFY_LOG"
    filevault_configuration

    echo "Status: Submitting device inventory to Jamf" >> "$DEP_NOTIFY_LOG"
    checkin_to_jamf

    # Nice completion text
    echo "Status: $INSTALL_COMPLETE_TEXT" >> "$DEP_NOTIFY_LOG"

    logging ""
    logging "--- END DEVICE ENROLLMENT LOG ---"
    logging ""

    echo "$DATE: --- END DEVICE ENROLLMENT LOG ---"

}

# Call the main funcion
main

exit 0
