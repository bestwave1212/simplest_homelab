#!/bin/sh
# Backup shire data to Synology NAS via SMB
# Uses rsync with --link-dest for hardlinked incremental backups

set -e

# Configuration
SYNOLOGY_HOST="100.103.156.58"
SYNOLOGY_SHARE="backupShire"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SMB_CREDENTIALS="$SCRIPT_DIR/.smbcredentials"
MOUNT_POINT="/mnt/synology_backup"
SNAPSHOT_DIR="$MOUNT_POINT/snapshots"
TIMESTAMP=$(date +%Y%m%dT%H%M)
RETENTION_WEEKS=1

# Subvolumes to backup
SUBVOLUMES="
mnt/data/cloud
mnt/data/immich
var/lib/docker/volumes
"

echo "========================================"
echo "Starting backup to Synology: $SYNOLOGY_HOST"
echo "Timestamp: $TIMESTAMP"
echo "========================================"

# Mount SMB share if not already mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Mounting SMB share..."
    mount -t cifs //"$SYNOLOGY_HOST/$SYNOLOGY_SHARE" "$MOUNT_POINT" \
        -o credentials="$SMB_CREDENTIALS",uid=0,gid=0,file_mode=0600,dir_mode=0700
fi

# Create snapshot directory
mkdir -p "$SNAPSHOT_DIR"

# Backup each subvolume
for subvolume in $SUBVOLUMES; do
    SRC_PATH="/$subvolume"
    DEST_NAME=$(echo "$subvolume" | tr '/' '-')
    DEST_PATH="$SNAPSHOT_DIR/${DEST_NAME}.${TIMESTAMP}"
    DEST_DIR="$SNAPSHOT_DIR"

    # Find previous snapshot for this specific subvolume
    PREVIOUS_SNAPSHOT=$(ls -td "$SNAPSHOT_DIR/${DEST_NAME}".* 2>/dev/null | head -1)

    # Skip if source doesn't exist
    if [ ! -e "$SRC_PATH" ]; then
        echo "WARNING: Source $SRC_PATH does not exist, skipping..."
        continue
    fi

    echo "----------------------------------------"
    echo "Backing up: $SRC_PATH"
    echo "Destination: $DEST_PATH"
    echo "Previous: $PREVIOUS_SNAPSHOT"
    echo "----------------------------------------"

    # Create parent directory
    mkdir -p "$DEST_DIR"

    # Run rsync with link-dest for hardlink incremental backup
    if [ -n "$PREVIOUS_SNAPSHOT" ] && [ -d "$PREVIOUS_SNAPSHOT" ]; then
        rsync -aH --delete --link-dest="$PREVIOUS_SNAPSHOT" "$SRC_PATH/" "$DEST_PATH/"
    else
        echo "No previous snapshot found, doing full backup..."
        rsync -aH --delete "$SRC_PATH/" "$DEST_PATH/"
    fi

    echo "Completed: $SRC_PATH"
done

# Cleanup old snapshots (keep 52 weeks)
echo "----------------------------------------"
echo "Cleaning up old snapshots (keeping $RETENTION_WEEKS weeks)..."
find "$SNAPSHOT_DIR" -maxdepth 1 -type d -name "*.2*" | \
    sort -r | tail -n +$((RETENTION_WEEKS + 1)) | xargs -r rm -rf

echo "----------------------------------------"
echo "Backup completed: $TIMESTAMP"
echo "----------------------------------------"

end_ts=$(date +%s)
echo "Done."
