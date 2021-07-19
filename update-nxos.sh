#!/bin/bash
############################################
# This script is for post install of NxOS
# Called manually by /opt/nxos/intsall.sh
# set current Nx version
NxVer="4.2.0.32840"
NxBuild="32840"
ServerName="NxOS-20LTS"
############################################

# Set Machine Hostname to Last 4 digits of enp1s0
if [[ -e /sys/class/net/enp1s0/address ]]; then
  macaddy=$(cat /sys/class/net/enp1s0/address | tr -d ':' | grep -o '....$')
elif [[ -e /sys/class/net/enp2s0/address ]]; then
  macaddy=$(cat /sys/class/net/enp2s0/address | tr -d ':' | grep -o '....$')
else
    macaddy="0000"
fi
ServerName="${ServerName}-${macaddy}"
echo -e "\n Hostname = ${ServerName} ... \n"
sudo hostnamectl set-hostname $ServerName

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

# Load PoE Drivers?
read -p "Download & Install Nx Software (y/n)? [default=No]: " answer
case ${answer:0:1} in
  y|Y )
    # Nx server
    file_name="nxwitness-server-${NxVer}-linux64.deb"
    if [ ! -f "$file_name" ]; then
      echo -e "\n Downloading ${file_name}... \n"
      wget "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name" -q -P ~/Downloads
    fi
    # Nx client
    file_name="nxwitness-client-${NxVer}-linux64.deb"
    if [ ! -f "$file_name" ]; then
      echo -e "\n Downloading ${file_name}... \n"
      wget "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name" -q -P ~/Downloads
    fi
    # Google Chrome
    file_name="google-chrome-stable_current_amd64.deb"
    if [ ! -f "$file_name" ]; then
      echo -e "\n Downloading ${file_name}... \n"
      wget "https://dl.google.com/linux/direct/$file_name" -q -P ~/Downloads
    fi
    # use ./ instead of ~/Downloads as google would not install?
    # Install NX Server
    echo -e "\n Installing Nx Server ... \n"
    sudo gdebi -n nxwitness-server-$NxVer-linux64.deb
    # Configure Nx Server to enumerate removeable Storage then restart service
    #sudo sed -i "$ a allowRemovableStorages=1" /opt/networkoptix/mediaserver/etc/mediaserver.conf
    #sudo service networkoptix-mediaserver restart
    # Install NX Client
    echo -e "\n Installing Nx Client ... \n"
    sudo gdebi -n nxwitness-client-$NxVer-linux64.deb
    #Install Google Chrome
    echo -e "\n Installing Google Chrome ... \n"
    sudo gdebi -n google-chrome-stable_current_amd64.deb
    # ToDo: do I need some sort of wait command for interactive gdebi?
    #
    echo -e "\n Done Installing Nx software \n"
    ;;
  * )
    echo -e "\n Skipping Nx Software \n"
    ;;
esac

#Query user to Install DS-WSELI intel grub hacks
read -p "Install DS-WSELI Freeze workarounds (y/n)? [default=No]: " answer
case ${answer:0:1} in
  y|Y )
    # sudo rm freeze_fix.sh
    wget -q -N http://support.nfs.co.nz/downloads/freeze_fix.sh
    chmod +x freeze_fix.sh
    . freeze_fix.sh
    ;;
  * )
    echo -e "\n Skipping DS-WSELI Freeze workarounds \n"
    ;;
esac

# Load PoE Drivers?
read -p "Install DS-WSELI PoE Drivers (y/n)? [default=No]: " answer
case ${answer:0:1} in
  y|Y )
    # Install Workstation PoE Drivers
    file_name="ds-wseli-poe.deb"
    if [ ! -f "$file_name" ]; then
      wget "http://support.nfs.co.nz/downloads/$file_name" -q -P ~/Downloads
    fi
    sudo gdebi -n ds-wseli-poe.deb
    echo -e "\n *** Reboot Required *** \n"
    sleep 1
    ;;
  * )
    echo -e "\n Skipping DS-WSELI PoE Drivers \n"
    ;;
esac

# Do system updates & cleanup
sudo apt -y upgrade
sudo apt autoremove
echo -e "\n *** Finished *** \n"
