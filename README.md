# lebon
LeBon is the baremetal hypervisor which hosts all the other services. This host setup must be as simple as possible because backing up the host is not so simple. Instead, create containers to create services or anything.


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

# Spindown disks
Understand the disks
```bash
smartctl -i -n standby /dev/sda
smartctl -i -n standby /dev/sdb
```

Spindown disk after 20min at idle (I want more than 20min)
```bash
hdparm -S 240 /dev/sda
hdparm -S 240 /dev/sdb
```
Check disk powerdown
```bash
smartctl -i -n standby /dev/sda
smartctl -i -n standby /dev/sdb
```

Need to add this at startup

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

# Container installation 
```bash
timedatectl set-timezone Europe/Paris
apt-get update
apt-get dist-upgrade -y
apt-get install sudo
adduser bestwave
#Then type your password
usermod -aG sudo bestwave
reboot

```


# NoName Project
The goal is to go back to the basics and make a host as simple as possible

## Network
Use mainly the ISP router for most things but I want access remotely with a VPN, access some site with domain name, internal DNS for my apps, privacy.
### Access with VPN
Use tailscale or wireguard
### Access with domain name
### Internal DNS
Use PiHole or AdGuardHome to have DNS sinkhole, DNS rewrite, and choose my own DNS (which?) for better privacy

## Storage
The goal is to have a storage on 1 big HDD (big capacity) + 1 SSD (low power). It must be fully reliable and low power. 
### Reliable
The FileSystem must have protection against bitrod and must be easily backup/restored. All data is backup on another machine that will be shutdown most of the time for low power consumption. The backup HDD is exactly the same as the main one. BTRFS seems to be the right candidate for bitrod detection & easy management. Backup is managed with proxmox backup server container. 
If power consumption allow it, it would be cool to have 2 nodes to have full redundancy and high avaibility but this is not the priority.
### Low power 
Spinoff or shutdown the HDD if not used. For this reason, only archive/massive data such as files/media will be on HDD

### Setup
Init disk with GPT
```bash
#install btrfs tools
apt install btrfs-progs
mkfs.btrfs -L data /dev/sda
#Check that you see /dev/sda as registered
btrfs device scan
```

### Init storage
```bash
# Create a btrfs volume for mass storage
which btrfs
sudo mkfs.btrfs /dev/sda
sudo mkdir /mnt/data
sudo mount /dev/sda /mnt/data
sudo chown bestwave:bestwave /mnt/data
sudo btrfs subvolume list


### Init backup
```bash
# Create subvolume to store snapshots
btrfs subvolume create /mnt/data/backup
btrfs subvolume create /mnt/data/backup/mordor
# Use btrbk for snapshot and backup of snapshots
sudo dnf install btrbk
wget LinkToMyConfig
```

```bash
# TA 29122024 Modified to fit my needs from : 
# Example btrbk configuration file
#
#
# Please refer to the btrbk.conf(5) man-page for a complete
# description of all configuration options.
# For more examples, see README.md included with this package.
#
#   btrbk.conf(5): <https://digint.ch/btrbk/doc/btrbk.conf.5.html>
#   README.md:     <https://digint.ch/btrbk/doc/readme.html>
#
# Note that the options can be overridden per volume/subvolume/target
# in the corresponding sections.
#


# Enable transaction log
transaction_log            /var/log/btrbk.log

# Specify SSH private key for remote connections
ssh_identity               /home/bestwave/.ssh/id_rsa
ssh_user                   bestwave

# Use sudo if btrbk or lsbtr is run by regular user
backend_local_user         btrfs-progs-sudo

# Enable stream buffer. Adding a buffer between the sending and
# receiving side is generally a good idea.
# NOTE: If enabled, make sure to install the "mbuffer" package!
stream_buffer              256m

# Directory in which the btrfs snapshots are created. Relative to
# <volume-directory> of the volume section.
# If not set, the snapshots are created in <volume-directory>.
#
# If you want to set a custom name for the snapshot (and backups),
# use the "snapshot_name" option within the subvolume section.
#
# NOTE: btrbk does not automatically create this directory, and the
# snapshot creation will fail if it is not present.
#
snapshot_dir               /mnt/data/backup/internal/

# Always create snapshots. Set this to "ondemand" to only create
# snapshots if the target volume is reachable. Set this to "no" if
# snapshot creation is done by another instance of btrbk.
#snapshot_create            always

# Perform incremental backups (set to "strict" if you want to prevent
# creation of non-incremental backups if no parent is found).
#incremental                yes

# Specify after what time (in full hours after midnight) backups/
# snapshots are considered as a daily backup/snapshot
#preserve_hour_of_day       0

