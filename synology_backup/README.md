# Synology Backup

Backup shire data to Synology NAS via SMB using rsync with hardlinked incremental snapshots.

## Overview

- **Target**: `\\100.103.156.58\backupShire`
- **Mount**: `/mnt/synology_backup`
- **Method**: rsync + `--link-dest` for incremental hardlinked backups
- **Schedule**: Runs after `btrbk_gondor.service` completes
- **Timer**: Daily at 01:00 (weekly via dependency on gondor)
- **Retention**: 52 weekly snapshots (~1 year)

## Data Backed Up

- `mnt/data/cloud`
- `mnt/data/immich`
- `var/lib/docker/volumes`

## Features

- **Incremental**: Only changed files are transferred (via rsync)
- **Compression**: Synology native compression (enabled on DSM)
- **Hardlinks**: Unchanged files share storage via hardlinks
- **Snapshots**: Timestamped directories (e.g., `cloud.20260421T0100`)

## Installation

### Prerequisites

1. Create SMB credentials file in the script directory:
```bash
cd /home/bestwave/simplest_homelab/synology_backup
sudo tee .smbcredentials <<'EOF'
username=your_synology_username
password=your_synology_password
EOF
sudo chmod 600 .smbcredentials
```

2. Test SMB access:
```bash
sudo mount -t cifs //100.103.156.58/backupShire /mnt/synology_backup \
    -o credentials=/home/bestwave/simplest_homelab/synology_backup/.smbcredentials,uid=0,gid=0,file_mode=0600,dir_mode=0700
ls /mnt/synology_backup
```

### Install

```bash
cd /home/bestwave/simplest_homelab/synology_backup
sudo ./install.sh --install
```

### Verify

```bash
sudo systemctl status btrbk_stationMir.timer --no-pager
```

## Reinstallation

If you need to reinstall after system changes:

```bash
# Stop and disable timer
sudo systemctl stop btrbk_stationMir.timer
sudo systemctl disable btrbk_stationMir.timer

# Remove old systemd files
sudo rm /etc/systemd/system/btrbk_stationMir.service
sudo rm /etc/systemd/system/btrbk_stationMir.timer
sudo systemctl daemon-reload

# Reinstall
cd /home/bestwave/simplest_homelab/synology_backup
sudo ./install.sh --install
```

## Manual Backup

To run a backup manually:

```bash
sudo /home/bestwave/simplest_homelab/synology_backup/backup_stationMir.sh
```

## Restore

### List Available Snapshots

```bash
ls -la /mnt/synology_backup/snapshots/
```

### Restore a Subvolume

```bash
# Example: restore immich
TIMESTAMP="20260421T0100"
DEST="/mnt/data/immich"

# Stop the service using the data
sudo systemctl stop immich

# Restore from snapshot
sudo rm -rf "$DEST"
sudo cp -a /mnt/synology_backup/snapshots/immich."$TIMESTAMP"/. "$DEST/"

# Restart service
sudo systemctl start immich
```

### Restore Docker Volumes

```bash
# Example: restore docker volumes
TIMESTAMP="20260421T0100"

# Stop Docker
sudo systemctl stop docker

# Restore
sudo rm -rf /var/lib/docker/volumes/*
sudo cp -a /mnt/synology_backup/snapshots/var-lib-docker-volumes."$TIMESTAMP"/. /var/lib/docker/volumes/

# Start Docker
sudo systemctl start docker
```

### Restore from Different Host

If shire is failed, restore from Synology to a new host:

```bash
# Mount on new host
sudo mount -t cifs //100.103.156.58/backupShire /mnt/synology_backup \
    -o credentials=/root/.smbcredentials,uid=0,gid=0

# Copy data
TIMESTAMP="20260421T0100"
sudo cp -a /mnt/synology_backup/snapshots/immich."$TIMESTAMP"/ /mnt/data/immich
```

## Troubleshooting

### Mount fails

Check credentials:
```bash
sudo cat /home/bestwave/simplest_homelab/synology_backup/.smbcredentials
sudo chmod 600 /home/bestwave/simplest_homelab/synology_backup/.smbcredentials
```

Test connection:
```bash
smbclient -L //100.103.156.58 -U username
```

### Backup fails

Check logs:
```bash
sudo journalctl -u btrbk_stationMir.service -n 50
```

Run manually with verbose output:
```bash
sudo bash -x /home/bestwave/simplest_homelab/synology_backup/backup_stationMir.sh
```

### Verify Backup Integrity

```bash
# Check snapshot exists
ls /mnt/synology_backup/snapshots/

# Compare file counts
find /mnt/data/immich -type f | wc -l
find /mnt/synology_backup/snapshots/immich.* -type f | wc -l

# Check for errors
sudo journalctl -u btrbk_stationMir.service --since "1 hour ago"
```

## Retention Policy

- Keeps 52 weekly snapshots
- Old snapshots are automatically cleaned up
- Uses hardlinks, so deleted snapshots don't free space if files still exist in other snapshots

## Files

| File | Description |
|------|-------------|
| `backup_stationMir.sh` | Main backup script |
| `btrbk_stationMir.service` | systemd service |
| `btrbk_stationMir.timer` | systemd timer |
| `install.sh` | Installation script |
| `README.md` | This file |