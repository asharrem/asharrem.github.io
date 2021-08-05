#!/bin/bash
#########################################
WebHostFiles="https://asharrem.github.io"
# Download & run nxos install script
#

# wait a little in case network is not ready
echo -e "\n Downloading NxOS updater script ... \n"
echo -e "\n Use Disk Management to setup disks before Installing Nx Server \n"
echo -e "\n waiting 10 seconds for network ... \n"
for i in {10..1};do echo -n ".$i" && sleep 1; done

# change working directory
cd ~/Downloads

# wget -O allows file overwritting
wget -q -O update-nxos.sh "$WebHostFiles/update-nxos.sh"

# check if download succeeded. Exit on NO
if [[ ! -f update-nxos.sh ]]; then
  echo -e "\n Failed to download NxOS updater script"
  echo -e " Please check internet & run wizard again"
  echo -e " by either log off/on or the main menu. \n"
  exit
fi

# Script must have downloaded so let's run it
chmod +x update-nxos.sh
. update-nxos.sh

# remove new_install flag
echo -e "\n Removing new_install flag from /opt/nxos... \n"
if [[ -f /opt/nxos/new_install ]]; then
  sudo rm /opt/nxos/new_install
fi
echo -e "\n Done! \n"
