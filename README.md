# lebon
Info for reinstalling proxmox on lebon : 
- disconnect ethernet on lan1 and connect lan0 to lepaysan (backup)
- set static ip 192.168.10.2, this will create bridge vmbr0 which correspond to LAN 
- with a third pc, set static ip like 192.168.10.5 and go to bakcup gui and copy its fingerprint (debug: might want to disable old VPN like tailscale, couldn't ping with it)
- connect to lebon gui and add a storage in "Datacenter", button "Add", then "proxmox backup server"
- create the WAN bridge vmbr1 and associate it with a physical port with internet access, and possibly other test bridges
- restore pfsense, internet is up !
- add non subscription repo, update, upgrade, reboot
- 
