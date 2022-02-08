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
NxFulVer="$NxMajVer.$NxBuild"
ServerName="NxOS-20LTS"
macaddy="0000"
SU_PASS="nxw1tness"
############################################

# run apt update
do
  TERM=ansi whiptail --title $TITLE --infobox "\n Running apt update..." 8 68
  sudo -S <<< $SU_PASS apt -qq update
  if [ $? != 0 ]; then
    # Ask password if default failed
    SU_PASS=$(whiptail --title $TITLE --passwordbox "\n Please enter password for $USER:" 8 68 3>&1 1>&2 2>&3)
    if [ $? != 0 ]; then
      # Exit on Cancel
      TERM=ansi whiptail --title $TITLE --infobox "\n apt update failed!" 8 68
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
TERM=ansi whiptail --title $TITLE --infobox "\n Changing Working Dir to ~/Downloads..." 8 68
cd ~/Downloads
sleep 0.5

# Display Checklist (whiptail)
CHOICES=$(whiptail --title $TITLE --separate-output --checklist "Choose options" 20 68 12 \
  "1" "Update Hostname to MAC address syntax" ON \
  "2" "Purge Nx & Google .deb's from Downloads Folder" ON \
  "3" "Download & Install Nx Chrome Browser" ON \
  "4" "Download & Install Nx Client" ON \
  "5" "Download & Install Nx Server" ON \
  "6" "Install Cockpit Advanced File Sharing (NAS)" OFF \
  "7" "Debug - Follow Boot process" OFF \
  "8" "Debug - use nomodeset" OFF \
  "9" "Install DS-WSELI-T2/8p PoE Drivers" OFF 3>&1 1>&2 2>&3)

if [ -z "$CHOICE" ]; then
  # user hit Cancel or unselected all options
  clear
  exit 1
else
  for CHOICE in $CHOICES; do
    case "$CHOICE" in
    "1")
      # Update Hostname
      TERM=ansi whiptail --title $TITLE --infobox "\n Updating Hostname to MAC address syntax..." 8 68
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
      TERM=ansi whiptail --title $TITLE --infobox "\n Hostname = ${ServerName}" 8 68
      sleep 0.5

      # udpdate hosts file with new ServerName
      # To Do: overwrite any existing ServerName
      # ie. not hardcoded to ubuntu
      sudo sed -i 's/127.0.1.1	ubuntu/127.0.1.1	'"${ServerName}"'/g' /etc/hosts
      TERM=ansi whiptail --title $TITLE --infobox "\n DNS Updated" 8 68
      sleep 0.5
      ;;
    "3")
      # Google Chrome - download & install if not already downloaded
      TERM=ansi whiptail --title $TITLE --infobox "\n Installing Google Chrome & Remote Desktop..." 8 68
      sleep 0.5
      file_name="google-chrome-stable_current_amd64.deb"
      if [ ! -f "$file_name" ]; then
        wget "https://dl.google.com/linux/direct/$file_name" -q -P ~/Downloads
        if [ $? != 0 ]; then
          # Download failed
          TERM=ansi whiptail --title $TITLE --infobox "\n Downloading $file_name failed!" 8 68
          sleep 3
          exit 1
        fi
        sudo -S <<< $SU_PASS gdebi -n $file_name
        if [ $? != 0 ]; then
          # Install failed
          TERM=ansi whiptail --title $TITLE --infobox "\n Installing $file_name failed!" 8 68
          sleep 3
          exit 1
        fi

        # WIP:Create Chrome Managed Policy
        TERM=ansi whiptail --title $TITLE --infobox "\n Changing Chrome Browser Policy..." 8 68
        sleep 0.5
        # create file first because tee will not
        file_name="/etc/opt/chrome/policies/managed/nxos.json"
        sudo mkdir -p "${file_name%/*}"
        # use tee to write to file because sudo cat <<EOF is BAD.
        sudo tee $file_name >/dev/null <<EOF
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
        TERM=ansi whiptail --title $TITLE --infobox "\n Chrome Browser Installed!" 8 68
        sleep 0.5
      else
        # google-chrome-stable_current_amd64.deb already in ~/Downloads
        TERM=ansi whiptail --title $TITLE --infobox "\n Assuming Chrome Browser Installed Already!" 8 68
        sleep 0.5
      fi

## YOU ARE HERE ##

      # Install Chrome Remote Desktop
      file_name="chrome-remote-desktop_current_amd64.deb"
      if [ ! -f "$file_name" ]; then

        wget "https://dl.google.com/linux/direct/$file_name" -q -P ~/Downloads

        sudo gdebi -n $file_name

        sudo usermod -a -G chrome-remote-desktop $USER

      fi

      ;;
    "3")
      echo "Option 3 was selected"
      ;;
    "4")
      echo "Option 4 was selected"
      ;;
    *)
      echo "Unsupported item $CHOICE!" >&2
      exit 1
      ;;
    esac
  done
