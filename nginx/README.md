# Nginx Reverse Proxy

Nginx runs on [Shire](../SHIRE.md) as a Docker container (`nginx-reverse-proxy`) with `network_mode: host`. It acts as a single entry point for all homelab services, routing `*.ltdm.xyz` subdomains to their respective backends.

## Services

| Subdomain | Backend | Port | WebSocket |
|-----------|---------|------|-----------|
| arcane.ltdm.xyz | arcane | 3552 | yes |
| audiobookshelf.ltdm.xyz | audiobookshelf | 13378 | yes |
| bazarr.ltdm.xyz | bazarr | 6767 | no |
| calibre.ltdm.xyz | calibre-web | 8082 | no |
| jellyfin.ltdm.xyz | jellyfin | 8096 | yes |
| lazylibrarian.ltdm.xyz | lazylibrarian | 5299 | no |
| lidarr.ltdm.xyz | lidarr | 8686 | no |
| lidify.ltdm.xyz | lidify | 5000 | no |
| mealie.ltdm.xyz | mealie | 9925 | no |
| nextcloud.ltdm.xyz | nextcloud-aio | 11000 | yes |
| prowlarr.ltdm.xyz | prowlarr | 9696 | no |
| radarr.ltdm.xyz | radarr | 7878 | no |
| sabnzbd.ltdm.xyz | sabnzbd | 8083 | no |
| seerr.ltdm.xyz | seerr | 5055 | yes |
| slskd.ltdm.xyz | slskd | 5030 | no |
| sonarr.ltdm.xyz | sonarr | 8989 | no |

## How it works

1. DNS: `*.ltdm.xyz` resolves to `192.168.1.5` (via AdGuard Home rewrites)
2. Browser connects to shire on port 80 (HTTP) or 443 (HTTPS)
3. Nginx matches the `server_name` and proxies to the backend on localhost

## Adding a new service

1. Create a new config file in `conf.d/`:
   ```bash
   # conf.d/myapp.conf
   server {
       listen 80;
       listen 443 ssl;
       server_name myapp.ltdm.xyz;

       location / {
           proxy_pass http://127.0.0.1:<port>;
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }
   }
   ```
2. Add a DNS rewrite in AdGuard Home (via web UI at `http://192.168.1.10:80`)
3. Reload nginx: `docker exec nginx-reverse-proxy nginx -s reload`

## SSL / HTTPS with Let's Encrypt

All services use a wildcard certificate (`*.ltdm.xyz`) issued by Let's Encrypt via DNS-01 challenge through the Cloudflare API.

### Setup

#### 1. Install certbot on Shire

```bash
apt install certbot python3-certbot-dns-cloudflare
```

#### 2. Create Cloudflare API token

1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Create token with permissions: **Zone > DNS > Edit** on zone `ltdm.xyz`
3. Save the token:
   ```bash
   mkdir -p /etc/letsencrypt
   cat > /etc/letsencrypt/cloudflare.ini << EOF
   dns_cloudflare_api_token = <YOUR_TOKEN>
   EOF
   chmod 600 /etc/letsencrypt/cloudflare.ini
   ```

#### 3. Request the wildcard certificate

```bash
certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
  -d "*.ltdm.xyz" -d "ltdm.xyz" \
  --agree-tos \
  --email your-email@example.com
```

This creates:
- `/etc/letsencrypt/live/ltdm.xyz/fullchain.pem`
- `/etc/letsencrypt/live/ltdm.xyz/privkey.pem`

#### 4. Mount certs in Docker

Update `docker-compose.yml`:
```yaml
services:
  nginx:
    image: nginx:alpine
    container_name: nginx-reverse-proxy
    restart: unless-stopped
    network_mode: host
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./conf.d:/etc/nginx/conf.d:ro
      - /etc/letsencrypt:/etc/nginx/certs:ro
```

#### 5. Update nginx.conf

```nginx
events {
    worker_connections 1024;
}

http {
    ssl_certificate     /etc/nginx/certs/live/ltdm.xyz/fullchain.pem;
    ssl_certificate_key /etc/nginx/certs/live/ltdm.xyz/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    include /etc/nginx/conf.d/*.conf;
}
```

#### 6. Add `listen 443 ssl` to all server blocks

Each file in `conf.d/` needs `listen 443 ssl;` alongside `listen 80;`.

#### 7. Restart nginx

```bash
docker compose down && docker compose up -d
```

### Auto-renewal

Certbot installs a systemd timer (`certbot.timer`) that runs twice daily. To reload nginx after renewal, create a deploy hook:

```bash
cat > /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh << 'EOF'
#!/bin/bash
docker exec nginx-reverse-proxy nginx -s reload
EOF
chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
```

Test renewal:
```bash
certbot renew --dry-run
```

### Optional: HTTP → HTTPS redirect

Add a catch-all server block at the top of `conf.d/` (e.g., `zzz-redirect.conf`):

```nginx
server {
    listen 80;
    server_name *.ltdm.xyz;
    return 301 https://$host$request_uri;
}
```

> **Note**: Files in `conf.d/` are loaded alphabetically. Prefix with `zzz-` to ensure it's loaded last and doesn't override specific `listen 80` blocks.

## Troubleshooting

### 502 Bad Gateway
The backend service is down or not responding. Check the container:
```bash
docker ps | grep <service>
```

### Certificate not trusted
- Ensure the certbot cert is valid: `openssl x509 -in /etc/letsencrypt/live/ltdm.xyz/fullchain.pem -text -noout`
- For local access, Let's Encrypt certs should be trusted automatically. If not, check your system's CA store.

### nginx won't start after config change
```bash
docker exec nginx-reverse-proxy nginx -t  # test config
docker exec nginx-reverse-proxy nginx -s reload  # reload
```
