# Shortened URLs
- (convert-to-fd.sh): t.ly/oaMDd 
- (test.sh): t.ly/1KnZf
- (shared-root branch): t.ly/asma0

## Discover NICs
- ip a

## Steps (steps specific to my setup)
1. Install with zfs (RAID0 for single-disk application)
2. Reboot into ISO > Advanced Options > Graphical, debug mode
3. Exit to bash with `exit` or Ctrl+D
4. dhclient -v enp2s0
5. ln -s /proc/self/fd /dev/fd
6. bash <(wget -qO- t.ly/oaMDd )

7. bash <(wget -qO- t.ly/asma0 )  ## shared-root test


# Notes
- No git is present in Debug Mode
- Initial attempt: execute script with `wget -O - https://raw.githubusercontent.com/spacepip/proxmox-zfs-fde/main/convert-to-fde.sh | bash -s`
