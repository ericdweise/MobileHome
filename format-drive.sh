# Formatting a drive to be used as a MobileHome
# ARGS:
#  1. Device path, e.g. /dev/sdb

set -euo pipefail


format_drive () {
    # ARGS:
    #  1. Block Device Path, e.g. /dev/sdb
    echo "*** Formatting Drive"

    # Make sure $1 is a block device
    if ! [[ -b $1 ]]; then
        echo "Not a block device: $1" 1>&2
        exit 1
    fi

    # Double check that user wants to wipe drive
    read -p "Are you sure you want to wipe $1 (type 'YES'): " answer
    if ! [[ $answer == 'YES' ]]; then
        echo "Exiting before wiping drive" 1>&2
        exit 1
    fi

    # Wipe drive
    echo "*** Wiping"
    sudo dd if=/dev/zero of=$1 bs=10M count=1

    # Create new partition table
    echo "*** Adding partition table and partitioning drive"
    sudo sfdisk $1 < partitions.sfdisk
}


add_contact_info () {
    # ARGS:
    #  1. Partition Device Path, e.g. /dev/sdb1
    echo "*** Setting up contact information on partition: $1"

    if ! [[ -b $1 ]]; then
        echo "Not a block device: $1" 1>&2
        exit 1
    fi

    # Make NTFS "Please return / contact info" partition
    sudo mkdosfs $DOS_PART
    TEMP_DIR=$(mktemp -d)
    sudo mount $DOS_PART $TEMP_DIR

    CONTACT_FILE="$TEMP_DIR/IF_FOUND_PLEASE_RETURN.txt"
    echo 'Put your contact info into the unencrypted partition so people can return a lost drive to you:'

    printf "Hi stranger,

    I'm an idiot and managed to loose my flashdrive.
    If you found it please contact me and I will be eternally grateful!\n\n" | sudo tee $CONTACT_FILE

    read -p 'Add your email: ' answer
    echo "Email: $answer" | sudo tee -a $CONTACT_FILE

    read -p 'Add your phone number: ' answer
    echo "Phone: $answer" | sudo tee -a $CONTACT_FILE

    sudo umount $TEMP_DIR
    rm -r $TEMP_DIR
}


format_luks () {
    # ARGS:
    #  1. Partition Device Path, e.g. /dev/sdb2
    echo "*** Setting up LUKS encryption on $1 ***"

    if ! [[ -b $1 ]]; then
        echo "Not a block device: $1" 1>&2
        exit 1
    fi

    # LUKS
    sudo cryptsetup luksFormat $1

    # Filesystem
    echo '*** Decrypt drive to set up filesystem. (Enter encryption password again)'
    sudo cryptsetup luksOpen $1 temp
    sudo mkfs.ext4 /dev/mapper/temp
    sudo cryptsetup luksClose temp

    # Verify encryption information
    sudo cryptsetup luksDump $1
}


# MAIN
DOS_PART=$1'1'
LUKS_PART=$1'2'

format_drive $1
add_contact_info $DOS_PART
format_luks $LUKS_PART

echo '*** All finished'
