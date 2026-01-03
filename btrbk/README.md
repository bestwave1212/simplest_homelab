# BTRBK
Use btrbk for all non CT/VM backups. Create btrfs snapshots on shire and push copies on remote servers gondor & stationMIR.
Every btrbk action is controlled by shire. That is why each server has its own configuration file.
Use btrbk_update.sh to update the configuration file of btrbk, to the values of the btrbk_*.conf in this directory and create/check for systemd routine to execute backup.

## Initialisation
First, you need to have btrfs installed and subvolumes mounted on shire and remote server.
```bash 
# Install btrbk
sudo apt update
sudo apt install btrbk
```
```bash 
# Configure shire for remote connection
sudo ssh-keygen -t rsa -b 4096 -f /etc/btrbk/ssh/id_rsa -C thomas.arcier@proton.me -N ""
sudo ssh-copy-id -i /etc/btrbk/ssh/id_rsa root@192.168.1.6
ssh root@192.168.1.6
# While you are connected, Configure gondor for remote connection
nano /etc/ssh/sshd_config 
# Change : PermitRootLogin prohibit-password
# Add : Match Address 192.168.0.42 #add exception for shire while using btrbk
exit #all done, back to shire
```

```bash 
# Use this repo to configure btrbk
git clone https://github.com/bestwave1212/simplest_homelab.git
cd simplest_homelab
cd btrbk
# Dry run, copy local files to system files
sudo ./btrbk_update.sh
# Does it seems to work ? Try to drink more water
sudo ./btrbk_update.sh --install
systemctl status btrbk_shire
```