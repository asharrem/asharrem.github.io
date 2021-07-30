#!/bin/bash
# disable xdisplay
# systemctl set-default multi-user.target
# Remove quiet splash from GRUB
sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\ splash\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/g" /etc/default/grub
echo -e "\n Removed quiet splash from GRUB ... \n"
if [ ! -e /etc/default/grub.d ]; then
  echo -e "\n Making grub.d ... \n"
  sudo mkdir /etc/default/grub.d
fi
sudo rm /etc/default/grub.d/*nxos*.cfg
sudo tee /etc/default/grub.d/50_nxos_cstate.cfg > /dev/null << EOF
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX intel_idle.max_cstate=1"
EOF
sudo tee /etc/default/grub.d/60_nxos_hdmi.cfg > /dev/null << EOF
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX video=HDMI-A-1:1920x1080@60:D"
EOF
sudo update-grub
sudo apt install linux-crashdump
echo -e "\n *** Reboot Required *** \n"
sleep 1
