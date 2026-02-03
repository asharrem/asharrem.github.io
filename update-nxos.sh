#!/bin/bash

# shellcheck disable=SC2317,SC2329
# Functions are called dynamically via $func mechanism (choice_01 .. choice_14)

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

# set Nx defaults & Hostname Prefix
NxMajVer="6.0.6"
NxBuild="41837"

SU_PASS="nxw1tness"

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

# Install using apt non-interactive & quiet
function install_deb {
  file_name="$(basename -- "$1")"
  TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Installing $file_name..." 19 68
  sleep 0.5
  if ! sudo DEBIAN_FRONTEND=noninteractive apt -y -q -o=dpkg::progress-fancy="1" install "./$file_name"; then
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

main() {
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

# get current OS details
# shellcheck source=/dev/null
. /etc/os-release

RebootWillHappenAfterFinish=0
OsMajorVer="$(echo $VERSION_ID | awk -F. '{print $1}')"
OsMinorVer="$(echo $VERSION_ID | awk -F. '{print $2}')"
ServerName="NxOS-${OsMajorVer}-${OsMinorVer}"
NxFulVer="$NxMajVer.$NxBuild"

# set tile of whiptail TUI
TITLE="NxOS Installation Wizard"

# check if the script has run once & disk manager flag exists. Clean up and start disk manager
if [ -e /opt/nxos/autostart_disk_manager ]; then
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Disk Manager Starting!" 19 68
  sudo rm /opt/nxos/autostart_disk_manager
  sudo rm /opt/nxos/new_install
  sudo gnome-disks
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Disk Manager Finished!" 19 68
  sleep 3
  exit 0
fi

# change ANSI color for TUI
sudo ln -sf /etc/newt/palette.original /etc/newt/palette

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

# set working dir: when root use /dev/shm or /tmp (no ~/Downloads); else use ~/Downloads or ram/tmp
if [[ $EUID -eq 0 ]]; then
  # Running as root — ~/Downloads often doesn't exist; use ram or /tmp
  if [[ -d /dev/shm ]]; then
    Working_Dir="/dev/shm"
  elif [[ -d /tmp ]]; then
    Working_Dir="/tmp"
  else
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Unable to set Working Dir...Aborting" 8 68
    sleep 3
    exit 1
  fi
elif [[ -n "$HOME" && -d "$HOME/Downloads" ]]; then
  Working_Dir="$HOME/Downloads"
else
  if [[ -d /dev/shm ]]; then
    Working_Dir="/dev/shm"
  elif [[ -d /tmp ]]; then
    Working_Dir="/tmp"
  else
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Unable to set Working Dir...Aborting" 8 68
    sleep 3
    exit 1
  fi
fi
TERM=ansi whiptail --title "$TITLE" --infobox "\n Working Dir is: ${Working_Dir}..." 8 68
cd "$Working_Dir" || exit 1
sleep 3

# display a whiptail progress bar for 50 seconds to accept any key press
for ((i = 0; i <= 100; i+=2)); do
    # read any key press 1 second timeout
    read -s -t 1 -n 1 key && break
    echo $i | TERM=ansi whiptail --title "$TITLE" --gauge "Press S to skip New System setup..." 6 60 0
done

case $key in
  # Skip New System setup
  "s" | "S")
    
    sudo rm /opt/nxos/autostart_disk_manager
    sudo rm /opt/nxos/new_install

    # Display Checklist (whiptail)
    CHOICES=$(whiptail --title "$TITLE" --separate-output --checklist "Choose options \n" 20 68 13 \
      "01" "Download & Run DWService.net Agent " ON \
      "02" "Update Hostname to MAC address syntax " OFF \
      "03" "Purge Nx & Google .deb's from Downloads Folder " OFF \
      "04" "Download & Install Google Chrome Browser " OFF \
      "05" "Download & Install Nx Client ${NxMajVer}.${NxBuild} " OFF \
      "06" "Download & Install Nx Server ${NxMajVer}.${NxBuild} " OFF \
      "07" "Install Cockpit Advanced File Sharing (NAS) " OFF \
      "08" "Install Camera Plugins (VCA) " OFF \
      "09" "Debug - Freeze Fix " OFF \
      "10" "Update NxOS Defaults " OFF \
      "11" "Un-Install Nx Witness Server & Client " OFF \
      "12" "Install a specific Nx Witness Client & or Server " OFF \
      "13" "Run Updates " OFF \
      "14" "Install DS-WSELI-T2/8p PoE Drivers " OFF 3>&1 1>&2 2>&3)
    ;;
  *)
    # update cockpit
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Updating Cockpit..." 19 68
    sleep 1
    sudo apt -y -q -o=dpkg::progress-fancy="1" install -t "${VERSION_CODENAME}"-backports cockpit
    # Set default choices
    CHOICES="02 03 04 05 06 09 10 13"
    TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Starting New System Defaults..." 19 68
    # Create openbox autostart script file reference for disk manager
    sudo touch /opt/nxos/autostart_disk_manager
    sleep 1
    ;;
