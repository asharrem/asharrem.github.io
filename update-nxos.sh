#!/bin/bash

############################################
# This script is for post install of NxOS
# Automatically run at fist boot or
# manually by /opt/nxos/intsall.sh
############################################
WebAddress="asharrem.github.io"
WebHostFiles="https://$WebAddress"
TITLE="NxOS Installation Wizard"
# set current Nx version & Hostname Prefix
NxMajVer="4.2.0"
NxBuild="32840"
ServerName="NxOS-20LTS"
macaddy="0000"
SU_PASS="nxw1tness"
############################################

NxFulVer="$NxMajVer.$NxBuild"

# run apt update
while true
do
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Running apt update..." 8 68
  sudo -S <<< $SU_PASS apt -qq update
  if [ $? != 0 ]; then
    # Ask password if default failed
    SU_PASS=$(whiptail --title "$TITLE" --passwordbox "\n Please enter password for $USER:" 8 68 3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
      # Exit on Cancel
      TERM=ansi whiptail --title "$TITLE" --infobox "\n apt update failed!" 8 68
      sleep 3
      exit 1
    fi
  else
    # Break loop on success
    break
  fi
done

# Install curl. Needed to update nx advanced flags later
sudo -S <<< $SU_PASS apt -qq install -y curl

# change working directory
TERM=ansi whiptail --title "$TITLE" --infobox "\n Changing Working Dir to ~/Downloads..." 8 68
cd ~/Downloads
sleep 0.5

# Display Checklist (whiptail)
CHOICES=$(whiptail --title "$TITLE" --separate-output --checklist "Choose options" 20 68 12 \
  "1" "Update Hostname to MAC address syntax" ON \
  "2" "Purge Nx & Google .deb's from Downloads Folder" OFF \
  "3" "Download & Install Nx Chrome Browser" ON \
  "4" "Download & Install Nx Client" ON \
  "5" "Download & Install Nx Server" ON \
  "6" "Install Cockpit Advanced File Sharing (NAS)" OFF \
  "7" "Debug - Follow Boot process" OFF \
  "8" "Debug - use nomodeset" OFF \
  "9" "Install DS-WSELI-T2/8p PoE Drivers" OFF 3>&1 1>&2 2>&3)

if [ -z "$CHOICES" ]; then
  # user hit Cancel or unselected all options
  clear
  exit 1
else
  for CHOICE in $CHOICES; do
    case $CHOICE in
    1)
      # Update Hostname
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Updating Hostname to MAC address syntax..." 8 68
      sleep 0.5
      # Set Machine Hostname to Last 4 digits of first eth found
      # reset so we can test for null
      unset first_eth
      first_eth=$(ls /sys/class/net | grep -m1 ^e)
      if [[ ! -z "$first_eth" ]]; then
        macaddy=$(cat /sys/class/net/$first_eth/address | tr -d ':' | grep -o '....$')
      fi
      ServerName="${ServerName}-${macaddy}"
      sudo hostnamectl set-hostname $ServerName
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Hostname = ${ServerName}" 8 68
      sleep 0.5

      # udpdate hosts file with new ServerName
      # To Do: overwrite any existing ServerName
      # ie. not hardcoded to ubuntu
      sudo sed -i 's/127.0.1.1	ubuntu/127.0.1.1	'"${ServerName}"'/g' /etc/hosts
      TERM=ansi whiptail --title "$TITLE" --infobox "\n DNS Updated" 8 68
      sleep 0.5
      ;;
    2)
      file_name_list="chrome-remote-desktop_current_amd64.deb google-chrome-stable_current_amd64.deb networkoptix-*.deb"
      for file_name in $file_name_list
      do
        TERM=ansi whiptail --title "$TITLE" --infobox "\n Removing $file_name ..." 8 68
        sleep 0.5
        rm $file_name > /dev/null 2>&1
      done
      ;;
    3 | 4 | 5)
    # Download files if they don't exist, then install them
      file_name_list="google-chrome-stable_current_amd64.deb chrome-remote-desktop_current_amd64.deb nxwitness-server-${NxFulVer}-linux64.deb nxwitness-client-${NxFulVer}-linux64.deb"
      for file_name in $file_name_list
      do
        TERM=ansi whiptail --title "$TITLE" --infobox "\n Downloading ..." 8 68
        sleep 0.5
        if [ ! -f "$file_name" ]; then
          # Download files
          if [[ $file_name = *(chrome) && $CHOICE = 3 ]]; then
            wget "https://dl.google.com/linux/direct/$file_name" -q
          elif [[ $file_name = *(nxwitness-client) && $CHOICE = 4 || $file_name = *(nxwitness-server) && $CHOICE = 5 ]]; then
            wget "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name" -q
          else
            # Unknown Download URL
            TERM=ansi whiptail --title "$TITLE" --infobox "\n Unknown URL for: $file_name " 8 68
            sleep 3
            exit 1
          fi
          if [ $? != 0 ]; then
            # Download failed
            TERM=ansi whiptail --title "$TITLE" --infobox "\n Downloading $file_name failed!" 8 68
            sleep 3
            exit 1
          fi
        fi
        # Install selected files
        if [[ $file_name = *(chrome) && $CHOICE = 3 || $file_name = *(nxwitness-client) && $CHOICE = 4 || $file_name = *(nxwitness-server) && $CHOICE = 5 ]]; then
          sudo -S <<< $SU_PASS gdebi -n $file_name
          if [ $? != 0 ]; then
            # Install failed
            TERM=ansi whiptail --title "$TITLE" --infobox "\n Installing $file_name failed!" 8 68
            sleep 3
            exit 1
          fi
          TERM=ansi whiptail --title "$TITLE" --infobox "\n $file_name Installed!" 8 68
          sleep 0.5
        fi
      done
      
      #Do Post Install actions
      #
      # Chrome Remote Desktop
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Adding $USER to Chrome Remote Desktop Group..." 8 68
      sleep 0.5
      sudo -S <<< $SU_PASS usermod -a -G chrome-remote-desktop $USER

      # WIP:Create Chrome Managed Policy
      file_name="/etc/opt/chrome/policies/managed/nxos.json"
      if [ ! -f "$file_name" && $CHOICE = 3 ]; then
        TERM=ansi whiptail --title "$TITLE" --infobox "\n Setting Chrome Browser Policy..." 8 68
        sleep 0.5
        # create file first because tee will not
        sudo -S <<< $SU_PASS mkdir -p "${file_name%/*}"
        # use tee to write to file because sudo cat <<EOF is BAD.
        sudo -S <<< $SU_PASS tee $file_name >/dev/null <<EOF
{
  "distribution": {
    "suppress_first_run_bubble": true,
    "make_chrome_default": true,
    "make_chrome_default_for_user": true,
    "suppress_first_run_default_browser_prompt": true,
  },
  "PasswordManagerEnabled": false,
  "BackgroundModeEnabled": false,
}
EOF
      fi
      
      if [ $CHOICE = 5 ]; then
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Applying Nx Stoarge permissions Fix..." 8 68
      sleep 0.5
        # Enable Nx AnalyticsDbStoragePermissions
        echo -e "\n Implementing Nx Server AnalyticsDbStoragePermissions fix \n"
        curl "http://admin:admin@127.0.0.1:7001/api/systemSettings?forceAnalyticsDbStoragePermissions=true"
      fi
      ;;

