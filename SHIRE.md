# Shire Server

Shire is a Proxmox baremetal host. It hosts all Docker services and manages the storage.

## Init

```bash
apt-get update
apt-get dist-upgrade -y
apt-get install sudo
adduser bestwave
usermod -aG sudo bestwave
reboot
# install tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-routes 192.168.1.0/24 --advertise-exit-node
```

## Routines

### Backup
Every day at 1am, take a snapshot of files and backups of Shire.
Every Monday at 1am, after Shires snapshot, push all snapshots to Gondor
