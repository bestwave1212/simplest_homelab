# Cloudflare Tunnel Setup for Jellyfin

## Quick Fix - Using Docker Hub Directly

### Step 1: Login to Docker Hub
```bash
docker login
# Enter your Docker Hub username and password
# Or use an access token from https://hub.docker.com/settings/security
```

### Step 2: Pull Cloudflared
```bash
cd /home/bestwave/simplest_homelab/cloudflare-tunnel
sudo docker compose pull
```

### Step 3: Start the Tunnel
```bash
sudo docker compose up -d
```

### Step 4: Verify
```bash
sudo docker compose ps
# Should show: cloudflared:latest cloudflare-tunnel Up (running)
```

## Alternative: Using Dockerfile (No Docker Hub Login Required)

If you can't login to Docker Hub, create a Dockerfile:

```bash
cat > Dockerfile << 'Dockerfile'
FROM ghcr.io/cloudflare/cloudflared:latest

WORKDIR /app

COPY config.json /app/config.json

RUN mkdir -p /var/run/cloudflared && chmod 777 /var/run/cloudflared

EXPOSE 80 443

CMD ["run", "--no-autoupdate", "--config", "/app/config.json"]
Dockerfile
```

Then build and run:
```bash
sudo docker build -t cloudflare-tunnel .
sudo docker run -d \
  --name cloudflare-tunnel \
  --network host \
  -v /home/bestwave/simplest_homelab/cloudflare-tunnel/config.json:/app/config.json:ro \
  -v /var/run/cloudflared:/var/run/cloudflared:ro \
  cloudflare-tunnel
```

## DNS Configuration

Add these records in Cloudflare Dashboard:
- `jellyfin.ltdm.xyz` → A record → Your public IP
- `adguard.ltdm.xyz` → A record → Your public IP
- `nginx.ltdm.xyz` → A record → Your public IP

Enable proxy (orange cloud) or disable (gray cloud) based on your security needs.

## Troubleshooting

```bash
# View logs
sudo docker compose logs -f cloudflare-tunnel

# Restart
sudo docker compose restart

# Stop
sudo docker compose down
```

## Notes

- The tunnel will create a secure Unix socket for authentication
- All traffic is encrypted through Cloudflare's edge
- The tunnel runs in host network mode for simplicity
- Services must be accessible on localhost (127.0.0.1)
