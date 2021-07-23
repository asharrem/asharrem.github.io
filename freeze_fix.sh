#!/bin/bash
# disable xdisplay
# systemctl set-default multi-user.target
# sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\ splash\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/g" /etc/default/grub
if [ ! -e /etc/default/grub.d ]; then
  echo -e "\n Making grub.d ... \n"
  sudo mkdir /etc/default/grub.d
fi
sudo rm /etc/default/grub.d/*nxos*.cfg
# video=HDMI-A-1:1920x1080@60:D
sudo tee /etc/default/grub.d/50_nxos.cfg > /dev/null << EOF
GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX nomodeset i915.modeset=0 intel_idle.max_cstate=1"
EOF
sudo update-grub
echo -e "\n *** Reboot Required *** \n"
sleep 1
