# Jamf DEPNotify

Use these scripts to assist with deployment and execution of DEPNotify in a Jamf MDM environment.

## Scripts

- `jamf-dep-notify-post-install.sh` - Use as the post-install script when repackaging the DEPNotify app for deployment.
- `jamf-dep-notify-start-enrollment.sh` - Use as the enrollment script in your Jamf enrollment Policy. This should be policy executed by the DEPNotify post-install script.
- `jamf-dep-notify-cleanup.sh` - Use this script in a policy called by the `jamf-dep-notiy-start-enrollment` policy. Removes the DEPNotify application and all of its dependencies.


## Jamf DEPNotify Re-Package

This example uses [Packages](http://s.sudre.free.fr/Software/Packages/about.html) to repackage the DEPNotify app.

### Project Tab

Give the project a **Name**, set the path to **Relative to Project**, and select a **Reference Folder** (The place where you want to store the project.)

Signing the package is necessary. As a part of this process the package is uploaded to Jamf and added to a Prestage Enrollment profile. The package needs to be signed inorder to use it in a Jamf Prestage Enrollment profile.

![](Screenshots/packages_project_tab.png)


### Settings Tab

Set the **identifier** and a version number on the Settings tab if you wish. I like to set the version number to the version of the original application that I am working with. In this case DENotify is on 1.1.5.

![](Screenshots/packages_settings_tab.png)


### Scripts Tab

On the Scripts tab drag the `jamf-dep-notify-post-install.sh` script into the square. Make sure that the **R** for Relative to Project opation is selected underneath the script.

![](Screenshots/packages_scripts_tab_01.png)

Drag the original [DEPNotify app](https://gitlab.com/Mactroll/DEPNotify) installer into the **Additional Resources** area, and make sure that the **Reference** is set to **Relative to Project**.

![](Screenshots/packages_scripts_tab_02.png)


### Build the Package

Once everything is in the new package press **Command + S** to save your work. Then, press **Command + B** to build the package.


### Upload the Package to Jamf

Once the package is created upload it to Jamf. Then add the package to your Pre-Stage Enrollment profile.

![](Screenshots/prestage_enrollment_package.png)


## Jamf Policies

**NOTE:** Make sure to upload `jamf-dep-notify-start-enrollment.sh` and `jamf-dep-notify-cleanup.sh` to Jamf as Scripts before creating the policies.

### Jamf DEPNotify Start Enrollment

**General settings tab**

![](Screenshots/start_depnotify_policy_general.png)

**Scripts payload tab**

![](Screenshots/start_depnotify_policy_script.png)

**Policy Scope**

You can scope the policy to **All Computers/All Users** or create a Smart Group with the following criteria and scope this policy to that smart group.

_Smart Group_

![](Screenshots/smart_group_has_jamf_pppc_profile.png)

_Scope_

![](Screenshots/start_depnotify_policy_scope.png)


### Jamf DEPNotify Cleanup

**General settings tab**

![](Screenshots/dep_notify_cleanup_general_settings.png)

**Scripts payload tab**

![](Screenshots/dep_notify_cleanup_script_payload.png)
