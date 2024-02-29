//swiftDialog - Open Source Admin Rights for macOS

//Usually we send a notification or interact with the user using Jamf. 

//- The built in solution for notifications is Jamf Notify.

//swiftDialog is a terminal based notification. You can create notifications via terminal commands.

//Used for messages/notifications such as “Please connect to the VPN etc.” 

//swiftDialog is already installed on every macOS device in MHP. 

//Deployed via Installomator

//demoter.sh script - used for admin rights/privileges. 

//Bash scripts used for Mac. 

//SAP Admin is written message/notification is done via switftDialog.

//Update Notification - Update Available - Configure it however you want, it can be movable or fixed. 

//You can configure the swiftDialog script to run before the application is installed by uploading the script in JAMF. 

//You can also run it with a custom trigger policy.   Sudo Jamf policy -event checkDeviceCompliance

sudo jamf policy -event checkDeviceCompliance

//Dialog - the command to start and parameters that you can use

/usr/local/bin/dialog --title “Hello world” —message “This is a new message sent on your device” 

/usr/local/bin/dialog --title “Hello world” —message “This is a new message sent on your device” —icon /Applications/Edge.app

/Library/JAMF/banner.png

//--infobuttontext "Request Support?" \
//--infobuttonaction "https://service.mhp.com/" \

/usr/local/bin/dialog  --title "Hello there" --message "This is a new message" --bannerimage "/Library/JAMF/banner.png" --button1text "Contune" --button2text "Cancel"  --infobuttontext "Request Support?" --infobuttonaction "https://service.mhp.com/" 

/usr/local/bin/dialog  --title "Hello there" --message "This is a new message" --bannerimage "/Library/JAMF/banner.png" --button1text "Contune" --button2text "Cancel" —notification —subtle “This is subtle” --icon “caution” 

