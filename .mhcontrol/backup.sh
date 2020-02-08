# This script is used to backup your mobile home device to another drive.

# ARGS
# 1 - Target DIRECTORY for the backup. (Where mobile home files will be backed up

if [ -z $1 ]; then
    echo "ERROR: Please provide target directory"
    exit '1'
fi

if [ ! -d $1 ]; then
    echo "ERROR: Target provided is not a directory: $1"
    exit '2'
fi

rsync -v -r --ignore-existing \
    --exclude-from='exclude-file.txt' \
    ../ $1
