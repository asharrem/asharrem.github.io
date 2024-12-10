#!/bin/bash
sudo apt install curl

# disable gui
sudo systemctl set-default multi-user.target

# fix nxos libgtk-3-0 update issue
sudo apt -o DPkg::options::="--force-overwrite" install libgtk-3-0

# update cockpit
. /etc/os-release
sudo apt install -t ${VERSION_CODENAME}-backports cockpit

# add cockpit ZFS manager
curl -sSL https://repo.45drives.com/setup | sudo bash
sudo apt-get update
sudo apt install openssh-server cockpit-file-sharing cockpit-zfs-manager cockpit-machines

# setup root user for vm migration & zfs remote replication tasks
# unlock root account
sudo passwd -u root
echo "set root password"
sudo passwd root
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh
echo "Use cockpit to do root key exchange"

# next task here
