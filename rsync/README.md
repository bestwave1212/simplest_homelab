# RSYNC
It manages backups between stationMIR and Shire. They are connected through VPN via tailscale.
## Initialisation
```bash
sudo apt install rsync
sudo useradd rsync -m -G users
sudo passwd rsync
su - rsync
git clone https://github.com/BestWave/simplest_homelab.git
cd simplest_homelab/rsync
# Make sure you already have ssh key
cat /root/.ssh/id_rsa

```