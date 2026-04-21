# BTRBK
Use btrbk for all non CT/VM backups. Create btrfs snapshots on shire and push copies on remote servers gondor & stationMIR.
Every btrbk action is controlled by shire. That is why each server has its own configuration file.
Use btrbk_update.sh to update the configuration file of btrbk, to the values of the btrbk_*.conf in this directory and create/check for systemd routine to execute backup.

## Initialisation
First, you need to have btrfs installed and subvolumes mounted on shire and remote server.
```bash 
# Install btrbk
sudo apt update
sudo apt install btrbk wakeonlan
```
```bash 
# Configure shire for remote connection
sudo ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -C thomas.arcier@proton.me -N ""
sudo ssh-copy-id -i /root/.ssh/id_rsa root@192.168.1.6
ssh root@192.168.1.6
# While you are connected, Configure gondor for remote connection
nano /etc/ssh/sshd_config 
# Change : PermitRootLogin prohibit-password
# Add : Match Address 192.168.0.42 #add exception for shire while using btrbk
exit #all done, back to shire
```

```bash 
# Use this repo to configure btrbk
git clone https://github.com/bestwave1212/simplest_homelab.git
cd simplest_homelab
cd btrbk
# Dry run, copy local files to system files
sudo ./btrbk_update.sh
# Does it seems to work ? Try to drink more water
sudo ./btrbk_update.sh --install
systemctl status btrbk_shire
```

## Docker Volumes Backup

Docker volumes are backed up using btrbk with their own snapshot directory.

### How it works

1. `/var/lib/docker/volumes` is a btrfs subvolume on the root filesystem (`/`)
2. Snapshots are stored in `/@snapshots/docker/`
3. Snapshots are pushed to gondor (remote backup server) via `btrbk_gondor.conf`
4. A symlink ensures `/var/lib/docker/volumes` is accessible at the expected path

### Retention policy

Same as other subvolumes: `8h 7d 0w 1m 1y`

### Verify snapshots

**Local (root filesystem):**
```bash
ls /@snapshots/docker/
sudo btrfs subvolume list / | grep docker
```

**Local backup (/mnt/data/@snapshots/):**
```bash
ls /mnt/data/@snapshots/ | grep docker
```
Note: Docker snapshots are NOT stored here (different filesystem)

**Remote (gondor):**
```bash
ssh root@192.168.1.6 "ls /mnt/backup/shire/" | grep docker
ssh root@192.168.1.6 "sudo btrfs subvolume list /mnt/backup/shire/ | grep docker"
```

**Full btrbk status:**
```bash
sudo btrbk -c /etc/btrbk/btrbk_shire.conf list snapshots
sudo btrbk -c /etc/btrbk/btrbk_gondor.conf list snapshots
```

### Troubleshooting

If `btrbk_shire.service` fails with "Snapshot path is not on same filesystem":
- Ensure docker snapshots use their own `snapshot_dir` on root (`/@snapshots/docker`)
- Check with: `sudo btrbk dryrun -c /etc/btrbk/btrbk_shire.conf`

### Restore Docker Volumes

#### Restore from local snapshot

1. List available snapshots:
   ```bash
   ls /@snapshots/docker/
   ```

2. Stop Docker:
   ```bash
   sudo systemctl stop docker
   ```

3. Remove current docker volumes:
   ```bash
   sudo rm -rf /var/lib/docker/volumes/*
   ```

4. Copy data from snapshot:
   ```bash
   sudo cp -a /@snapshots/docker/volumes.YYYYMMDDTHHMM/. /var/lib/docker/volumes/
   ```

5. Start Docker and verify:
   ```bash
   sudo systemctl start docker
   docker volume ls
   ```

#### Restore from gondor (remote backup)

1. List available snapshots on gondor:
   ```bash
   ssh root@192.168.1.6 "ls /mnt/backup/shire/" | grep volumes
   ```

2. Stop Docker:
   ```bash
   sudo systemctl stop docker
   ```

3. Create a temporary snapshot on gondor and send it to shire:
   ```bash
   # On gondor: make a writable snapshot
   ssh root@192.168.1.6 "sudo btrfs subvolume snapshot /mnt/backup/shire/volumes.YYYYMMDDTHHMM /mnt/backup/shire/volumes_restore"

   # Receive on shire
   sudo btrfs receive /@snapshots/docker/ <<< $(ssh root@192.168.1.6 "sudo btrfs send /mnt/backup/shire/volumes_restore")
   ```

4. Remove current docker volumes and restore:
   ```bash
   sudo rm -rf /var/lib/docker/volumes/*
   sudo cp -a /@snapshots/docker/volumes_restore/. /var/lib/docker/volumes/
   ```

5. Cleanup and start Docker:
   ```bash
   sudo btrfs subvolume delete /@snapshots/docker/volumes_restore
   ssh root@192.168.1.6 "sudo btrfs subvolume delete /mnt/backup/shire/volumes_restore"
   sudo systemctl start docker
   docker volume ls
   ```

#### Restore a single volume

If you only need to restore one specific volume:

1. Find the volume name in the snapshot:
   ```bash
   ls /@snapshots/docker/volumes.YYYYMMDDTHHMM/
   ```

2. Stop the container using that volume:
   ```bash
   docker stop <container_name>
   ```

3. Copy only that volume:
   ```bash
   sudo cp -a /@snapshots/docker/volumes.YYYYMMDDTHHMM/<volume_name>/. /var/lib/docker/volumes/<volume_name>/
   ```

4. Restart the container:
   ```bash
   docker start <container_name>
   ```