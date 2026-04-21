# Backup Server

rsync daemon server for Synology NAS backup via Tailscale.

## Setup

```bash
cd rsync
docker compose up -d
```

## Synology Hyper Backup

1. Open **Hyper Backup** → **+** → **Data backup task** → **rsync**
2. Fill in:
   - **Server:** `100.70.204.68`
   - **Port:** `873`
   - **Username:** `bestwave`
   - **Password:** `Jgvvzf97`
   - **Backup module:** `backup`

## Credentials

- **User:** `bestwave`
- **Password:** `Jgvvzf97`
- **rsync module:** `backup`
- **Data path:** `/mnt/data/backup/stationmir`

## Network

- **Tailscale IP:** `100.70.204.68`
- Requires native Tailscale on Synology with subnet route enabled