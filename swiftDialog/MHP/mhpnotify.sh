#!/bin/bash

# JAMF Pro-Parameter
hostname="${2}"  # Der Hostname, von JAMF übergeben
logPath="${4}"  # Log Path
dialogMode="${5}"    # Modus für Benachrichtigungen: "MINIPOPUP", "SYSTEM", "POPUP"
title="${6}" 
message="${7}"
icon="${8}"
position="${9}"
blurscreen="${10}"
jamfAction="${11}"

# Pfad zu swiftDialog
swiftDialog="/Library/Application Support/Dialog/Dialog.app/Contents/MacOS/Dialog"

# Log-Funktion
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "${logPath}"
}

checkSudoRights() {
    if [ "$(/usr/bin/id -u)" != "0" ]; then
        echo "Script must be run as root"
        exit 1
    fi
}

checkSwiftDialog() {
    if [ ! -e "${swiftDialog}" ]; then
        echo "Swift Dialog is not installed; exit script!"
        log "Swift Dialog is not installed; exit script!"
        exit 1
    fi
}

showNotification() {
    "${swiftDialog}" \
        --notification \
        --title "${title}" \
        --message "${message}" 
    echo "System notification is shown: $title - $message"
    log "System notification is shown: $title - $message "
}

showMessageWindowMini() {
    if [ "$blurscreen" = "TRUE" ]; then
     "${swiftDialog}" \
        --mini \
        --title "${title}" \
        --message "${message}" \
        --icon "${icon}" \
        --ontop \
        --position "${position}" \
        --blurscreen
    else 
     "${swiftDialog}" \
        --mini \
        --title "${title}" \
        --message "${message}" \
        --icon "${icon}" \
        --ontop \
        --position "${position}"
    fi
    echo "Mini message window is shown: $title - $message"
    log "Mini message window is shown: $title - $message "
}

showMessageWindow() {
    if [ "$blurscreen" = "TRUE" ]; then
     "${swiftDialog}" \
        --title "${title}" \
        --bannerimage "/Library/JAMF/banner.png" \
        --bannerheight 100 \
        --height 50% \
        --messagefont size=14 \
        --message "${message}" \
        --icon "${icon}" \
        --iconsize 130 \
        --infobuttontext "Request Support?" \
        --infobuttonaction "https://service.mhp.com/" \
        --ontop \
        --position "${position}" \
        --blurscreen
    else 
     "${swiftDialog}" \
        --title "${title}" \
        --bannerimage "/Library/JAMF/banner.png" \
        --bannerheight 100 \
        --height 50% \
        --messagefont size=14 \
        --message "${message}" \
        --icon "${icon}" \
        --iconsize 130 \
        --infobuttontext "Request Support?" \
        --infobuttonaction "https://service.mhp.com/" \
        --ontop \
        --position "${position}"
    fi
    echo "Message window is shown: $title - $message"
    log "Message window is shown: $title - $message "
}

checkSudoRights
checkSwiftDialog

if [ "$dialogMode" = "MINIPOPUP" ]; then 
    showMessageWindowMini
fi

if [ "$dialogMode" = "POPUP" ]; then 
    showMessageWindow
fi

if [ "$dialogMode" = "SYSTEM" ]; then 
    showNotification
fi

if [ ! -z "$jamfAction" ]; then      
    sudo jamf policy -event "$jamfAction"
fi

exit 0