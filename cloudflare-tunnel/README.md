# Cloudflare Tunnel Setup for Jellyfin & Homelab

## Quick Start

1. **Start the tunnel:**
```bash
cd /home/bestwave/simplest_homelab/cloudflare-tunnel
sudo docker-compose up -d
```

2. **Verify it's running:**
```bash
sudo docker-compose ps
```

3. **Access your services:**
- jellyfin.ltdm.xyz
- adguard.ltdm.xyz
- nginx.ltdm.xyz

## How it works

This uses Cloudflared (official Cloudflare tunnel) in host network mode to expose your local services securely through Cloudflare's edge.

## Configuration

The tunnel uses a single ingress rule that routes traffic based on hostname:
- `jellyfin.ltdm.xyz` → localhost:8096
- `adguard.ltdm.xyz` → localhost:3000
- `nginx.ltdm.xyz` → localhost:80

## Maintenance

**View logs:**
```bash
sudo docker-compose logs -f
```

**Restart:**
```bash
sudo docker-compose restart
```

**Stop:**
```bash
sudo docker-compose down
```

## DNS Setup

Make sure your DNS records are set up in Cloudflare:
- A records pointing to your public IP (or using Cloudflare's proxy)
- Or use Cloudflare's automatic tunnel DNS if configured in dashboard
