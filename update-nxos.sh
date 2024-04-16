#!/bin/bash

############################################
# This script is for post install of NxOS
# Automatically run at fist boot or
# manually by /opt/nxos/intsall.sh
#
# maintainer: andrew@nfs.co.nz
#
############################################

# set host location of additional install files
WebAddress="asharrem.github.io"
WebHostFiles="https://$WebAddress"

# set tile of whiptail TUI
TITLE="NxOS Installation Wizard"

# get current OS details
# shellcheck source=/dev/null
. /etc/os-release

# set Nx defaults & Hostname Prefix
NxMajVer="5.1.3"
NxBuild="38363"
#
SU_PASS="nxw1tness"
OsMajorVer="$(echo $VERSION_ID | awk -F. '{print $1}')"
OsMinorVer="$(echo $VERSION_ID | awk -F. '{print $2}')"
ServerName="NxOS-${OsMajorVer}-${OsMinorVer}"
macaddy="0000"
NxFulVer="$NxMajVer.$NxBuild"
NxUrl="https://updates.networkoptix.com/default"
NxFilenameTypes="linux64 linux_x64 linux_x64-patch"

############################################

# wget url($1)
function download {
  export file_name_debug="$1"
  file_name="$(basename -- "$1")"
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Downloading $file_name..." 19 68
  sleep 3.5
  # only download & overwrite newer file - quietly
  if ! wget -N -q --show-progress "$1"; then
    # Download failed
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Downloading $file_name failed!" 19 68
    sleep 3
    return 1
  fi
}

# Install using gdebi non-interactive & quiet
function install_deb {
  file_name="$(basename -- "$1")"
  TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Installing $file_name..." 19 68
  sleep 0.5
  if ! sudo gdebi -n -q -o quiet=1 -o dpkg::progress-fancy="1" "$file_name"; then
    # Install failed
    TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Installing $file_name failed!" 19 68
    sleep 3
    return 1
  fi
  TERM=ansi whiptail --title "$TITLE" --infobox "\n ...Installed $file_name" 19 68
  sleep 1
}

# Enable Nx AnalyticsDbStoragePermissions
function install_nx_server_post_cmd {
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Applying Nx Storage permissions Fix..." 19 68
  sleep 0.5
  if ! curl -k -L --max-redirs 1 -u admin:admin "http://127.0.0.1:7001/api/systemSettings?forceAnalyticsDbStoragePermissions=true"; then
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Failed to apply Nx Storage permissions Fix!" 19 68
    sleep 3
    return 1
  fi
}

# Download & Install Nx: $1 = server || client
function install_nx {
  # go thru url synatax iterations
  for Nxtype in $NxFilenameTypes; do
    file_name="nxwitness-$1-$NxFulVer-$Nxtype.deb"
    # test if file is available
    if [[ $(curl -o /dev/null --silent -Iw '%{http_code}' "${NxUrl}/${NxBuild}/linux/${file_name}") = 200 ]]; then
      download "$NxUrl/$NxBuild/linux/$file_name"
      install_deb "$file_name"
      break
    fi
  done
}

# =============   main  ================

# Get sudo password
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
if ! command -v curl &> /dev/null; then
  sleep 3
  sudo apt -y -q -o=dpkg::progress-fancy="1" install curl
fi

# Install gdebi. Needed to install stuff.
TERM=ansi whiptail --title "$TITLE" --infobox "\n Installing GDebi..." 19 68
if ! command -v gdebi &> /dev/null; then
  sleep 3
  sudo apt -y -q -o=dpkg::progress-fancy="1" install gdebi-core
fi

# set working dir to $HOME/Downloads or ram drive
if [[ -d $HOME/Downloads ]]; then
  Working_Dir="$HOME/Downloads"
else
  if [[ -d /dev/shm ]]; then
    Working_Dir="/dev/shm"
  else
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Unable to set Working Dir...Aborting" 8 68
    sleep 3
    exit 1
  fi  
fi
TERM=ansi whiptail --title "$TITLE" --infobox "\n Working Dir is: ${Working_Dir}..." 8 68
cd "$Working_Dir" || exit 1
sleep 3

# Display Checklist (whiptail)
CHOICES=$(whiptail --title "$TITLE" --separate-output --checklist "Choose options" 19 68 14 \
  "01" "Download & Run DWService.net Agent " OFF \
  "02" "Update Hostname to MAC address syntax " ON \
  "03" "Purge Nx & Google .deb's from Downloads Folder " ON \
  "04" "Download & Install Google Chrome Browser " ON \
  "05" "Download & Install Nx Client ${NxMajVer}.${NxBuild} " ON \
  "06" "Download & Install Nx Server ${NxMajVer}.${NxBuild} " ON \
  "07" "Install Cockpit Advanced File Sharing (NAS) " OFF \
  "08" "Install Camera Plugins (VCA) " OFF \
  "09" "Debug - Freeze Fix " ON \
  "10" "Update NxOS Defaults " ON \
  "11" "Un-Install Nx Witness Server & Client " OFF \
  "12" "Install a specific Nx Witness Client & or Server " OFF \
  "13" "Run Updates " ON \
  "14" "Install DS-WSELI-T2/8p PoE Drivers " OFF 3>&1 1>&2 2>&3)