fi

exit 0




# Download the latest NxOS Applications
read -p "Download & Install Nx & Google Software (Y/n)? [default=Yes]: " answer
case ${answer:0:1} in

    # No was selected
    n|N )
      echo -e "\n Skipping Nx Software \n"
      ;;

    # Yes (Enter) was selected
    * )



    # Nx server - download
    file_name="nxwitness-server-${NxMajVer}-linux64.deb"
    if [ ! -f "$file_name" ]; then
      echo -e "\n Downloading ${file_name}... \n"
      wget "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name" -q -P ~/Downloads
    fi

    # Nx client - download
    file_name="nxwitness-client-${NxMajVer}-linux64.deb"
    if [ ! -f "$file_name" ]; then
      echo -e "\n Downloading ${file_name}... \n"
      wget "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name" -q -P ~/Downloads
    fi

    # NX Client - Install
    echo -e "\n Installing Nx Client ... \n"
    sudo gdebi -n nxwitness-client-$NxMajVer-linux64.deb

    # NX Server Install
    echo -e "\n Installing Nx Server ... \n"
    sudo gdebi -n nxwitness-server-$NxMajVer-linux64.deb

    # Configure Nx Server to enumerate removeable Storage then restart service
    #sudo sed -i "$ a allowRemovableStorages=1" /opt/networkoptix/mediaserver/etc/mediaserver.conf
    #sudo service networkoptix-mediaserver restart

    #
    echo -e "\n Done Installing Nx software \n"

    # Enable AnalyticsDbStoragePermissions
    echo -e "\n Implementing Nx Server AnalyticsDbStoragePermissions fix \n"
    # use curl instead of chrome
    curl "http://admin:admin@127.0.0.1:7001/api/systemSettings?forceAnalyticsDbStoragePermissions=true"
    # use chrome instead of curl
    # /opt/google/chrome/google-chrome "http://admin:admin@127.0.0.1:7001/api/systemSettings?forceAnalyticsDbStoragePermissions=true" --incognito --noerrdialogs --disable-translate --no-first-run --fast --fast-start --disable-infobars --disable-features=TranslateUI --disk-cache-dir=/dev/null --password-store=basic >/dev/null
    echo -e "\n"
    ;;
esac

#Query user to Install DS-WSELI workarounds
read -p "Enable DS-WSELI workarounds (y/N)? [default=No]: " answer
case ${answer:0:1} in
  y|Y )

    # Download freeze_fix scripts
    wget -O freeze_fix.sh "$WebHostFiles/freeze_fix.sh" -q
    chmod +x freeze_fix.sh
    . freeze_fix.sh
    ;;

  # No was selected
  * )
    echo -e "\n Skipping DS-WSELI workarounds \n"
    ;;
esac

# Load DS-WSELI PoE Drivers?
read -p "Install DS-WSELI PoE Drivers (y/N)? [default=No]: " answer
case ${answer:0:1} in
  y|Y )

    # Download & Install Workstation PoE Drivers
    file_name="ds-wseli-poe.deb"
    if [ ! -f "$file_name" ]; then
      wget "$WebHostFiles/$file_name" -q -P ~/Downloads
    fi
    sudo gdebi -n ds-wseli-poe.deb
    ;;

    # No was selected
  * )
    echo -e "\n Skipping DS-WSELI PoE Drivers \n"
    ;;
esac

# Install Cockpit Advanced File Management & Sharing?
read -p "Install Cockpit Advanced File Management & Sharing? [default=No]: " answer
case ${answer:0:1} in
  y|Y )

    # Download & Install Cockpit Advanced
    # Needs GPG to add repos
    sudo apt -y install gpg
    # advanced file support by 45drives
    curl -sSL https://repo.45drives.com/setup | sudo bash
    sudo apt -y install \
    crudini \
    cockpit-file-sharing \
    cockpit-navigator \
    cockpit \
    cockpit-bridge \
    cockpit-networkmanager \
    cockpit-packagekit \
    cockpit-storaged \
    cockpit-system \
    cockpit-ws \
    gvfs-backends \
    gvfs-fuse

    conf=/etc/samba/smb.conf
    # remove leading spaces & tabs so crudini does not fail
    sudo sed -i.bak 's/^[ \t]*//' $conf
    # add key pair to samba
    sudo crudini --set $conf global include registry
    ;;

  # No was selected
  * )
      echo -e "\n Skipping Cockpit Advanced \n"
    ;;

esac

# Do system updates & cleanup
sudo apt -y upgrade
sudo apt autoremove
echo -e "\n *** Finished *** \n"
echo -e "\n *** Reboot Required *** \n"
