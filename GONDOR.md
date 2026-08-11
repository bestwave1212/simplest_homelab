# Gondor

Gondor is the backup server — "the last shield that protects the realm of men".

- Hostname / IP: `gondor` / `192.168.1.6`
- Not always on: powered on weekly by Shire via Wake-on-LAN, then shut down after the backup

## What it does

Every Monday at 1am, after Shire's local snapshot, Shire pushes btrfs snapshots to Gondor with btrbk.

- Target directory: `/mnt/backup/shire`
- Backed up subvolumes: `/mnt/data/backup/internal`, `/mnt/data/immich`, `/mnt/data/cloud`, servarr media (movies, tv, books, audiobooks, audio), docker volumes
- Retention: `8h 7d 0w 1m 1y`

## Flow

1. Shire creates local snapshots (daily at 1am, `btrbk_shire`).
2. Monday at 1am: `backup_gondor.sh` wakes Gondor with WoL (`2c:60:0c:0d:ac:44`) and waits until it pings.
3. `btrbk run -c /etc/btrbk/btrbk_gondor.conf` pushes the snapshots to `ssh://192.168.1.6/mnt/backup/shire`.
4. Gondor is shut down.

## Install / update

```bash
cd btrbk
sudo ./btrbk_update.sh --install
```

## Verify

```bash
ssh root@192.168.1.6 "ls /mnt/backup/shire/"
sudo btrbk -c /etc/btrbk/btrbk_gondor.conf list snapshots
```

## See also

- [btrbk/README.md](btrbk/README.md) — full btrbk setup, SSH keys, and restore procedures
- [synology_backup/README.md](synology_backup/README.md) — Synology stationMir backup (Borg2, weekly)
