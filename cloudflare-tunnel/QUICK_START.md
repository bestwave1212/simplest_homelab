# Quick Start Guide - Cloudflare Tunnel for Jellyfin Home Lab

## TL;DR - 5 Minute Setup

### Step 1: Get Your Tunnel Token

```bash
# Get token from Cloudflare Zero Trust Dashboard
# Go to: one.dash.cloudflare.com > Zero Trust > Access > Tunnel Configuration
# Click "Get tunnel config" and copy the token
```

### Step 2: Create .env File

```bash
cd /home/bestwave/simplest_homelab/cloudflare-tunnel

# Create .env file
cat > .env << 'ENVFILE'
CF_TUNNEL_TOKEN=your-actual-tunnel-token-here
JELLYFIN_PUBLISHED_SERVER_URL=https://jellyfin.ltdm.xyz
INIT_ADMIN=admin
INIT_ADMIN_PASSWORD=your-sync-password
ENVFILE
```

### Step 3: Copy Config Template

```bash
# Copy template to production config
cp config/config.json.template config/config.json

# Edit config.json to replace TOKEN placeholder
nano config/config.json
```

### Step 4: Start Tunnel

```bash
# Start tunnel only
docker-compose up -d cloudflare-tunnel

# Check it's working
docker logs cloudflare-tunnel -f
```

### Step 5: Verify

```bash
# Test Jellyfin
curl -I https://jellyfin.ltdm.xyz

# Test OpenWebUI
```

---

## Complete Service List

| Domain | Internal Address | Purpose |
|--------|------------------|---------|
| jellyfin.ltdm.xyz | 192.168.1.5:8096 | Media server |
| arcane.ltdm.xyz | 192.168.1.5:3552 | App dashboard |
| sync.ltdm.xyz | 192.168.1.5:8081 | File sync |
| calibre.ltdm.xyz | 192.168.1.5:8082 | E-book manager |
| bazarr.ltdm.xyz | 192.168.1.5:6767 | Subtitle manager |
| sabnzbd.ltdm.xyz | 192.168.1.5:8080 | NZB downloader |
| lidarr.ltdm.xyz | 192.168.1.5:8686 | Music manager |
| lidify.ltdm.xyz | 192.168.1.5:5000 | Music metadata |
| seerr.ltdm.xyz | 192.168.1.5:5055 | Request manager |
| sonarr.ltdm.xyz | 192.168.1.5:8989 | TV manager |
| radarr.ltdm.xyz | 192.168.1.5:7878 | Movie manager |
| prowlarr.ltdm.xyz | 192.168.1.5:9696 | Indexer manager |
| lazylibrarian.ltdm.xyz | 192.168.1.5:5299 | Book manager |
| audiobookshelf.ltdm.xyz | 192.168.1.5:13378 | Audiobook manager |
| slskd.ltdm.xyz | 192.168.1.5:5030 | File sharing |

---

## Important Notes

### ✅ What Works

- All web services (HTTP/HTTPS)
- SSL/TLS via Cloudflare auto-provisioning
- WAF and DDoS protection
- No open ports on router
- Secure encrypted tunnel

### ⚠️ Special Cases

**AdGuard Home** - Uses macvlan network
- Cannot be tunneled directly
- Use Tailscale or reconfigure to bridge network

**UDP Services** - SSDP, UPnP, WebSockets
- May need direct IP access for device discovery
- Consider mDNS alternative for some clients

### 🔐 Security Checklist

- [ ] All services have strong passwords
- [ ] Cloudflare WAF is enabled
- [ ] Rate limiting is configured
- [ ] SSL/TLS is enforced
- [ ] Two-factor auth is enabled where possible

---

## Troubleshooting Quick Commands

```bash
# Check tunnel status
docker-compose ps cloudflare-tunnel

# View tunnel logs
docker logs cloudflare-tunnel -f

# Restart tunnel
docker-compose restart cloudflare-tunnel

# Stop tunnel
docker-compose stop cloudflare-tunnel

# Start tunnel
docker-compose up -d cloudflare-tunnel
```

---

## Next Steps

1. **Test**: Verify all services are accessible
2. **Configure**: Set up Cloudflare WAF rules
3. **Secure**: Enable 2FA on all services
4. **Monitor**: Set up alerts for tunnel status
5. **Document**: Update your network documentation

---

## Files Created

```
/home/bestwave/simplest_homelab/cloudflare-tunnel/
├── docker-compose.yml          # Main compose file
├── README.md                   # Full documentation
├── SETUP.md                    # Detailed setup guide
├── QUICK_START.md              # This file
└── config/
    └── config.json.template    # Tunnel config template
```

---

## Useful Links

- [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/)
- [Docker Cloudflared Image](https://hub.docker.com/r/cloudflared/cloudflared)

---

**Need help?** Check the full README.md or SETUP.md for detailed instructions.
