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
Working_Dir="$HOME/Downloads"
############################################

NxFulVer="$NxMajVer.$NxBuild"

function download {
  # wget url($1)
  file_name="$(basename -- "$1")"
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Downloading $file_name..." 19 68
  sleep 0.5
  # only download & overwrite newer file - quietly
  if ! wget -N -q --show-progress "$1"; then
    # Download failed
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Downloading $file_name failed!" 19 68
    sleep 3
    return 1
  fi
  return 0
}

function install_deb {
  file_name="$(basename -- "$1")"
  TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Installing $file_name..." 19 68
  sleep 0.5
  # Install non-interactive & quiet
  clear
  if ! sudo gdebi -n -q -o quiet=1 -o dpkg::progress-fancy="1" "$file_name"; then
    # Install failed
    TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Installing $file_name failed!" 19 68
    sleep 3
    return 1
  fi
  TERM=ansi whiptail --title "$TITLE" --infobox "\n ...Installed $file_name" 19 68
  sleep 0.5
  return 0
}

# 
while true
do
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Testing sudo...please wait for next screen" 19 68
  if ! sudo -S -v <<< "$SU_PASS"; then
    # Ask password if default failed
    if ! SU_PASS=$(whiptail --title "$TITLE" --passwordbox "\n Please enter password for $USER:" 19 68 3>&1 1>&2 2>&3); then
      # Exit on Cancel
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Exiting Wizard!" 19 68
      sleep 3
      exit 1
    fi
  else
    # Break loop on success
    break
  fi
done

# run apt update
TERM=ansi whiptail --title "$TITLE" --infobox "\n Running apt update..." 19 68
sudo apt -y -q -o=dpkg::progress-fancy="1" update

# Install curl. Needed to update nx advanced flags later
TERM=ansi whiptail --title "$TITLE" --infobox "\n Installing Curl..." 19 68
sudo apt -y -q -o=dpkg::progress-fancy="1" install curl

# change working directory
TERM=ansi whiptail --title "$TITLE" --infobox "\n Changing Working Dir to $Working_Dir..." 19 68
cd "$Working_Dir" || exit 1
sleep 0.5

# Display Checklist (whiptail)
CHOICES=$(whiptail --title "$TITLE" --separate-output --checklist "Choose options" 19 68 13 \
  "01" "Install DS-WSELI-T2/8p PoE Drivers" OFF \
  "02" "Update Hostname to MAC address syntax" ON \
  "03" "Purge Nx & Google .deb's from Downloads Folder" OFF \
  "04" "Download & Install Google Chrome Browser" ON \
  "05" "Download & Install Latest Stable Nx Witness Client" ON \
  "06" "Download & Install Latest Stable Nx Witness Server" ON \
  "07" "Install Cockpit Advanced File Sharing (NAS)" OFF \
  "08" "Debug - Follow Boot process" OFF \
  "09" "Debug - Freeze Fix" OFF \
  "10" "Update NxOS Defaults (Resets First Boot Flag)" OFF \
  "11" "Un-Install Nx Witness Server & Client" OFF \
  "12" "Install a specific Nx Witness Client Build" OFF \
  "13" "Run Upadtes" ON 3>&1 1>&2 2>&3)

