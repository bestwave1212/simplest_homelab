# Middle earth

Yes, the theme is middle earth and all servers are named after a special place of this land.

- **Shire** (formerly LeBon) — Proxmox baremetal host, always up, runs all Docker services
- **Gondor** — backup server, the last shield that protects the realm of men
- **Laptaupe** — personal laptop

---

## Services on Shire

| Service | LAN URL | Domain | Directory |
|---------|---------|--------|-----------|
| Nextcloud AIO | http://192.168.1.5:11000 | nextcloud.ltdm.xyz | [nextcloud-aio/](nextcloud-aio/) |
| Cloudflare Tunnel | — | *.ltdm.xyz | [cloudflare-tunnel/](cloudflare-tunnel/) |
| Nginx (reverse proxy) | http://192.168.1.5 | — | [nginx/](nginx/) |
| Servarr stack | http://192.168.1.5 | *.ltdm.xyz | [servarr/](servarr/) |
| AdGuard Home | http://192.168.1.5:3000 | adguard.ltdm.xyz | [adguard/](adguard/) |
| Rsync | — | — | [rsync/](rsync/) |
| Synology Backup | — | — | [synology_backup/](synology_backup/) |

## Infrastructure

- **Backup**: btrbk (btrfs snapshots) + Proxmox Backup Server
  - Daily at 1am: local snapshot → push to Gondor & StationMir on Monday
  - See [btrbk/](btrbk/) for configs and [GONDOR.md](GONDOR.md) for backup server docs
- **Disk spindown**: hdparm -S 240 (20min idle) on /dev/sda, /dev/sdb
- **GPU passthrough**: vfio-pci, see [SHIRE.md](SHIRE.md)

## Quick Links

- [SHIRE.md](SHIRE.md) — Shire server setup, Proxmox, GPU passthrough, maintenance
- [GONDOR.md](GONDOR.md) — Gondor backup server & TrueNAS setup
- [LAPTAUPE.md](LAPTAUPE.md) — Laptop reinstall notes
- [DESIGN.md](DESIGN.md) — NoName Project design doc
