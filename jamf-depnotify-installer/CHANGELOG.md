# Change Log
All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to Year Notation Versioning.


## Types of Changes

- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.


## [v2.2.5] - 2020-06-25

- **Added** - Additional clarification added to the `APP_ICON_ARRAY` description to explain the concept a bit better, and added example directory structure for placing app icon images in the DEPNotify Distribution package.
- **Changed** - Instead of setting the Mac computer name to the serial number by default you can now toggle this function on by setting `COMPUTER_NAME_ENABLE` to `true`. If this option is not enabled the Mac will be named something like `John's MacBook Pro` or `Jane's iMac Pro`. Alternatively, you can set the device name via MDM.
    - **Added** - Ability to set a prefix to the computer name. This requires that the `COMPUTER_NAME_ENABLE` option be set to `true.`
- **Changed** - Refactored code for readability.

## [v2.2.3] - 2020-06-05

- **Changed** - Refactored and restructured `jamf_depnotify_start.sh` logic.


## [v2.2.2] - 2020-05-26

- **Added** - Added logic to ensure that the Jamf Self Service app is launched if custom branding is being used. Saw some instances in macOS Catalina where the Self Service app would never launch during device configuration and this would prevent DEPNotify from launching as well. 


## [v2.2.1] - 2020-04-30

- **Changed** - A bunch of code refactoring for readability.
- **Changed** - Moved unnecessary logging out of individual functions and into the main function call.
- **Changed** - now the `dep_notify_clean` function checked for the the `.logout` and `.done` DEPNotify files.
- **Fixed** minor bugs.


## [v2.2.0] - 2020-04-25

- **Added** ability to update the **[`MainTextImage`](https://gitlab.com/Mactroll/DEPNotify#maintextimage)** to the icon of the app being installed.
- **Changed** restart logic to leverage the builtin DEPNotify **[`Command: Restart`](https://gitlab.com/Mactroll/DEPNotify#restart)** functionality.

## [v2.1.2] - 2020-04-25

- **Added** variable to hold the name of the organization that way it only needs to be modified in one place within the script.
- **Added** TRIGGER var to allow for either a customer trigger or policy ID to be passed to the `jamf policy` command. Update added from the Start DEPNotify Jamf repo.
- **Changes** to script logic.
- **Changes** to syntax


## [v2.1.0] - 2020-04-21

- Added a switch at the top of the script to enabled the SAP Privileges app. This does require that an associated app install policy also be in Jamf.
- Added logic to install SAP Privileges App via Jamf policy if FV is enabled.


## [v2.0.0] - 2020-03-03

### Added

- Added option in the script to set an ENROLLMENT\_COMPLETE_REBOOT flag.
    - If configured will call a policy in Jamf Pro to reboot the device. This is assuming that the policy has already been created in Jamf.
    - This can be helpful in situations where software needs the Mac to restart or if you are delivering the Mac to an end user and you would like them to start fresh at a login window.
- Added logic to only run certain pieces of the code if they have been toggled on either in Jamf Pro script parameters or in the script itself.

### Changed

- Moved all changes to a dedicated change log.
- Updated `README.md`
- Updated the log file name to the name of the enrollment script.
- Moved DEPNotify Cleanup
    - Moved the DEPNotify clean up script into the main enrollment script to reduce some of the over head needed in maintaining an additional policy just to run a clean up routine.
    - Will make it more portable for conversion and use with other MDM platforms.
- Changed the get\_current_user logic so that it adheres more closely to the Apple way.

### Removed

- Removed the logic that checks for the DEPNotify daemon as this is being handled in the DEPNotify clean logic within the main script.


## [Initial Changelog]

Captures everything prior to adding this change log file to this repo. Yes I know it should be in reverse chronological order. I just haven't made time to go back and change this. :P

### Version - v1.0.0

- Modified from Jamf's DEPNotify-Starter script found here https://github.com/jamf/DEPNotify-Starter
- Initial release
- Converted a number of the features in this script to functions.
- A secondary log file is generated at /Library/Logs
    - enrollment-<date>.log

### Version - v1.0.1

- Added check within the check_jamf_connect_login function to attempt an installation of Jamf Connect Login if after 10 seconds the Connect Login binary is not 


### Version - v1.0.2

- Moved the policy array section closer to the top of the script to make it a little easier to modify later.


### Version - v1.0.3

- Added functionality to rename Mac
- Added function that calls jamf recon
- Added DEPNotiy status for FaultVault check and submitting inventory to Jamf console.


### Version - v1.0.4

- Added fix for Wi-Fi switching over before the end of the enrollment.
- Added function to create an enrollment complete stub file.
    - Once the stub is laid down the Mac will check in.
- Added an accompanying Extension attribute that checks for the enrollment complete stub.
    - The Mac will then be moved to an  Enrollment Complete smart group. This Smart group can have any number of profiles scoped to it. For example if you want to determine exactly when a Wi-Fi profile is installed on a device you can use this method to make sure that you control the state of the device.
    - This is all in an effort to control when the configuration profile is installed on the device.


### Version - v1.0.5

- Added ability to cleanup DEPNotify and the dependencies that are left behind once the deployment process is over.
    - calls a Jamf Pro policy containing a script


### Version - v1.0.6

- Additional code refactoring done.
- Added ability to check for the dep-notify-enrollment daemon to see if it is running before starting the DEPNotify process.
- Added Jamf policy to policy array that creates a local administrator account on the Mac.


### Version - v1.1

- Added ability to update the username assigned in Jamf computer inventory record.
    - calls a policy tied to a script that will determine if device was enrolled via UIE or Automated Enrollment.
    - This functionality can be toggled on with the variable UPDATE\_USERNAME\_INVENTORY_RECORD below.


### Version - v1.2

- Added the ability to enable checking for Jamf Connect Login with the JAMF\_CONNECT_ENABLED variable. This variable is assigned to the Jamf script parameter option number 11. Set the option to true else it will remain false and assume that we are not using Jamf Connect.


### Version - v1.2.1

- Refactoring to make the script a little more portable.
- Added additional functionality to the is\_jamf\_enrollment_complete function to check for the jamf.log then look in the log to see if the enrollmentComplete string is present.

### Version - v1.3.0

- Added ability to bind the Mac to an AD domain if the BIND TO ACTIVE DIRECTORY section below for more details.



