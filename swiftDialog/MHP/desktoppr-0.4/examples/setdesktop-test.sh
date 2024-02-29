#!/bin/sh

 #JAMF Pro-Parameter
hostname="${2}"  # Der Hostname, von JAMF übergeben
logPath="${4}"  # Log Path
picturepath="${5}" #Defines the wallpaper path
desktoppr="${6}" #Checks if desktoppr is installed
loggedInUser="${7}" #Sets the login user parameter
uid="${8}" #checks the logged in user
 

##
## sets the desktop using `desktoppr`
##
echo "1. Start Desktop Check F1 VRUM VRUM" 
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# set the path to the desktop image file here
picturepath="/Library/Desktop/Images/MHPtest.jpg"

  # Setting the log path
logPath="/var/log/setdesktop.log"

echo $logPath
# Log-Funktion
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "${logPath}"
}

log "1. Verify if image exists"
# verify if image exists
if [ ! -f "$picturepath" ]; then
echo "no file at $picturepath, existing"
exit 1
fi
echo $picturepath


log "2. Verify desktoppr installed"
echo "verify desktoppr installed"

# verify desktoppr path install
desktoppr="/usr/local/bin/desktoppr"
if [ ! -x "$desktoppr" ]; then
    echo "Unable to find desktoppr at $desktoppr, exiting"
    exit 1
fi
echo $desktoppr

log "3. Get the current user"
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && !/loginwindow/ {print $3}' )
echo $loggedInUser
log "loggedInUser="$loggedInUser


log "4. Set the Desktop and Test user loggon"
if [ -n "$loggedInUser" ]; then
   #Setting the desktop wallpaper
echo "User Logged In"
uid=$(id -u "$loggedInUser")
launchctl asuser "$uid" sudo -u "$loggedInUser" "$desktoppr" "$picturepath" 
else
echo "No user logged in, not setting wall"
log "No user is logged in, not setting wallpaper"
fi 

log "5. Function to run as the current user"
echo "5. Function to run as the current user"

runAsUser() {
    if [ "$loggedInUser" != "loginwindow" ]; then
        sudo -u "$loggedInUser" launchctl asuser "$uid" "$@"
        log "5.1 inside runAsUser"
    else
        log "No user logged in, cannot run" 
        exit 1
    fi
}        

log "6. Setting the wallpaper" 
echo "6. Setting the wallpaper" 
#Setting wallpaper
#runAsUser "$desktoppr" "$picturepath" 

# Log completion of script
log "7. Finished setting desktop wallpaper for user"
echo "7. Finished setting desktop wallpaper for user"

exit 0 