#!/bin/bash

# disable/enable xdisplay
# systemctl set-default multi-user.target
# systemctl set-default graphical.target

# Remove quiet splash from GRUB
sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\ splash\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/g" /etc/default/grub
echo -e "\n Removed quiet splash from GRUB ... \n"

# Create grub.d folder
if [ ! -e /etc/default/grub.d ]; then
  echo -e "\n Making grub.d ... \n"
  sudo mkdir /etc/default/grub.d
fi

# Remove any existing NxOS grub settings
# Don't care if does not exist
sudo rm /etc/default/grub.d/*nxos*.cfg

# Turn Off C-States
read -p "Disable C-States (y/N)? [default=No]: " answer
case ${answer:0:1} in
  y|Y )
  sudo tee /etc/default/grub.d/50_nxos_cstate.cfg > /dev/null << EOF
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX intel_idle.max_cstate=0"
EOF
  ;;
  # [default=No]
  * )
    echo -e "\n Skipping C-State workarounds \n"
    ;;
esac

# Force HDMI
read -p "Force HDMI @ 1080p (y/N)? [default=No]: " answer
case ${answer:0:1} in
  y|Y )
  sudo tee /etc/default/grub.d/60_nxos_hdmi.cfg > /dev/null << EOF
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX video=HDMI-A-1:1920x1080@60:e"
EOF
  ;;

  # [default=No]
  * )
  echo -e "\n Skipping HDMI workarounds \n"
  ;;
esac

# Nomodeset
read -p "Use nomodeset (y/N)? [default=No]: " answer
case ${answer:0:1} in
  y|Y )
  sudo tee /etc/default/grub.d/70_nxos_nomodeset.cfg > /dev/null << EOF
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX nomodeset"
EOF
  ;;

  # [default=No]
  * )
  echo -e "\n Skipping nomodeset workarounds \n"
  ;;
esac

sudo update-grub

# Install kdump system
read -p "Install kdump (y/N)? [default=No]: " answer
case ${answer:0:1} in
  y|Y )
  sudo apt install -y linux-crashdump
  ;;

  # [default=No]
  * )
  echo -e "\n Skipping kdump workarounds \n"
  ;;
esac

echo -e "\n *** Reboot Required *** \n"
sleep 1
