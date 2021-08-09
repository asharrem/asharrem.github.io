#!/bin/bash

############################################
# This script is for post install of NxOS
# Called manually by /opt/nxos/intsall.sh
# set current Nx version
WebHostFiles="https://asharrem.github.io"
NxVer="4.2.0"
NxBuild="32840"
ServerName="NxOS-20LTS"
macaddy="0000"
NxVer="$NxVer.$NxBuild"

############################################

# Set Machine Hostname to Last 4 digits of first eth found
unset first_eth
first_eth=$(ls /sys/class/net | grep -m1 ^e)
if [[ ! -z "$first_eth" ]]; then
  macaddy=$(cat /sys/class/net/$first_eth/address | tr -d ':' | grep -o '....$')
fi
ServerName="${ServerName}-${macaddy}"
echo -e "\n Hostname = ${ServerName} ... \n"
sudo hostnamectl set-hostname $ServerName

# udpdate hosts with new ServerName
sudo sed -i 's/127.0.1.1	ubuntu/127.0.1.1	'"${ServerName}"'/g' /etc/hosts
echo -e "\n /etc/hosts updated ... \n"

# ToDo: Update icon theme - not working yet
#
# gsettings set org.gnome.desktop.interface icon-theme "gnome"
# google chrome passwords & background
#

# prepare apt & download dir
sudo apt update
echo -e "\n Changing to ~/Downloads ... \n"
cd ~/Downloads

# Download the latest NxOS Applications
read -p "Download & Install Nx Software (y/N)? [default=No]: " answer
case ${answer:0:1} in
  y|Y )

    # Install curl
    sudo apt install -y curl

    # Google Chrome - download & install if not downloaded
    file_name="google-chrome-stable_current_amd64.deb"
    if [ ! -f "$file_name" ]; then
      echo -e "\n Downloading ${file_name}... \n"
      wget "https://dl.google.com/linux/direct/$file_name" -q -P ~/Downloads
      echo -e "\n Installing Google Chrome ... \n"
      sudo gdebi -n google-chrome-stable_current_amd64.deb
      # Create Chrome Managed Policy
      echo -e "\n Disabling Chrome Passwords & Background Mode \n"
      sudo cat <<EOF > /etc/opt/chrome/policies/managed/nxos.json
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
      echo -e "\n"

      echo -e "\n Google Chrome Installed ... \n"
      echo -e "\n You can now use Cockpit or Diskmanager"
      echo -e " to mount storage before Nx Server Loads ... \n"
    fi

    # Nx server - download
    file_name="nxwitness-server-${NxVer}-linux64.deb"
    if [ ! -f "$file_name" ]; then
      echo -e "\n Downloading ${file_name}... \n"
      wget "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name" -q -P ~/Downloads
    fi

    # Nx client - download
    file_name="nxwitness-client-${NxVer}-linux64.deb"
    if [ ! -f "$file_name" ]; then
      echo -e "\n Downloading ${file_name}... \n"
      wget "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name" -q -P ~/Downloads
    fi

    # NX Client - Install
    echo -e "\n Installing Nx Client ... \n"
    # ugly hack - use --force-overwrite becuase of vms icon
    sudo dpkg --force-overwrite -i nxwitness-client-$NxVer-linux64.deb
    # sudo gdebi -n nxwitness-client-$NxVer-linux64.deb

    # NX Server Install
    echo -e "\n Installing Nx Server ... \n"
    sudo gdebi -n nxwitness-server-$NxVer-linux64.deb

    # Configure Nx Server to enumerate removeable Storage then restart service
    #sudo sed -i "$ a allowRemovableStorages=1" /opt/networkoptix/mediaserver/etc/mediaserver.conf
    #sudo service networkoptix-mediaserver restart

    #
    echo -e "\n Done Installing Nx software \n"

    # Enable AnalyticsDbStoragePermissions
    echo -e "\n Implementing Nx Server AnalyticsDbStoragePermissions \n"
    curl "http://admin:admin@127.0.0.1:7001/api/systemSettings?forceAnalyticsDbStoragePermissions=true"
    echo -e "\n"

    # /opt/google/chrome/google-chrome "http://admin:admin@127.0.0.1:7001/api/systemSettings?forceAnalyticsDbStoragePermissions=true" --incognito --noerrdialogs --disable-translate --no-first-run --fast --fast-start --disable-infobars --disable-features=TranslateUI --disk-cache-dir=/dev/null --password-store=basic >/dev/null
    ;;

  # No was selected
  * )
    echo -e "\n Skipping Nx Software \n"
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
    echo -e "\n *** Reboot Required *** \n"
    sleep 1
    ;;

    # No was selected
  * )
    echo -e "\n Skipping DS-WSELI PoE Drivers \n"
    ;;
esac


# Do system updates & cleanup
sudo apt -y upgrade
sudo apt autoremove
echo -e "\n *** Finished *** \n"
