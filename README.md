# Shortened URL
- t.ly/oaMDd  resolves to https://raw.githubusercontent.com/spacepip/proxmox-zfs-fde/main/convert-to-fde.sh

## Discover NICs
- ip a

## Steps (steps specific to my setup and NIC)
1. Install with zfs (RAID0 for single-disk application)
2. Reboot into ISO > Advanced Options > Graphical, debug mode
3. Exit to bash with `exit` or `Ctrl+D`
4. `dhclient -v enp2s0`
5. `ln -s /proc/self/fd /dev/fd`
6. `bash <(wget -qO- t.ly/oaMDd )`


# Notes
- `git` is not available in Debug Mode
- Initial failed attempt: execute script with `wget -O - https://raw.githubusercontent.com/spacepip/proxmox-zfs-fde/main/convert-to-fde.sh | bash -s`
- Can't change the path for "dir: local" in "/etc/pve/storage.cfg". It seems that the location is hardcoded to "/var/lib/vz".
When I uploaded an ISO over the webGUI it was placed in "/var/lib/vz/templates/iso" instead of the new location I defined in 
"/etc/pve/storage.cfg". Hence, I'll just change the mountpoint of my "var-lib-vz" dataset to point to "/var/lib/vz/" to make it all 
work nicely.
