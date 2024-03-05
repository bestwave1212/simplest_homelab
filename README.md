# lebon
LeBon is the baremetal hypervisor which hosts all the other services. It must be as simple as possible to be able to reinstall it easily because backup the host is not so easy.

Info for reinstalling proxmox on lebon : 
- disconnect ethernet on lan1 and connect lan0 to lepaysan (backup)
- set static ip 192.168.12.2, this will create bridge vmbr0 which correspond to LAN 
- with a third pc, set static ip like 192.168.12.5 and go to bakcup gui and copy its fingerprint (debug: might want to disable old VPN like tailscale, couldn't ping with it)
- connect to lebon gui and add a storage in "Datacenter", button "Add", then "proxmox backup server"


#  Install i217V intel NIC (not working)
This NIC is not working out of the box, must download and compile drivers from intel
```bash
#install dependencies
apt-get install linux-headers-$(uname -r)
apt-get install gcc make

#get drivers
wget https://downloadmirror.intel.com/15817/eng/e1000e-3.8.4.tar.gz
tar zxf e100
cd e1000e-3.8.4/src/
make install
modprobe e1000e insmod e1000e
```

# Enable passthrough
Follow passthrough guide : https://www.reddit.com/r/homelab/comments/b5xpua/the_ultimate_beginners_guide_to_gpu_passthrough/
```bash
#Enable IOMMU
nano /etc/default/grub
# GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"
update-grub
```

```bash
#check iommu on & check iommu grouping
#load VFIO modules
nano /etc/modules
```
Paste this :

vfio

vfio_iommu_type1

vfio_pci

vfio_virqfd

```bash
#blacklist stat drivers
echo "blacklist ahci" >> /etc/modprobe.d/blacklist.conf
#add SATA controller to vfio
echo "options vfio-pci ids=8086:7ae2"> /etc/modprobe.d/vfio.conf
update-initramfs -u
reboot
```

- Check that driver in use is vfio-pci and not ahci, it works currently only because I have 1 Sata so I can disable all Sata controllers, to choose which sata to passthrough follow this guide : https://gist.github.com/kiler129/4f765e8fdc41e1709f1f34f7f8f41706


- restore pfsense, passthrough NIC1 internet is up !
- add non subscription repo, update, upgrade, reboot

# Backup
When backup is restored, add PBS server to LeBon storage and create a scheduled backup

# TrueNAS
One bug I found was when mounting a NFS share of a dataset with a child dataset. The Child dataset permissions was set to root:root (root of TrueNAS and not of proxmox so very limited access unless you give 777 permissions). A workaround I found on TrueNAS forum was to create a share for the child, although it was already shared by the "parent" dataset. 
To do that in TrueNAS, go to SHARES, then UNIX (NFS) Shares, then ADD. Select the child dataset to share and share to the whole network (the parent share is only shared to one host/ip) to avoid conflict. Also in Advanced options, gite the same Maproot user & Maproot Group as the parent dataset.

# TrueNAS - backup
This is a separate PC to backup everything outside of lebon, used a lot when reinstalling proxmox host. 
Steps to reproduce to use backup
Install TrueNAS 
In router, use dhcp static lease to asign ip addresse 192.168.12.21 to mac address : 2c:60:0c:0d:ac:44
In storage, create a ZVOL named backup
In Datasets, create a dataset proxmox
In Credentials, Local Users, create a user proxmox with its own group
In Shares, create a UNIX share for /mnt/backup/proxmox, for host/ip 192.168.12.2
In Advanced settings, set Maproot User & Maproot group to proxmox

Go to proxmox and mount this NFS share

# NordVPN
connecting using CLI
```bash
#launch login page and type password
nordvpn login
#then paste here the link and change https by nordvpn, like so :
nordvpn login --callback "nordvpn://nordaccount.com/product/nordvpn/login/success?return=1&redirect_upon_open=1&exchange_token=Njk2Yzc2YmRlNmEwMTIzZjJmYmVlODZhMDM1YjdhZTQwZGJmOTkwODk0Yjk5ZjVjNDU4MGI2ZThjNzJjMjYzZg%3D%3D"
nordvpn set autoconnect on Sweden
```

# Nextcloud AIO
Run nextcloud AIO docker inside a LXC : 
- create the LXC container with a fixed ip address + a data folder mounted to store files
- Install docker
- In cloudflare, create a tunnel for http://127.0.0.1:11000
- Disable special feature for nextcloud web page (rocket features)
- run this command :
```bash
sudo docker run \
--init \
--sig-proxy=false \
--name nextcloud-aio-mastercontainer \
--restart always \
--publish 8080:8080 \
--env APACHE_PORT=11000 \
--env APACHE_IP_BINDING=127.0.0.1 \
--env SKIP_DOMAIN_VALIDATION=true \
--env NEXTCLOUD_DATADIR="/mnt/data" \
--volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config \
--volume /var/run/docker.sock:/var/run/docker.sock:ro \
nextcloud/all-in-one:latest
```

# Error solving
I just borked my fav LXC, here is how i fixed it : 
```bash
root@prox:~# pct mount 102
mounted CT 102 in '/var/lib/lxc/102/rootfs'



root@prox:~# lsattr /var/lib/lxc/102/rootfs/etc/resolv.conf
----i---------e---- /var/lib/lxc/102/rootfs/etc/resolv.conf
root@prox:~# chattr -i /var/lib/lxc/102/rootfs/etc/resolv.conf
root@prox:~# lsattr /var/lib/lxc/102/rootfs/etc/resolv.conf
--------------e---- /var/lib/lxc/102/rootfs/etc/resolv.conf
root@prox:~# pct unmount 102
```


# Laptaupe
This is my personal laptop, here is the list of things to do when reinstall : 
```bash
#Fix gamepad issue
```
#Backup both disks using proxmox-backup-client and a systemd service
```bash
#install proxmox-backup-client
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
#sha512sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 7da6fe34168adc6e479327ba517796d4702fa2f8b4f0a9833f5ea6e6b48f6507a6da403a274fe201595edc86a84463d50383d07f64bdde2e3658108db7d6dc87  /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
#md5sum /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 41558dc019ef90bd0f6067644a51cf5b /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg
echo "deb http://download.proxmox.com/debian/pbs-client bookworm main" >> /etc/apt/sources.list.d/proxmox.list
apt-get update
apt-get install proxmox-backup-client
#create bash script
mkdir /root/backup
echo "
#backup laptaupe
export PBS_REPOSITORY=192.168.12.30:8007:backup
export PBS_PASSWORD=to be changed
proxmox-backup-client backup laptaupe_data.pxar:/mnt/data
proxmox-backup-client backup laptaupe.pxar:/" >> /root/backup/backup.sh
echo "#exclude wanted folders here" >> /root/backup/.pxarexclude
#file executable but only readable by root to ensure no password leak
chmod 700 backup.sh
#change password
nano /root/backup/backup.sh
#create service using systemd to execute it everyday
echo "
[Unit]
Description=Backup laptaupe
After=default.target

[Service]
Type=oneshot
WorkingDirectory=/root/backup/
ExecStart=/root/backup/backup.sh" >> /etc/systemd/system/backup_laptaupe.service
#execute this service everyday
echo "[Unit]
Description=Launches laptaupe backup every day at 4am 

[Timer]
OnCalendar=Mon..Sun *-*-* 04:00:00
Persistent=true
Unit=backup_laptaupe.service

[Install]
WantedBy=timers.target" >> /etc/systemd/system/backup_laptaupe.timer

#Start this timer at boot
systemctl enable backup_laptaupe.timer
systemctl status backup_laptaupe.timer
systemctl status backup_laptaupe.service
```

#install my apps

#configure tailscle
