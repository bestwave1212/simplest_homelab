# lebon
Info for reinstalling proxmox on lebon : 
- disconnect ethernet on lan1 and connect lan0 to lepaysan (backup)
- set static ip 192.168.10.2, this will create bridge vmbr0 which correspond to LAN 
- with a third pc, set static ip like 192.168.10.5 and go to bakcup gui and copy its fingerprint (debug: might want to disable old VPN like tailscale, couldn't ping with it)
- connect to lebon gui and add a storage in "Datacenter", button "Add", then "proxmox backup server"
- create the WAN bridge vmbr1 and associate it with a physical port with internet access, and possibly other test bridges
- restore pfsense, internet is up !
- add non subscription repo, update, upgrade, reboot

Follow passthrough guide : https://www.reddit.com/r/homelab/comments/b5xpua/the_ultimate_beginners_guide_to_gpu_passthrough/
- Enable IOMMU : nano /etc/default/grub -> GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt" -> update-grub
- check iommu on & check iommu grouping
- load VFIO modules : nano /etc/modules
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd

- blacklist stat drivers : echo "blacklist ahci" >> /etc/modprobe.d/blacklist.conf
- add stat controller to vfio :echo "options vfio-pci ids=8086:7ae2"> /etc/modprobe.d/vfio.conf
- update-initramfs -u
- reboot
- Check that driver in use is vfio-pci and not ahci, it works currently only because I have 1 Sata so I can disable all Sata controllers, to choose which sata to passthrough follow this guide : https://gist.github.com/kiler129/4f765e8fdc41e1709f1f34f7f8f41706

