#!/bin/bash
#
# check for internet connectivity while displaying progress bar (uses Whiptail)
# Return IPv4_connected 1 false || 0 true - follows exit status sytax (>0 is error)
# uses PING method and supports FQDN (recommended to confirm DNS working)
#
function check_internet () {
    local counter=0
    local IPv4_connected=1
    local check_address=$1
    local fallback_address="google.com"
    if [[ -z "$check_address" ]]; then check_address=$fallback_address; fi
    while [ $IPv4_connected != 0 ]
    do
        while [ $counter -le 100 ]
        do
            if ping -q -c 1 -W 1 $check_address >/dev/null; then
                # prepare to exit loop
                counter=100
                IPv4_connected=0
            fi 
            # Display Progress Bar - This method supports CTRL + C
            export TERM=linux
            echo $counter | whiptail --gauge "\n Checking Internet connectivity to: $check_address" 8 68 0
            (( counter += 5 ))
            sleep 0.5
        done
        # Display Retry on "No Internet"
        if [ $IPv4_connected != 0 ]; then
            if whiptail --yesno "\n No Route to the Internet! Do you want to retry?" 8 68; then
                counter=0
            else
                break
            fi
        fi
    done
    return $IPv4_connected
}

check_internet google.com
echo Connected = $?