# Specify on which day of week weekly/monthly backups are to be
# preserved.
#preserve_day_of_week       sunday

# Preserve all snapshots for a minimum period of time.
#snapshot_preserve_min      1d

# Retention policy for the source snapshots.
#snapshot_preserve          <NN>h <NN>d <NN>w <NN>m <NN>y

# Preserve all backup targets for a minimum period of time.
#target_preserve_min        no

# Retention policy for backup targets:
#target_preserve            <NN>h <NN>d <NN>w <NN>m <NN>y

# Retention policy for archives ("btrbk archive" command):
#archive_preserve_min       no
#archive_preserve           <NN>h <NN>d <NN>w <NN>m <NN>y

# Enable compression for remote btrfs send/receive operations:
#stream_compress            no
#stream_compress_level      default
#stream_compress_threads    default

# Enable lock file support: Ensures that only one instance of btrbk
# can be run at a time.
#lockfile                   /var/lock/btrbk.lock

# Don't wait for transaction commit on deletion. Enable this to make
# sure the deletion of subvolumes is committed to disk when btrbk
# terminates.
#btrfs_commit_delete no


#
# Volume section (optional): "volume <volume-directory>"
#
#   <volume-directory>  Base path within a btrfs filesystem
#                       containing the subvolumes to be backuped
#                       (usually the mount-point of a btrfs filesystem
#                       mounted with subvolid=5 option).
#
# Subvolume section: "subvolume <subvolume-name>"
#
#   <subvolume-name>    Subvolume to be backuped, relative to
#                       <volume-directory> in volume section.
#
# Target section: "target <type> <volume-directory>"
#
#   <type>              (optional) type, defaults to "send-receive".
#   <volume-directory>  Directory within a btrfs filesystem
#                       receiving the backups.
#
# NOTE: The parser does not care about indentation, this is only for
# human readability. All options apply to the last section
# encountered, overriding the corresponding option of the upper
# section. This means that the global options must be set on top,
# before any "volume", "subvolume" or "target section.
#


#
# Example retention policy:
#
snapshot_preserve_min   2d
snapshot_preserve       14d

target_preserve_min     no
target_preserve         20d 10w *m


#
# Simple setup: Backup root and home to external disk
#
snapshot_dir /btrbk_snapshots
target       /mnt/btr_backup
subvolume    /
subvolume    /home


#
# Complex setup
#
# In order to keep things organized, it is recommended to use "volume"
# sections and mount the top-level subvolume (subvolid=5):
#
#  $ mount -o subvolid=5 /dev/sda1 /mnt/btr_pool
#
# Backup to external disk mounted on /mnt/btr_backup
volume /mnt/btr_pool
  # Create snapshots in /mnt/btr_pool/btrbk_snapshots
  snapshot_dir btrbk_snapshots

  # Target for all subvolume sections:
  target /mnt/btr_backup

  # Some default btrfs installations (e.g. Ubuntu) use "@" for rootfs
  # (mounted at "/") and "@home" (mounted at "/home"). Note that this
  # is only a naming convention.
  #subvolume @
  subvolume root
  subvolume home
  subvolume kvm
    # Use different retention policy for kvm backups:
    target_preserve 7d 4w


# Backup data to external disk as well as remote host
volume /mnt/btr_data
  subvolume  data
    # Always create snapshot, even if targets are unreachable
    snapshot_create always
    target /mnt/btr_backup
    target ssh://backup.my-remote-host.com/mnt/btr_backup


# Backup from remote host, with different naming
volume ssh://my-remote-host.com/mnt/btr_pool
  subvolume data_0
    snapshot_dir   snapshots/btrbk
    snapshot_name  data_main
    target /mnt/btr_backup/my-remote-host.com


# Backup on demand (noauto) to remote host running busybox, login as
# regular user using ssh-agent with current user name (ssh_user no)
# and default credentials (ssh_identity no).
volume /home
  noauto  yes
  compat  busybox
  backend_remote  btrfs-progs-sudo
  ssh_user      no
  ssh_identity  no

  target ssh://my-user-host.com/mnt/btr_backup/home
  subvolume  alice
  subvolume  bob


# Resume backups from remote host which runs its own btrbk instance
# creating snapshots for "home" in "/mnt/btr_pool/btrbk_snapshots".
volume ssh://my-remote-host.com/mnt/btr_pool
  snapshot_dir           btrbk_snapshots
  snapshot_create        no
  snapshot_preserve_min  all
  subvolume home
    target /mnt/btr_backup/my-remote-host.com
```

## APPs
### Backup
That will be used to back up my other machines
### ServArr
### HomeAssistant
### Nextcloud
### Others 
Mealie
habitica

