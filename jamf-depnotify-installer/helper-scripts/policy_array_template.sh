#!/usr/bin/env bash

###############################################################################
# POLICY ARRAY VARIABLE TO MODIFY
###############################################################################
# The policy array must be formatted "Progress Bar text,customTrigger". These
# will be run in order as they appear below.
#
# Where applicable, updated the array with applications that are being deployed
# from Jamf during device enrollment. If the application already exists on the
# device then we want to skip that app. This can happen is cases like re-
# enrollment or if the device is pre-existing when the device is not wiped
# prior to enrolling.
POLICY_ARRAY=(
	# "Installing App Name,your-custom-trigger"
	"Installing Citrix Workspace,citrix-workspace"
    "Installing Enterprise Connect,enterprise-connect"
    "Installing Global Protect VPN Client,global-protect"
	"Installing Google Chrome,google-chrome-browser"
	"Installing Microsoft Office (This may take some time depending on your network speed),microsoft-office"
	"Installing Skype for Business,microsoft-skype-for-business"
	"Install Symantec Enpoint Protection,symantec-endpoint-protection"
	"Install Carbon Black Defense,carbon-black-defense"
	"Enabled FileVault Disk Encryption,enable-filevault"
	"Setting the Desktop Wallpaper,set-desktop-wallpaper"
	"Finalizing your Mac setup,replace-macos-dock"
)


#######################################################################################
# (OPTIONAL) APP ICON ARRAY VARIABLE TO MODIFY
#######################################################################################
# The policy array must be formatted "App Name,/path/to/local/image.png". The App name
# should be contained in both the App Icon Array and the Policy array so that the
# script can determine which icon needs to be displayed.
#
# These icons should coinside with the order of the policy array above so that the
# right App icon is displayed as the App is being installed. This array is not required.
#
# These icon images will need to be deployed in the jamf-depnotify-installer package.
APP_ICON_ARRAY=(
	# "App Name,/tmp/depnotify/icons/icon_name.png"
	"Citrix Workspace,/tmp/depnotify/icons/citrix_workspace_icon.png"
	"Enterprise Connect,/tmp/depnotify/icons/apple_ec_icon.png"
    "Global Protect,/tmp/depnotify/icons/paloalto_global_protect_new_icon.png"
	"Google Chrome,/tmp/depnotify/icons/google_chrome_browser_icon.png"
	"Microsoft Office,/tmp/depnotify/icons/microsoft_office_icon.png"
	"Skype for Business,/tmp/depnotify/icons/microsoft_skype_for_biz_icon.png"
	"Symantec Enpoint Protection,/tmp/depnotify/icons/symantec_sep_icon.png"
	"Carbon Black Defense,/tmp/depnotify/icons/vmware_carbon_black_defense_icon.png"
	"FileVault,/tmp/depnotify/icons/apple_filevault_icon.png"
	"Desktop Wallpaper,/tmp/depnotify/icons/com.apple.macbook-retina-space-gray-insight2020.png"
	"Finalizing,/tmp/depnotify/icons/com.apple.macbook-retina-space-gray-insight2020.png"
)


# Testing this to see if a link to an image can be refernced
#######################################################################################
# (OPTIONAL) APP ICON ARRAY VARIABLE TO MODIFY
#######################################################################################
# The policy array must be formatted "App Name,/path/to/local/image.png". The App name
# should be contained in both the App Icon Array and the Policy array so that the
# script can determine which icon needs to be displayed.
#
# These icons should coinside with the order of the policy array above so that the
# right App icon is displayed as the App is being installed. This array is not required.
#
# These icon images will need to be deployed in the jamf-depnotify-installer package.
APP_ICON_ARRAY=(
	# "App Name,/tmp/depnotify/icons/icon_name.png"
	"Citrix Workspace,https://ima.jamfcloud.com/icon?id=10951"
	"Enterprise Connect,https://ima.jamfcloud.com/icon?id=10950"
    "Global Protect,https://ima.jamfcloud.com/icon?id=10952"
	"Google Chrome,https://ima.jamfcloud.com/icon?id=2537"
	"Microsoft Office,https://ima.jamfcloud.com/icon?id=136"
	"Skype for Business,https://ima.jamfcloud.com/icon?id=2541"
	"Symantec Enpoint Protection,https://ima.jamfcloud.com/icon?id=2542"
	"Carbon Black Defense,https://ima.jamfcloud.com/icon?id=10953"
	"FileVault,https://ima.jamfcloud.com/icon?id=10949"
)

DEPNOTIFY_LOGOUT="/Users/captam3rica/Desktop/enrollment-this.log"
DEPNOTIFY_DONE="/Users/captam3rica/Desktop/jamf.log"

wait_for_completion() {
	# Wait for the user to press the Logout button.
	while [ ! -f "$DEPNOTIFY_LOGOUT" ] || [ ! -f "$DEPNOTIFY_DONE" ]; do
		echo "Cleanup: Waiting for Completion file ..."
		echo "Cleanup: The user has not closed the DEPNotify window ..."
		echo "Cleanup: Waiting 1 second ..."
		/bin/sleep 1
		if [ -f "$DEPNOTIFY_DONE" ]; then
			echo "Cleanup: Found $DEPNOTIFY_DONE"
			break
		fi

		if [ -f "$DEPNOTIFY_LOGOUT" ]; then
			echo "Cleanup: Found $DEPNOTIFY_LOGOUT"
			break
		fi
	done
}

wait_for_completion
