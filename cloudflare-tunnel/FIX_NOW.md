# FIX YOUR CLOUDFLARE TUNNEL NOW

## Problem
Docker Hub requires login for cloudflared:latest image.

## Solution 1: Login to Docker Hub (RECOMMENDED)

```bash
# Login to Docker Hub
docker login

# Then start the tunnel
cd /home/bestwave/simplest_homelab/cloudflare-tunnel
sudo docker compose up -d
```

## Solution 2: Use Public Registry Mirror

```bash
# Configure Docker to use mirror
cat > /etc/docker/daemon.json << 'DAEMON'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn"
  ]
}
DAEMON

# Restart Docker
sudo systemctl restart docker

# Then start the tunnel
cd /home/bestwave/simplest_homelab/cloudflare-tunnel
sudo docker compose up -d
```

## Solution 3: Use Alternative Image

```bash
# Pull from Docker Scout (public)
docker pull public.ecr.aws/cloudflare/cloudflared:latest

# Update docker-compose.yml
cat > docker-compose.yml << 'COMPOSE'
services:
  cloudflare-tunnel:
    image: public.ecr.aws/cloudflare/cloudflared:latest
    container_name: cloudflare-tunnel
    network_mode: host
    restart: unless-stopped
    volumes:
      - ./config.json:/app/config.json:ro
      - /var/run/cloudflared:/var/run/cloudflared:ro
    command:
      - run
      - --no-autoupdate
      - --config
      - /app/config.json
COMPOSE

# Start
sudo docker compose up -d
```

## Quick Commands

```bash
# Start tunnel (after login or mirror setup)
cd /home/bestwave/simplest_homelab/cloudflare-tunnel
sudo docker compose up -d

# Check status
sudo docker compose ps

# View logs
sudo docker compose logs -f

# Test access
curl https://jellyfin.ltdm.xyz
```

## DNS Setup

In Cloudflare Dashboard → DNS → Add Record for each domain:
- jellyfin.ltdm.xyz → A → Your IP
- adguard.ltdm.xyz → A → Your IP  
- nginx.ltdm.xyz → A → Your IP

Enable proxy (orange cloud) for Cloudflare protection.
