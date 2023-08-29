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



#backup
When backup is restored, add PBS server to LeBon storage and create a scheduled backup