## YOU ARE HERE ##

    "6")
      echo "Option 6 was selected"
      ;;

    *)
      echo "Unsupported item $CHOICE!" >&2
      exit 1
      ;;
    esac
  done
fi

exit 0


# #Query user to Install DS-WSELI workarounds
# read -p "Enable DS-WSELI workarounds (y/N)? [default=No]: " answer
# case ${answer:0:1} in
#   y|Y )

#     # Download freeze_fix scripts
#     wget -O freeze_fix.sh "$WebHostFiles/freeze_fix.sh" -q
#     chmod +x freeze_fix.sh
#     . freeze_fix.sh
#     ;;

#   # No was selected
#   * )
#     echo -e "\n Skipping DS-WSELI workarounds \n"
#     ;;
# esac

# # Load DS-WSELI PoE Drivers?
# read -p "Install DS-WSELI PoE Drivers (y/N)? [default=No]: " answer
# case ${answer:0:1} in
#   y|Y )

#     # Download & Install Workstation PoE Drivers
#     file_name="ds-wseli-poe.deb"
#     if [ ! -f "$file_name" ]; then
#       wget "$WebHostFiles/$file_name" -q -P ~/Downloads
#     fi
#     sudo gdebi -n ds-wseli-poe.deb
#     ;;

#     # No was selected
#   * )
#     echo -e "\n Skipping DS-WSELI PoE Drivers \n"
#     ;;
# esac

# # Install Cockpit Advanced File Management & Sharing?
# read -p "Install Cockpit Advanced File Management & Sharing? [default=No]: " answer
# case ${answer:0:1} in
#   y|Y )

#     # Download & Install Cockpit Advanced
#     # Needs GPG to add repos
#     sudo apt -y install gpg
#     # advanced file support by 45drives
#     curl -sSL https://repo.45drives.com/setup | sudo bash
#     sudo apt -y install \
#     crudini \
#     cockpit-file-sharing \
#     cockpit-navigator \
#     cockpit \
#     cockpit-bridge \
#     cockpit-networkmanager \
#     cockpit-packagekit \
#     cockpit-storaged \
#     cockpit-system \
#     cockpit-ws \
#     gvfs-backends \
#     gvfs-fuse

#     conf=/etc/samba/smb.conf
#     # remove leading spaces & tabs so crudini does not fail
#     sudo sed -i.bak 's/^[ \t]*//' $conf
#     # add key pair to samba
#     sudo crudini --set $conf global include registry
#     ;;

#   # No was selected
#   * )
#       echo -e "\n Skipping Cockpit Advanced \n"
#     ;;

# esac

# # Do system updates & cleanup
# sudo apt -y upgrade
# sudo apt autoremove
# echo -e "\n *** Finished *** \n"
# echo -e "\n *** Reboot Required *** \n"