for CHOICE in $CHOICES; do
  case $CHOICE in
  # Download & Run DWAgent
  "01")
    TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Getting DWAgent..." 19 68
    sleep 0.5
    file_name="https://www.dwservice.net/download/dwagent.sh"
    if ! download "$file_name"; then
      TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Failed to get DWAgent..." 19 68
      sleep 0.5
      continue
    else
      sudo bash dwagent.sh
      TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Finished with DWAgent..." 19 68
      sleep 0.5
    fi
  ;;
  # Update Hostname
  "02")
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
    TERM=ansi whiptail --title "$TITLE" --infobox "\n DNS Updated - Reboot required" 19 68
    sleep 3
  ;;
  # Purge Nx & Google .deb's from Downloads Folder
  "03")
    file_name_list="chrome-remote-desktop_current_amd64.deb google-chrome-stable_current_amd64.deb nxwitness-*.deb"
    for file_name in $file_name_list
    do
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Removing $file_name ..." 19 68
      sleep 0.5
      rm "$file_name" > /dev/null 2>&1
    done
    rm -r "$HOME/.local/share/Network Optix"
  ;;
  # Download Chrome files if they don't exist, then install them
  "04")
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
 
    # Create Chrome Browser Managed Policy - (Parts no longer work ?)
    file_name="/etc/opt/chrome/policies/managed/nxos.json"
    if [ ! -f "$file_name" ]; then
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Setting Chrome Browser Policy..." 19 68
      sleep 0.5
      # create file first because tee will not
      sudo mkdir -p "${file_name%/*}"
      # use tee to write to file because sudo cat <<EOF is BAD in this context.
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
"custom_chrome_frame": false,
}
EOF
    fi
  ;;
  # Install Nx Client
  "05")
    install_nx client
  ;;
  # Install Nx Sever
  "06")
    install_nx server
    install_nx_server_post_cmd
  ;;
  # Download & Install Cockpit Advanced
  "07")
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Installing 45drives sharing scripts..." 19 68
    # sleep 0.5
    sudo apt -y -q -o=dpkg::progress-fancy="1" install -t "${VERSION_CODENAME}"-backports cockpit
    # Needs GPG to add repos
    sudo apt -y -q -o=dpkg::progress-fancy="1" install gpg zfsutils-linux
    # advanced file support by 45drives
    curl -sSL https://repo.45drives.com/setup | sudo bash
    sudo apt -y -q -o=dpkg::progress-fancy="1" install \
    crudini \
    cockpit-file-sharing \
    cockpit-navigator \
    cockpit-zfs-manager \
    gvfs-backends \
    gvfs-fuse
    
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Setting up smb.conf..." 19 68
    file_name=/etc/samba/smb.conf
    # remove leading spaces & tabs so crudini does not fail
    sudo sed -i.bak 's/^[ \t]*//' $file_name
    # add key pair to samba
    sudo crudini --set $file_name global include registry
  ;;
  # Install Camera Plugins - currently only VCA Edge AI 
  "08")
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Installing VCA..." 19 68
    sleep 0.5
    file_name="vca/nx/libvca_edge_analytics_plugin.so"
    if ! download "$WebHostFiles/$file_name"; then
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Failed..." 19 68
      sleep 0.5
    fi
    sudo cp libvca_edge_analytics_plugin.so /opt/networkoptix/mediaserver/bin/plugins
    sleep 0.5
    file_name="vca/nx/vca_models.json"
    if ! download "$WebHostFiles/$file_name"; then
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Failed..." 19 68
      sleep 0.5
    fi
    sudo cp vca_models.json /opt/networkoptix/mediaserver/bin
  ;;
  # Grub mods:
  "09")
  # Grub mods: remove startup Splash 
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Updating Grub..." 19 68
    sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\ splash\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/g" /etc/default/grub
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Boot Splash turned OFF" 19 68
    sleep 0.5
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Applying current freeze fixes..." 19 68
    sleep 0.5
    # Create grub.d folder
    if [ ! -e /etc/default/grub.d ]; then
      sudo mkdir /etc/default/grub.d
    fi
    # Remove any existing NxOS grub settings
    # Don't care if does not exist
    sudo rm /etc/default/grub.d/*nxos*.cfg
    sudo tee /etc/default/grub.d/50_nxos_fix.cfg > /dev/null << EOF
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX intel_idle.max_cstate=1 i915.enable_dc=0 ipv6.disable=1 module_blacklist=pinctrl_elkhartlake"
EOF
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Updating Grub..." 19 68
    sudo update-grub
  ;;
  # Download nxos-default-settings.deb
  "10")
    file_name="nxos-default-settings.deb"
    if ! download "$WebHostFiles/$file_name"; then
      continue
    fi
    sudo apt -o DPkg::options::="--force-overwrite" install "./$file_name"
    # remove live cd autologin
    sudo rm /etc/lightdm/lightdm.conf
    # fix broken dependancies from arc-theming
    sudo apt -yf install
    # clean up old theming from .gtkrc-2.0
    rm "$HOME/.gtkrc-2.0"
    # clean up from old nxos versions
    rm "$HOME/.config/gtk-3.0/settings.ini"
    rm "$HOME/.config/pcmanfm/default/pcmanfm.conf"
    rm "$HOME/.config/lxterminal/lxterminal.conf"
    rm "$HOME/.config/tint2/tint2rc"
    rm "$HOME/.local/share/applications/NxOS_Getting_Started.desktop"
    rm "$HOME/.local/share/applications/NxOS_Install_Wizard.desktop"
    rm "$HOME/.local/share/applications/NxOS_Clock.desktop"
    rm "$HOME/.config/openbox/menu.xml"
    rm "$HOME/.config/openbox/rc.xml"
    rm "$HOME/.config/openbox/autostart"
    sudo rm -r /etc/skel/
  ;;
  # Uninstall Nx Server & Client
  "11")
    unset file_name_list
    NX_CHOICES=$(whiptail --title "$TITLE" --separate-output --checklist "Choose options" 19 68 2 \
      "01" "Uninstall Nx Client " ON \
      "02" "Uninstall Nx Server " ON 3>&1 1>&2 2>&3)
    for NX_CHOICE in $NX_CHOICES; do
      case $NX_CHOICE in
      "01")
        # Uninstall Nx Client
       file_name_list="networkoptix-client $file_name_list"
       rm -r "$HOME/.local/share/Network Optix"
      ;;
      "02")
        # Uninstall Nx Server
       file_name_list="networkoptix-mediaserver $file_name_list"
      ;;
      esac
    done
    for file_name in $file_name_list
    do
      TERM=ansi whiptail --title "$TITLE" --infobox "\n Removing $file_name..." 19 68
      sleep 0.5
      if ! sudo dpkg -r "$file_name"; then
        continue
      fi
    done
  ;;
  # Download & Install Specific Nx Client
  "12")
    NxMajVer=$(TERM=ansi whiptail --title "$TITLE" --inputbox "\n Install Nx Witness Client\nEnter Nx Major Version eg. 4.2.0" 19 68 3>&1 1>&2 2>&3)      
    NxBuild=$(TERM=ansi whiptail --title "$TITLE" --inputbox "\n Enter Nx Build Number eg. 32840" 19 68 3>&1 1>&2 2>&3)
    NxFulVer="$NxMajVer.$NxBuild"
    # Display Checklist (whiptail)
    NX_CHOICES=$(whiptail --title "$TITLE" --separate-output --checklist "Choose options" 19 68 2 \
      "01" "Install specific Nx Client" ON \
      "02" "Install specific Nx Server" ON 3>&1 1>&2 2>&3)
    for NX_CHOICE in $NX_CHOICES; do
      case $NX_CHOICE in
      "01")
        # Install Nx Client - specific version
        install_nx client
      ;;
      "02")
        # Install Nx Server - specific version
        install_nx server
        install_nx_server_post_cmd
        ;;
      esac
    done
  ;;
  # Run updates
  "13")
    TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Applying System Updates..." 19 68
    sleep 0.5
    sudo apt -y -q -o=dpkg::progress-fancy="1" upgrade
    TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Cleaning System..." 19 68
    sleep 0.5
    sudo apt -y -q -o=dpkg::progress-fancy="1" autoremove
  ;;
  # Install DS-WSELI Workstation PoE Drivers
  "14")
    file_name="ds-wseli-poe.deb"
    if ! download "$WebHostFiles/$file_name"; then
      continue
    fi
    if ! install_deb "$file_name"; then
      continue
    fi
  ;;
  # Selection out of bounds
  *)
    echo "Unsupported item $CHOICE!" >&2
    break
  ;;
  esac
done
TERM=ansi whiptail --title "$TITLE" --infobox "\n Finished!!!" 8 68
sleep 1