esac

# --- CHOICE HANDLERS ---

function choice_01 {
  # Download & Run DWAgent
  TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Getting DWAgent..." 19 68
  sleep 0.5
  file_name="https://www.dwservice.net/download/dwagent.sh"
  if ! download "$file_name"; then
    TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Failed to get DWAgent..." 19 68
    sleep 0.5
    return
  else
    sudo bash dwagent.sh
    TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Finished with DWAgent..." 19 68
    sleep 0.5
  fi
}

function choice_02 {
  # Update Hostname
  macaddy="0000"
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Updating Hostname to MAC address syntax..." 19 68
  sleep 0.5
  unset first_eth
  for iface in /sys/class/net/*; do
    [[ -d "$iface" ]] || continue
    if [[ $(basename "$iface") == e* ]]; then
      first_eth=$(basename "$iface")
      break
    fi
  done
  if [[ -n "$first_eth" ]]; then
    macaddy=$(cat /sys/class/net/"$first_eth"/address | tr -d ':' | grep -o '....$')
  fi
  ServerName="${ServerName}-${macaddy}"
  sudo hostnamectl set-hostname "$ServerName"
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Hostname = ${ServerName}" 19 68
  sleep 0.5
  sudo sed -i 's/127.0.1.1	'"${HOSTNAME}"'/127.0.1.1	'"${ServerName}"'/g' /etc/hosts
  TERM=ansi whiptail --title "$TITLE" --infobox "\n DNS Updated - Reboot will happen after finish." 19 68
  RebootWillHappenAfterFinish=1
  sleep 3
}

function choice_03 {
  # Purge Nx & Google .deb's from Downloads Folder
  file_name_list="chrome-remote-desktop_current_amd64.deb google-chrome-stable_current_amd64.deb nxwitness-*.deb"
  for file_name in $file_name_list
  do
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Removing $file_name ..." 19 68
    sleep 0.5
    rm "$file_name" > /dev/null 2>&1
  done
  rm -r "$HOME/.local/share/Network Optix"
}

function choice_04 {
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
  file_name="/etc/opt/chrome/policies/managed/nxos.json"
  if [ ! -f "$file_name" ]; then
    TERM=ansi whiptail --title "$TITLE" --infobox "\n Setting Chrome Browser Policy..." 19 68
    sleep 0.5
    sudo mkdir -p "${file_name%/*}"
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
}

function choice_05 {
  # Install Nx Client
  install_nx client
}

function choice_06 {
  # Install Nx Server
  install_nx server
  install_nx_server_post_cmd
}

function choice_07 {
  # Download & Install Cockpit Advanced
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Installing 45drives sharing scripts..." 19 68
  sudo apt -y -q -o=dpkg::progress-fancy="1" install gpg zfsutils-linux
  curl -sSL https://repo.45drives.com/setup | sudo bash
  sudo apt -y -q -o=dpkg::progress-fancy="1" install \
  cockpit-file-sharing \
  cockpit-zfs-manager \
  cockpit-identities \
  gvfs-backends \
  gvfs-fuse
}

function choice_08 {
  # Install Camera Plugins - currently only VCA Edge AI
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
}

function choice_09 {
  # Grub mods: remove startup Splash
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Updating Grub..." 19 68
  sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\\ splash\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/g" /etc/default/grub
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Boot Splash turned OFF" 19 68
  sleep 0.5
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Applying current freeze fixes..." 19 68
  sleep 0.5
  if [ ! -e /etc/default/grub.d ]; then
    sudo mkdir /etc/default/grub.d
  fi
  sudo rm /etc/default/grub.d/*nxos*.cfg
  sudo tee /etc/default/grub.d/50_nxos_fix.cfg > /dev/null << EOF
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX intel_idle.max_cstate=1 i915.enable_dc=0 ipv6.disable=1 module_blacklist=pinctrl_elkhartlake"
EOF
  TERM=ansi whiptail --title "$TITLE" --infobox "\n Updating Grub..." 19 68
  sudo update-grub
}

function choice_10 {
  # Download nxos-default-settings.deb
  file_name="nxos-default-settings.deb"
  if ! download "$WebHostFiles/$file_name"; then
    return
  fi
  sudo apt -y -o DPkg::options::="--force-overwrite" install "./$file_name"
  sudo rm /etc/lightdm/lightdm.conf
  sudo apt -yf install
  rm "$HOME/.gtkrc-2.0"
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
  sudo rm /etc/lightdm/lightdm.conf
}

function choice_11 {
  # Uninstall Nx Server & Client
  unset file_name_list
  NX_CHOICES=$(whiptail --title "$TITLE" --separate-output --checklist "Choose options" 19 68 2 \
    "01" "Uninstall Nx Client " ON \
    "02" "Uninstall Nx Server " ON 3>&1 1>&2 2>&3)
  for NX_CHOICE in $NX_CHOICES; do
    case $NX_CHOICE in
    "01")
      file_name_list="networkoptix-client $file_name_list"
      rm -r "$HOME/.local/share/Network Optix"
      ;;
    "02")
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
}

function choice_12 {
  # Download & Install Specific Nx Client
  NxMajVer=$(TERM=ansi whiptail --title "$TITLE" --inputbox "\n Install Nx Witness Client\nEnter Nx Major Version eg. 4.2.0" 19 68 3>&1 1>&2 2>&3)      
  NxBuild=$(TERM=ansi whiptail --title "$TITLE" --inputbox "\n Enter Nx Build Number eg. 32840" 19 68 3>&1 1>&2 2>&3)
  NxFulVer="$NxMajVer.$NxBuild"
  NX_CHOICES=$(whiptail --title "$TITLE" --separate-output --checklist "Choose options" 19 68 2 \
    "01" "Install specific Nx Client" ON \
    "02" "Install specific Nx Server" ON 3>&1 1>&2 2>&3)
  for NX_CHOICE in $NX_CHOICES; do
    case $NX_CHOICE in
    "01")
      install_nx client
      ;;
    "02")
      install_nx server
      install_nx_server_post_cmd
      ;;
    esac
  done
}

function choice_13 {
  # Run updates
  TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Applying System Updates..." 19 68
  sleep 0.5
  sudo apt -y -q -o=DPkg::options::="--force-overwrite" install libgtk-3-0
  sudo apt -y -q -o=dpkg::progress-fancy="1" dist-upgrade
  TERM=ansi whiptail --clear --title "$TITLE" --infobox "\n Cleaning System..." 19 68
  sleep 0.5
  sudo apt -y -q -o=dpkg::progress-fancy="1" autoremove
}

function choice_14 {
  # Install DS-WSELI Workstation PoE Drivers
  file_name="ds-wseli-poe.deb"
  if ! download "$WebHostFiles/$file_name"; then
    return
  fi
  if ! install_deb "$file_name"; then
    return
  fi
}

for CHOICE in $CHOICES; do
  func="choice_${CHOICE}"
  if declare -f "$func" > /dev/null; then
    $func
  else
    echo "Unsupported item $CHOICE!" >&2
    break
  fi
done

if [ "$RebootWillHappenAfterFinish" == "1" ]; then
  # display a whiptail progress bar for 10 seconds to accept any key press
  unset key
  for ((i = 0; i <= 100; i+=5)); do
      # read any key press 1 second timeout
      read -s -t 1 -n 1 key && break
      echo $i | TERM=ansi whiptail --title "$TITLE" --gauge "Press S to skip Reboot..." 6 60 0
  done

  case $key in
    # Skip Reboot
    s | S)
    ;;
    *)
      pcmanfm --desktop-off
      sudo reboot
    ;;
  esac
fi 
TERM=ansi whiptail --title "$TITLE" --infobox "\n Wizard Finished!!!" 8 68
sleep 1
exit 0
}

main "$@"