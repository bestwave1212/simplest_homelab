#!/bin/bash
# Backup shire data to Synology NAS via SMB using BorgBackup 2
# Uses Borg native deduplication and compression

set -e

# Configuration
SYNOLOGY_HOST="100.103.156.58"
SYNOLOGY_SHARE="backupShire"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SMB_CREDENTIALS="$SCRIPT_DIR/.smbcredentials"
MOUNT_POINT="/mnt/synology_backup"
BORG_REPO="$MOUNT_POINT/borg_repo"
export BORG_REPO
BORG_PASSPHRASE="$(cat "$SCRIPT_DIR/.borg_passphrase" 2>/dev/null || echo "")"
export BORG_PASSPHRASE
export BORG_RELOCATED_REPO_ACCESS_IS_OK=yes

# Retention policy: keep 52 weekly archives (~1 year)
RETENTION_WEEKS=52

# Subvolumes to backup
SUBVOLUMES=(
    "/mnt/data/cloud"
    "/mnt/data/immich"
    "/var/lib/docker/volumes"
)

echo "========================================"
echo "Starting BorgBackup 2 to Synology: $SYNOLOGY_HOST"
echo "Repository: $BORG_REPO"
echo "========================================"

# Check borg2 is available
if ! command -v borg2 &> /dev/null; then
    echo "ERROR: borg2 not found. Please install borgbackup2 manually:"
    echo "  sudo apt-get install borgbackup2"
    exit 1
fi

# Mount SMB share if not already mounted
if ! mountpoint -q "$MOUNT_POINT"; then
    echo "Mounting SMB share..."
    mkdir -p "$MOUNT_POINT"
    mount -t cifs //"$SYNOLOGY_HOST/$SYNOLOGY_SHARE" "$MOUNT_POINT" \
        -o credentials="$SMB_CREDENTIALS",uid=0,gid=0,file_mode=0600,dir_mode=0700
fi

# Initialize borg repo if it doesn't exist
if [ ! -d "$BORG_REPO" ]; then
    echo "Initializing Borg repository..."
    borg2 repo-create -e repokey-aes-ocb
fi

# Create archive for each subvolume
TIMESTAMP=$(date +%Y%m%dT%H%M)
echo "Archive timestamp: $TIMESTAMP"

for subvolume in "${SUBVOLUMES[@]}"; do
    if [ ! -e "$subvolume" ]; then
        echo "WARNING: $subvolume does not exist, skipping..."
        continue
    fi

    ARCHIVE_NAME=$(echo "$subvolume" | tr '/' '-' | sed 's/^-//')
    echo "----------------------------------------"
    echo "Backing up: $subvolume"
    echo "Archive: $ARCHIVE_NAME-$TIMESTAMP"
    echo "----------------------------------------"

    borg2 create \
        --stats \
        -C zstd,3 \
        -r "$BORG_REPO" \
        "$ARCHIVE_NAME-$TIMESTAMP" \
        "$subvolume"
done

# Prune old archives based on retention policy
echo "----------------------------------------"
echo "Pruning old archives (keeping $RETENTION_WEEKS weekly)..."
for subvolume in "${SUBVOLUMES[@]}"; do
    ARCHIVE_NAME=$(echo "$subvolume" | tr '/' '-' | sed 's/^-//')
    borg2 prune \
        --list \
        --keep-last "$RETENTION_WEEKS" \
        -r "$BORG_REPO" \
        --prefix "$ARCHIVE_NAME-"
done

echo "----------------------------------------"
echo "Backup completed: $TIMESTAMP"
echo "----------------------------------------"
echo "Done."
