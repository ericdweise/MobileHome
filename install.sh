#!/bin/bash

# MobileHome is an automount system for USB drives.

# ARGS:
# 1 - device to be automounted

# CONSTANTS
MOUNT_POINT="$HOME/mobilehome"
UNIT_FILE="${MOUNT_POINT//'/'/'-'}"
UNIT_FILE="${UNIT_FILE/'-'/''}"

# Check argument is provided
if [ -z $1 ]; then
    echo 'No argument provided.'
    exit '1'
fi

# Ensure that device is a block device
if [ ! -b $1 ]; then
    echo "$1 is NOT a block device. Exiting installation"
    exit '100'
fi

# Find UUID of mobilehome device
DEV_UUID=$(sudo blkid -o value -s UUID $1)
echo "DEVICE UUID: '$DEV_UUID'"
if [ -z $DEV_UUID ]; then
    echo 'No Device UUID found'
    exit '101'
fi
TEST=$(grep "$DEV_UUID" /etc/fstab)
if [ TEST ]; then
    echo "The Device UUID $DEV_UUID is already in fstab."
    exit '102'
fi

# Find user id
USER_UID="$(whoami)"
# TODO: figure out how to elevate privs while getting right output from
# whoami command. Running the entire script as root will set USERID to
# 'root', but I want unpriv'd users to have access to their own mobilehome.


# Create mount point
if [ ! -d "$MOUNT_POINT" ]; then
    mkdir $MOUNT_POINT
fi

# Add line to /etc/fstab
printf '\n# Added by MobileHome\n' | sudo tee -a /etc/fstab
echo "UUID=$DEV_UUID	$MOUNT_POINT	auto	rw,uid=$USER_UID,gid=$USER_UID,x-systemd.automount,x-systemd.device-timeout=2,noauto,nofail	0	2" | sudo tee -a /etc/fstab

## setup systemd to automount
sudo systemctl daemon-reload
sudo systemctl restart local-fs.target

 check that systemd services have been created and are active
TEST=$(systemctl is-active $UNIT_FILE.mount)
if [ ! TEST='active' ]; then
    echo "Service is not active: $UNIT_FILE.mount"
fi

TEST=$(systemctl is-active $UNIT_FILE.automount)
if [ ! TEST='active' ]; then
    echo "Service is not active: $UNIT_FILE.automount"
fi
