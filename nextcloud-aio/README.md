# Nextcloud AIO

Nextcloud All-in-One, deployed like the other services in this repo.

## Setup

```bash
cd nextcloud-aio
docker compose up -d
```

## Access

- Mastercontainer UI (initial setup): https://192.168.1.5:8088
- Nextcloud (public): https://nextcloud.ltdm.xyz (Cloudflare tunnel -> http://127.0.0.1:11000)
- Nextcloud (LAN): http://192.168.1.5:11000

## First run

1. Open https://192.168.1.5:8088 (use the IP, not a domain, to avoid HSTS issues).
2. The initial passphrase is shown on the setup page (`/setup`); it is also stored in `/mnt/docker-aio-config/data/configuration.json` on the mastercontainer.
3. Set the domain to `nextcloud.ltdm.xyz` (domain validation is skipped).
4. Enable "Disable special feature for the Nextcloud web page".
5. Start the containers and wait until everything is healthy.

## Notes

- Data lives in `/mnt/data/cloud/nextcloud` (part of the `cloud` btrfs subvolume, covered by btrbk backups).
- Apache binds `0.0.0.0:11000`; the mastercontainer UI is on `8088`.
- Caveat: compose cannot pass `--sig-proxy=false`. On `docker compose down` some AIO helper containers may stay in a stopping state; recover with `docker compose restart` or `docker restart <container>`.
