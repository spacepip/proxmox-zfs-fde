`dhclient -v enp2s0`
execute script with `wget -O - https://raw.githubusercontent.com/spacepip/proxmox-zfs-fde/main/convert-to-fde.sh | bash -s`

shrotened URL (convert-to-fd.sh): t.ly/oaMDd 

shortened URL (test.sh): t.ly/1KnZf


# This works on vm-nas!
bash <(wget -qO- t.ly/1KnZf)

# THis to be excuted on the Proxmox Host
dhclient -v enp2s0
ln -s /proc/self/fd /dev/fd
bash <(wget -qO- t.ly/oaMDd )


sudo su
wget -O - t.ly/1KnZf | bash -s 


## Steps
1. Install with zfs (RAID0 for single-disk application)
2. Reboot into ISO > Advanced Options > Graphical, debug mode
3. Exit to bash with `exit` or Ctrl+D


# Notes
- No git is present in Debug Mode
