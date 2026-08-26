# Shire Weekly Report

Weekly health report for Shire (192.168.1.5). Runs every Monday at 1am, after the btrbk backup completes.

## What it does

1. **Apt upgrades** — checks and applies package updates
2. **Docker image updates** — pulls latest images for all running containers, restarts those with new images
3. **Health data collection** — disk, memory, CPU load, uptime, inodes
4. **Email report** — sends a formatted summary to the address in `/home/bestwave/.shire-email`

## Schedule

- **When:** Every Monday at 01:00
- **Guard:** Waits up to 2h after `btrbk_gondor.service` finishes (via `OnUnitActiveAfter`)
- **Log:** `/home/bestwave/shire-weekly.log`

## Install / update

```bash
cd /home/bestwave/simplest_homelab/btrbk
sudo ./btrbk_update.sh --install
```

This copies the service and timer to `/etc/systemd/system/`, reloads systemd, and enables the timer.

## Verify

```bash
# Check timer status
systemctl status shire_weekly.timer

# Check last run
journalctl -u shire_weekly.service -n 50

# Check last run timestamp
cat /home/bestwave/.shire-weekly-last-run

# View the latest report
cat /home/bestwave/shire-weekly.log
```

## Manual run

```bash
sudo systemctl start shire_weekly.service
```

## Email config

The recipient address is stored in `/home/bestwave/.shire-email`. Update it to change where reports are sent.

## See also

- [btrbk/README.md](btrbk/README.md) — btrfs backup setup
- [SHIRE.md](../SHIRE.md) — Shire server setup