for CHOICE in $CHOICES; do
  case $CHOICE in
  "01")
    # Download & Install Workstation PoE Drivers
    file_name="ds-wseli-poe.deb"
    if ! download "$WebHostFiles/$file_name"; then
      continue
    fi
    if ! install_deb "$file_name"; then
      continue
    fi
  ;;
  "02")
    # Update Hostname
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Updating Hostname to MAC address syntax..." 19 68
    sleep 0.5
    # Set Machine Hostname to Last 4 digits of first eth found
    # reset so we can test for null
    unset first_eth
      # shellcheck disable=SC2010
    first_eth=$(ls /sys/class/net | grep -m1 ^e)
    if [[ -n "$first_eth" ]]; then
      # shellcheck disable=SC2002
      macaddy=$(cat /sys/class/net/"$first_eth"/address | tr -d ':' | grep -o '....$')
    fi
    ServerName="${ServerName}-${macaddy}"
    sudo hostnamectl set-hostname "$ServerName"
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Hostname = ${ServerName}" 19 68
    sleep 0.5

    # udpdate hosts file with new ServerName
    sudo sed -i 's/127.0.1.1	'"${HOSTNAME}"'/127.0.1.1	'"${ServerName}"'/g' /etc/hosts
    TERM=ansi whiptail --title "$TITLE" --infobox "\n DNS Updated" 19 68
    sleep 0.5
  ;;
  "03")
    file_name_list="chrome-remote-desktop_current_amd64.deb google-chrome-stable_current_amd64.deb nxwitness-*.deb"
    for file_name in $file_name_list
    do
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Removing $file_name ..." 19 68
      sleep 0.5
      rm "$file_name" > /dev/null 2>&1
    done
  ;;
  "04")
    # Download Chrome files if they don't exist, then install them
    file_name_list="google-chrome-stable_current_amd64.deb chrome-remote-desktop_current_amd64.deb"
    for file_name in $file_name_list
    do
      if ! download "https://dl.google.com/linux/direct/$file_name"; then
        continue
      fi
      if ! install_deb "$file_name"; then
        continue
      fi
    done
    #Do Post Install actions
    #
    # No Longer needed?? - Add user to Chrome Remote Desktop user Group
    # TERM=ansi whiptail --title "$TITLE" --infobox "\n Adding $USER to Chrome Remote Desktop Group..." 19 68
    # sleep 0.5
    # sudo usermod -a -G chrome-remote-desktop "$USER"

    # Create Chrome Browser Managed Policy
    file_name="/etc/opt/chrome/policies/managed/nxos.json"
    if [ ! -f "$file_name" ]; then
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Setting Chrome Browser Policy..." 19 68
      sleep 0.5
      # create file first because tee will not
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
    fi
  ;;
  "05")
    # Download & Install Nx Client
    file_name="nxwitness-client-${NxFulVer}-linux64.deb"
    if ! download "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name"; then
      # Retry with alternate syntax
      file_name="nxwitness-client-${NxFulVer}-linux_x64.deb"
      if ! download "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name"; then
        continue
      fi
    fi
    if ! install_deb "$file_name"; then
      continue
    fi
  ;;
  "06")
    # Download & Install Nx Server
    file_name="nxwitness-server-${NxFulVer}-linux64.deb"
    if ! download "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name"; then
      # Retry with alternate syntax
      file_name="nxwitness-server-${NxFulVer}-linux_x64.deb"
      if ! download "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name"; then
        continue
      fi
    fi
    if ! install_deb "$file_name"; then
      continue
    fi
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Applying Nx Storage permissions Fix..." 19 68
    sleep 0.5
    # Enable Nx AnalyticsDbStoragePermissions
    if ! curl "http://admin:admin@127.0.0.1:7001/api/systemSettings?forceAnalyticsDbStoragePermissions=true"; then
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Failed to apply Nx Storage permissions Fix!" 19 68
      sleep 3
    fi
  ;;
  "07")
    # Download & Install Cockpit Advanced
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Installing 45drives sharing scripts..." 19 68
    # sleep 0.5
    # Needs GPG to add repos
    sudo apt -y -q -o=dpkg::progress-fancy="1" install gpg
    # advanced file support by 45drives
    curl -sSL https://repo.45drives.com/setup | sudo bash
    sudo apt -y -q -o=dpkg::progress-fancy="1" install \
    crudini \
    cockpit-file-sharing \
    cockpit-navigator \
    gvfs-backends \
    gvfs-fuse
    
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Setting up smb.conf..." 19 68
    file_name=/etc/samba/smb.conf
    # remove leading spaces & tabs so crudini does not fail
    sudo sed -i.bak 's/^[ \t]*//' $file_name
    # add key pair to samba
    sudo crudini --set $file_name global include registry
  ;;
  "08")
    # remove statup Splash 
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Updating Grub..." 19 68
    sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\ splash\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/g" /etc/default/grub
    sudo update-grub
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Boot Splash turned OFF" 19 68
    sleep 0.5
  ;;
  "09")
    # Implement Kernal Grub cmds
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Applying current freeze fixes..." 19 68
    sleep 0.5
    # Create grub.d folder
    if [ ! -e /etc/default/grub.d ]; then
      sudo mkdir /etc/default/grub.d
    fi
    # Remove any existing NxOS grub settings
    # Don't care if does not exist
    sudo rm /etc/default/grub.d/*nxos*.cfg
    sudo tee /etc/default/grub.d/50_nxos_cstate.cfg > /dev/null << EOF
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX i915.enable_rc6=0"
EOF
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Updating Grub..." 19 68
    sudo update-grub
  ;;
  "10")
    # Download nxos-default-settings.deb
    file_name="nxos-default-settings.deb"
    if ! download "$WebHostFiles/$file_name"; then
      continue
    fi
    if ! sudo dpkg --force-overwrite -i "$file_name"; then
      continue
    fi
    # remove live cd autologin
    sudo rm /etc/lightdm/lightdm.conf
  ;;
  "11")
    # Uninstall Nx Server & Client
    file_name_list="networkoptix-mediaserver networkoptix-client"
    for file_name in $file_name_list
    do
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Removing $file_name..." 19 68
      sleep 0.5
      if ! sudo dpkg -r "$file_name"; then
        continue
      fi
    done
  ;;
  "12")
    # Download & Install Specific Nx Client
    NxMajVer=$(TERM=ansi whiptail --title "$TITLE" --inputbox "\n Install Nx Witness Client\nEnter Nx Major Version eg. 4.2.0" 19 68 3>&1 1>&2 2>&3)      
    NxBuild=$(TERM=ansi whiptail --title "$TITLE" --inputbox "\n Enter Nx Build Number eg. 32840" 19 68 3>&1 1>&2 2>&3)
    NxFulVer="$NxMajVer.$NxBuild"
    # Display Checklist (whiptail)
    NX_CHOICES=$(whiptail --title "$TITLE" --separate-output --checklist "Choose options" 19 68 13 \
      "01" "Install specific Nx Client" ON \
      "02" "Install specific Nx Server" ON 3>&1 1>&2 2>&3)
    for NX_CHOICE in $NX_CHOICES; do
      case $NX_CHOICE in
      "01")
        # Install Nx Client - specific version
        file_name="nxwitness-client-${NxFulVer}-linux64.deb"
        if ! download "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name"; then
          # Retry with alternate syntax
          file_name="nxwitness-client-${NxFulVer}-linux_x64.deb"
          if ! download "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name"; then
            continue
          fi
        fi
        if ! install_deb "$file_name"; then
          continue
        fi
      ;;
      "02")
        # Install Nx Server - specific version
        file_name="nxwitness-server-${NxFulVer}-linux64.deb"
        if ! download "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name"; then
          # Retry with alternate syntax
          file_name="nxwitness-server-${NxFulVer}-linux_x64.deb"
          if ! download "https://updates.networkoptix.com/default/$NxBuild/linux/$file_name"; then
            continue
          fi
        fi
        if ! install_deb "$file_name"; then
          continue
        fi
        TERM=ansi whiptail --title "$TITLE" --infobox "\n Applying Nx Storage permissions Fix..." 19 68
        sleep 0.5
        # Enable Nx AnalyticsDbStoragePermissions
        if ! curl "http://admin:admin@127.0.0.1:7001/api/systemSettings?forceAnalyticsDbStoragePermissions=true"; then
          TERM=ansi whiptail --title "$TITLE" --infobox "\n Failed to apply Nx Storage permissions Fix!" 19 68
          sleep 3
        fi
        ;;
      esac
    done
  ;;
  "13")
    # Run updates
    TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Applying System Updates..." 19 68
    sleep 0.5
    sudo apt -y -q -o=dpkg::progress-fancy="1" upgrade
    TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Cleaning System..." 19 68
    sleep 0.5
    sudo apt -y -q -o=dpkg::progress-fancy="1" autoremove
  ;;
  *)
    echo "Unsupported item $CHOICE!" >&2
    break
  ;;
  esac
done
