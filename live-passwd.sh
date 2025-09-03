#!/bin/bash

# Check for whiptail
if ! command -v whiptail &> /dev/null; then
    echo "whiptail is required but not installed. Please install it and rerun this script."
    exit 1
fi

# Find block devices (excluding loop, rom, and the live USB itself)
DEVICES=()
while read -r line; do
    DEV=$(echo "$line" | awk '{print $1}')
    SIZE=$(echo "$line" | awk '{print $4}')
    MOUNTED=$(echo "$line" | awk '{print $7}')
    # Exclude live USB (mounted on /cdrom or /media), loop, rom, and empty mountpoints
    if [[ "$DEV" =~ ^/dev/(sd|hd|vd|nvme|mmcblk) ]] && [[ "$MOUNTED" != "/" ]] && [[ "$MOUNTED" != "/cdrom" ]] && [[ "$MOUNTED" != /media/* ]]; then
        DEVICES+=("$DEV" "$SIZE $MOUNTED")
    fi
done < <(lsblk -lpno NAME,TYPE,SIZE,MOUNTPOINT | grep "part")

if [ ${#DEVICES[@]} -eq 0 ]; then
    whiptail --msgbox "No suitable block devices found." 10 50
    exit 1
fi

# Let user select the boot/root partition
SELECTED_DEV=$(whiptail --title "Select Ubuntu Partition" --menu "Choose the Ubuntu root/boot partition:" 20 70 10 "${DEVICES[@]}" 3>&1 1>&2 2>&3)
if [ -z "$SELECTED_DEV" ]; then
    whiptail --msgbox "No partition selected. Exiting." 10 50
    exit 1
fi

# Mount the selected partition
MNTDIR="/mnt/ubuntu-root"
sudo mkdir -p "$MNTDIR"
sudo mount "$SELECTED_DEV" "$MNTDIR"

# Bind mount necessary filesystems for chroot
for fs in proc sys dev; do
    sudo mount --bind /$fs "$MNTDIR"/$fs
done

# Get list of users from /etc/passwd in the chroot
USER_LIST=()
while IFS=: read -r username _ uid _ _ _ _; do
    if [ "$uid" -ge 1000 ] && [ "$uid" -lt 65534 ]; then
        USER_LIST+=("$username" "")
    fi
done < "$MNTDIR/etc/passwd"

if [ ${#USER_LIST[@]} -eq 0 ]; then
    whiptail --msgbox "No regular users found on the selected partition." 10 50
    # Cleanup
    for fs in dev sys proc; do
        sudo umount "$MNTDIR"/$fs
    done
    sudo umount "$MNTDIR"
    exit 1
fi

# Let user select which user to reset password for
SELECTED_USER=$(whiptail --title "Select User" --menu "Choose the user to reset password for:" 20 60 10 "${USER_LIST[@]}" 3>&1 1>&2 2>&3)
if [ -z "$SELECTED_USER" ]; then
    whiptail --msgbox "No user selected. Exiting." 10 50
    # Cleanup
    for fs in dev sys proc; do
        sudo umount "$MNTDIR"/$fs
    done
    sudo umount "$MNTDIR"
    exit 1
fi

# Prompt for new password
NEWPASS=$(whiptail --title "New Password" --passwordbox "Enter new password for $SELECTED_USER:" 10 60 3>&1 1>&2 2>&3)
if [ -z "$NEWPASS" ]; then
    whiptail --msgbox "No password entered. Exiting." 10 50
    # Cleanup
    for fs in dev sys proc; do
        sudo umount "$MNTDIR"/$fs
    done
    sudo umount "$MNTDIR"
    exit 1
fi

# Confirm password
CONFIRM_PASS=$(whiptail --title "Confirm Password" --passwordbox "Re-enter new password for $SELECTED_USER:" 10 60 3>&1 1>&2 2>&3)
if [ "$NEWPASS" != "$CONFIRM_PASS" ]; then
    whiptail --msgbox "Passwords do not match. Exiting." 10 50
    # Cleanup
    for fs in dev sys proc; do
        sudo umount "$MNTDIR"/$fs
    done
    sudo umount "$MNTDIR"
    exit 1
fi

# Change password in chroot
echo "$SELECTED_USER:$NEWPASS" | sudo chroot "$MNTDIR" chpasswd

if [ $? -eq 0 ]; then
    whiptail --msgbox "Password for $SELECTED_USER has been reset successfully." 10 50
else
    whiptail --msgbox "Failed to reset password for $SELECTED_USER." 10 50
fi

# Cleanup
for fs in dev sys proc; do
    sudo umount "$MNTDIR"/$fs
done
sudo umount "$MNTDIR"

exit 0
