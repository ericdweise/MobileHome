# This script is used to backup your mobile home device to another drive.

# ARGS
# 1 - Target DIRECTORY for the backup. (Where mobile home files will be backed up

function last_char () {
    if [ -z $1 ]; then
        return
    fi
    LEN=$((${#1}-1))
    LAST_CHAR=${1:$LEN:1}
}

if [ -z $1 ]; then
    echo "ERROR: Please provide target directory"
    exit '1'
fi

if [ ! -d $1 ]; then
    echo "ERROR: Target provided is not a directory: $1"
    exit '2'
fi

BACKUP_FILE="mobilehome-backup-log-$(date +'%Y-%m-%d').log"

echo "=== BACKING UP MOBILEHOME ===" | tee -a $BACKUP_FILE
echo "=== START TIME: $(date +'%Y-%m-%d %H:%M')" | tee -a $BACKUP_FILE
echo "=== TARGET DEVICE ===" | tee -a $BACKUP_FILE
echo "DEVICE-PATH: $1" | tee -a $BACKUP_FILE

last_char $1
if [[ $LAST_CHAR = '/' ]]; then
    DIRECTORY=${1:0:-1}
else
    DIRECTORY=$1
fi
PART_NAME=$(mount | grep $DIRECTORY | cut -f 1 -d ' ')
BLOCK_NAME=${PART_NAME:0:-1}
lsblk -o +VENDOR,MODEL,UUID,MAJ:MIN,FSAVAIL,MOUNTPOINT,LABEL,SERIAL,SIZE $BLOCK_NAME | tee -a $BACKUP_FILE

# BACKUP
rsync -v -r -c --update \
    --log-file=$BACKUP_FILE \
    --times \
    --update \
    --whole-file \
    --prune-empty-dirs \
    --exclude-from='exclude-file.txt' \
    ../ $1
