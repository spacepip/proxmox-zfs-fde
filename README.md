## Steps (steps specific to my setup and NIC)
1. Install with zfs (RAID0 for single-disk application)
2. Reboot into ISO
3. Advanced Options > Install Proxmox VE (Terminal UI, Debug Mode) 
4. Exit to bash with `exit` or `Ctrl+D`
5. Display available NICs with `ip a`
6. `dhclient -v enp2s0`
7. `ln -s /proc/self/fd /dev/fd`
8. `bash <(wget -qO- https://raw.githubusercontent.com/spacepip/proxmox-zfs-fde/main/convert-to-fde.sh )`


# Notes
- `git` is not available in Debug Mode
- Initial failed attempt: execute script with `wget -O - https://raw.githubusercontent.com/spacepip/proxmox-zfs-fde/main/convert-to-fde.sh | bash -s`
- Can't change the path for "dir: local" in "/etc/pve/storage.cfg". It seems that the location is hardcoded to "/var/lib/vz".
When I uploaded an ISO over the webGUI it was placed in "/var/lib/vz/templates/iso" instead of the new location I defined in 
"/etc/pve/storage.cfg". Hence, I'll just change the mountpoint of my "var-lib-vz" dataset to point to "/var/lib/vz/" to make it all 
work nicely.
