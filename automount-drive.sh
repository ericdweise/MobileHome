#!/bin/bash

# MobileHome is an automount system for USB drives.

# ARGS:
# 1 - device to be automounted

set -uo pipefail


# CONSTANTS
MOUNT_POINT="/home/mobilehome"
LUKS_KEY_FILE="$HOME/.mhcrypt"
SYSD_MOUNT="${MOUNT_POINT//'/'/'-'}"
SYSD_MOUNT="${SYSD_MOUNT/'-'/''}"
USER_ID="$(whoami)"

SYSD_LUKS=''

# Check argument is provided
if [ -z $1 ]; then
    echo 'No argument provided.' 1>&2
    exit 1
fi

# Ensure that device is a block device
if [ ! -b $1 ]; then
    echo "$1 is NOT a block device. Exiting installation" 1>&2
    exit 1
fi

# Find UUID of mobilehome device
UUID=$(sudo blkid -o value -s UUID $1)
echo "*** DEVICE UUID: '$UUID'"
if [ -z $UUID ]; then
    echo 'No Device UUID found' 1>&2
    exit 1
fi

# Create mount point
if [ ! -d "$MOUNT_POINT" ]; then
    echo "*** Creating mount point: $MOUNT_POINT"
    sudo mkdir $MOUNT_POINT
fi

# Create Passphrase file
if ! [[ -f $LUKS_KEY_FILE ]]; then
    echo "*** Creating new passphrase file: $LUKS_KEY_FILE"
    sudo dd if=/dev/random of=$LUKS_KEY_FILE bs=256 count=1
    sudo chmod 0400 $LUKS_KEY_FILE
fi

# Test if keyfile will unlock drive. If not, add it to the LUKS header
sudo cryptsetup open /dev/disk/by-uuid/$UUID mobilehome --key-file $LUKS_KEY_FILE
if [[ $? -ne 0 ]]; then
    echo '*** Adding new key-file to LUKS header'
    sudo cryptsetup luksAddKey $1 $LUKS_KEY_FILE
else
    sudo cryptsetup close mobilehome
fi

# Add drive to /etc/crypttab
echo '*** Editing /etc/crypttab'
printf '\n# Added by MobileHome\n' | sudo tee -a /etc/crypttab
echo "mobilehome /dev/disk/by-uuid/$UUID $LUKS_KEY_FILE luks" | sudo tee -a /etc/crypttab

# Add line to /etc/fstab
echo '*** Editing /etc/fstab'
printf '\n# Added by MobileHome\n' | sudo tee -a /etc/fstab
echo "/dev/mapper/mobilehome	$MOUNT_POINT	ext4	rw,x-systemd.automount,x-systemd.device-timeout=2,noauto,nofail	0	2" | sudo tee -a /etc/fstab

## Save automount services in SystemD
echo '*** Saving automount services and reloading SystemD services'
sudo systemctl daemon-reload
sudo systemctl restart local-fs.target

# Mount drive and change permissions of mountpoint
echo "*** Changing ownership of mount point '$MOUNT_POINT' from 'root' to '$USER_ID'"
sudo mount $MOUNT_POINT
sudo chown $USER_ID:$USER_ID $MOUNT_POINT

# check that systemd services have been created and are active
echo '*** The following SystemD services should now be active:'
echo " - $SYSD_MOUNT.mount)"
echo " - $SYSD_MOUNT.automount)"
echo " Try running 'systemctl status' to see their state"

echo '*** All finished'
