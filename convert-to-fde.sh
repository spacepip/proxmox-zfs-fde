#!/bin/bash
# Source: https://forum.proxmox.com/threads/native-full-disk-encryption-with-zfs.140170/

set -e 
set -v

# echo "Please enter the password for the ZFS share"
# read input
# export ZFSPASSWORD="$input"
# echo "The password entered is: $ZFSPASSWORD"


while true; do
  read -s -p "Please enter a password for the 'rpool/ROOT' dataset: " PASSWORDENTERED
  echo
  read -s -p "Please enter the password again: " PASSWORDAGAIN
  echo
  [ "$PASSWORDENTERED" = "$PASSWORDAGAIN" ] && break
  echo "The passwords don't match. Please try again"
done

ZFSPASSWORD=$PASSWORDENTERED


# Encrypt root dataset
zpool import -f rpool                        # Force import the ZFS pool named 'rpool'
zfs snapshot -r rpool/ROOT@copy              # Create a recursive snapshot of 'rpool/ROOT'
zfs send -R rpool/ROOT@copy | zfs receive rpool/copyroot            # Duplicate the snapshot to 'rpool/copyroot'
zfs destroy -r rpool/ROOT                    # Destroy the original 'rpool/ROOT' to replace it with an encrypted version
zfs create -o encryption=on -o keyformat=passphrase rpool/ROOT <<< "$ZFSPASSWORD"     # Create a new 'rpool/ROOT' with encryption
zfs send -R rpool/copyroot/pve-1@copy | zfs receive -o encryption=on rpool/ROOT/pve-1    # Restore 'pve-1' from the copy
zfs destroy -r rpool/copyroot                # Clean up by removing the temporary copy
zpool export rpool                           # Export the pool to finalize changes

# Prepare for chroot & destroy rpool/data dataset
zpool import -f -R /mnt rpool                # Import the pool with an alternate root at /mnt
zfs load-key -a <<< "$ZFSPASSWORD"                              # Load the encryption keys for all encrypted datasets
zfs destroy -r rpool/data                    # Destroy original dataset as after mounting pve-1 in the next step rpool/data will appear `busy` (see post #4 below)
zfs destroy -r rpool/var-lib-vz
zfs mount rpool/ROOT/pve-1                   # Mount the 'pve-1' dataset
mount -o rbind /proc /mnt/proc               # Recursively bind the /proc directory to the chroot environment
mount -o rbind /sys /mnt/sys                 # Recursively bind the /sys directory
mount -o rbind /dev /mnt/dev                 # Recursively bind the /dev directory
chroot /mnt /bin/bash <<"EOT"                       # Change root into the new environment

set -e 
set -v

# Create encrypt rpool/data dataset
zfs create -o encryption=on rpool/ROOT/data     # Create a new dataset with encryption enabled
zfs create -o encryption=on -o mountpoint=/var/lib/vz rpool/ROOT/var-lib-vz     # Create a new dataset with encryption enabled

## Can't seem to update 'path' with 'pvesm set'. Must remove and then re-add
# pvesm remove local
# pvesm remove local-zfs

##Also added 'snippets' as content type
# pvesm add dir local --path /rpool/ROOT/var-lib-vz --content iso,vztmpl,backup,snippets
# pvesm add zfspool local-zfs --pool rpool/ROOT/data --sparse true --content images,rootdir
# pvesm didn't work!

# mount /etc/pve  i.e. the Proxmox Cluster File System (pmxcfs)
pmxcfs -l

cat > /etc/pve/storage.cfg <<'EOF'
dir: local
        path /var/lib/vz
        content iso,vztmpl,backup,snippets

zfspool: local-zfs
        pool rpool/ROOT/data
        sparse
        content images,rootdir

EOF

chown root:www-data /etc/pve/storage.cfg
chmod 640 /etc/pve/storage.cfg


EOT
# exit
# Cleanup and reboot



umount /mnt/proc                              # Unmount /proc
umount -l /mnt/sys                               # Unmount /sys "-l for lazy because regular umount didn't work"
umount -l /mnt/dev                               # Unmount /dev (if target is busy, check for nested mounts)
zfs unmount rpool/ROOT/data                  # Unmount the ZFS dataset
zfs unmount rpool/ROOT/var-lib-vz
zfs unmount rpool/ROOT/pve-1                  # Unmount the ZFS dataset
zpool export rpool                            # Export the ZFS pool

echo "Success! Proxmox now uses full disk encryption with ZFS."
echo "Please use Ctrl + Alt + Del to reboot"
#reboot
# or maybe use "reboot" command
#Ctrl + Alt + Del                              # Use key combination to reboot the system