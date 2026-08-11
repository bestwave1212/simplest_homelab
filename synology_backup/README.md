# Synology Backup

Backup shire data to Synology NAS via SMB using BorgBackup 2 with native deduplication and compression.

## Overview

- **Target**: `\\100.103.156.58\backupShire`
- **Mount**: `/mnt/synology_backup`
- **Method**: BorgBackup 2 with deduplication and compression
- **Schedule**: Runs after `btrbk_gondor.service` completes
- **Timer**: Daily at 01:00 (weekly via dependency on gondor)
- **Retention**: 52 weekly archives (~1 year)

## Data Backed Up

- `/mnt/data/cloud`
- `/mnt/data/immich`
- `/var/lib/docker/volumes`

## Features

- **Deduplication**: Borg native deduplication (no Synology-side dedup needed)
- **Compression**: zstd level 3 (configurable in script)
- **Encryption**: repokey encryption (passphrase in `.borg_passphrase`)
- **Incremental**: Only changed chunks are transferred
- **Archives**: Timestamped Borg archives (e.g., `cloud-20260421T0100`)

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

2. Create Borg passphrase file (used for repo encryption):
```bash
cd /home/bestwave/simplest_homelab/synology_backup
sudo tee .borg_passphrase <<'EOF'
your_secure_passphrase_here
EOF
sudo chmod 600 .borg_passphrase
```

3. Test SMB access:
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

The script will automatically install `borgbackup2` via apt if `borg2` is not found.

### Verify

```bash
sudo systemctl status btrbk_stationMir.timer --no-pager
borg2 --version
```

### Manual Run (as root)

```bash
# Option A: Run via systemd (recommended)
sudo systemctl start btrbk_stationMir.service

# Option B: Run directly as root (if you have root password)
su -
/home/bestwave/simplest_homelab/synology_backup/backup_stationMir.sh
exit

# Option C: Via sudo (requires entering password)
echo "your_password" | sudo -S /home/bestwave/simplest_homelab/synology_backup/backup_stationMir.sh
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

### List Available Archives

```bash
borg2 list /mnt/synology_backup/borg_repo
```

### List Files in an Archive

```bash
borg2 list /mnt/synology_backup/borg_repo::cloud-20260421T0100
```

### Restore a Subvolume

```bash
# Example: restore immich
ARCHIVE="cloud-20260421T0100"

# Stop the service using the data
sudo systemctl stop immich

# Restore from archive
cd /mnt/data
borg2 extract /mnt/synology_backup/borg_repo::$ARCHIVE

# Restart service
sudo systemctl start immich
```

### Mount Archive (Browse Files)

```bash
# Mount archive to browse files
mkdir -p /tmp/borg_mount
borg2 mount /mnt/synology_backup/borg_repo::cloud-20260421T0100 /tmp/borg_mount
ls /tmp/borg_mount
# When done:
borg2 umount /tmp/borg_mount
```

### Restore Docker Volumes

```bash
# Example: restore docker volumes
ARCHIVE="var-lib-docker-volumes-20260421T0100"

# Stop Docker
sudo systemctl stop docker

# Restore
cd /var/lib/docker
borg2 extract /mnt/synology_backup/borg_repo::$ARCHIVE

# Start Docker
sudo systemctl start docker
```

### Restore from Different Host

If shire is failed, restore from Synology to a new host:

```bash
# Mount on new host
sudo mount -t cifs //100.103.156.58/backupShire /mnt/synology_backup \
    -o credentials=/path/to/.smbcredentials,uid=0,gid=0

# Install borg2
sudo apt install borgbackup2

# List archives
borg2 list /mnt/synology_backup/borg_repo

# Restore
cd /mnt/data
borg2 extract /mnt/synology_backup/borg_repo::immich-20260421T0100
```

## Troubleshooting

### Borg2 Not Found

The script auto-installs `borgbackup2` via apt. If that fails:

```bash
# Manual install
sudo apt-get update
sudo apt-get install -y borgbackup2

# Verify
borg2 --version
```

### Mount fails

Check credentials:
```bash
cat /home/bestwave/simplest_homelab/synology_backup/.smbcredentials
chmod 600 /home/bestwave/simplest_homelab/synology_backup/.smbcredentials
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

Run manually:
```bash
sudo /home/bestwave/simplest_homelab/synology_backup/backup_stationMir.sh
```

### Verify Backup Integrity

```bash
# List archives
borg2 list /mnt/synology_backup/borg_repo

# Check archive contents
borg2 info /mnt/synology_backup/borg_repo::cloud-20260421T0100

# Check for errors
sudo journalctl -u btrbk_stationMir.service --since "1 hour ago"
```

## Retention Policy

- Keeps 52 weekly archives (~1 year)
- Old archives are automatically pruned by Borg
- Deduplication means unchanged data uses minimal space
- Compression (zstd) reduces storage footprint

## Files

| File | Description |
|------|-------------|
| `backup_stationMir.sh` | Main backup script (BorgBackup 2) |
| `btrbk_stationMir.service` | systemd service |
| `btrbk_stationMir.timer` | systemd timer |
| `install.sh` | Installation script |
| `.smbcredentials` | SMB credentials (not in git) |
| `.borg_passphrase` | Borg passphrase (not in git) |
| `README.md` | This file |
