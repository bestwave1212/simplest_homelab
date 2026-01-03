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
# Use this repo to configure btrbk
git clone https://github.com/bestwave1212/simplest_homelab.git
cd simplest_homelab
cd btrbk
sudo ./btrbk_update.sh
```