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
echo "Start F1" 
export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# set the path to the desktop image file here
picturepath="/Library/Desktop/Images/MHPtest.jpg"

  # Setting the log path
logPath="/Users/petru-darius.tatu/testlog/setdesktop.log"

echo $logPath
# Log-Funktion
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "${logPath}"
}

log "verify if image exists"
# verify the image exists
if [ ! -f "$picturepath" ]; then
    echo "no file at $picturepath, exiting"
    exit 1
fi

echo "verify desktoppr installed"
# verify that desktoppr is installed
desktoppr="/usr/local/bin/desktoppr"
if [ ! -x "$desktoppr" ]; then
    echo "cannot find desktoppr at $desktoppr, exiting"
    exit 1
fi

# get the current user
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
echo "loggedUsed= $loggedInUser"
# test if a user is logged in
if [ -n "$loggedInUser" ]; then
    # set the desktop for the user
    echo "user logged in"
    uid=$(id -u "$loggedInUser")
    launchctl asuser "$uid" sudo -u "$loggedInUser" "$desktoppr" "$picturepath"
else
    echo "no user logged in, no desktop set"
    log "Log is written: $picturepath - $loggedInUser"
fi

# Function to run a command as the current logged-in user
runAsUser() {  
    if [ "$loggedInUser" != "loginwindow" ]; then
        sudo -u "$loggedInUser" launchctl asuser "$uid" "$@"
    else
        log "No user logged in, cannot run command"
        exit 1
    fi
}

# Set the desktop wallpaper
runAsUser "$desktoppr" "$picturepath"

# Log completion of script
log "Finished setting desktop wallpaper for user $loggedInUser"

exit 0 