#!/bin/bash
# Source: https://forum.proxmox.com/threads/native-full-disk-encryption-with-zfs.140170/

set -e 
set -v

echo "Please enter the password for the ZFS share"
read input
export ZFSPASSWORD="$input"
echo "The password entered is: $ZFSPASSWORD"


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
zfs load-key -a                              # Load the encryption keys for all encrypted datasets
zfs destroy -r rpool/data                    # Destroy original dataset as after mounting pve-1 in the next step rpool/data will appear `busy` (see post #4 below)
zfs mount rpool/ROOT/pve-1                   # Mount the 'pve-1' dataset
mount -o rbind /proc /mnt/proc               # Recursively bind the /proc directory to the chroot environment
mount -o rbind /sys /mnt/sys                 # Recursively bind the /sys directory
mount -o rbind /dev /mnt/dev                 # Recursively bind the /dev directory
chroot /mnt /bin/bash                        # Change root into the new environment

# Create encrypt rpool/data dataset
dd if=/dev/urandom bs=32 count=1 of=/.data.key         # Create a new encryption key
chmod 400 /.data.key                                   # Set appropriate permissions for key
chattr +i /.data.key                                   # Make key immutable
zfs create -o encryption=on -o keylocation=file:///.data.key -o keyformat=raw rpool/data     # Create a new dataset with encryption enabled
# Setup systemd service for automatic unlocking of rpool/data on boot
sudo cat > /etc/systemd/system/zfs-load-key.service <<'EOF'
[Unit]
Description=Load encryption keys
DefaultDependencies=no
After=zfs-import.target
Before=zfs-mount.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/zfs load-key -a

[Install]
WantedBy=zfs-mount.service
EOF
systemctl enable zfs-load-key

## Optional! Only needed if stuck at boot with ZFS-encryption enabled (see post #3 below): Update boot configuration
# echo "simplefb" >> /etc/initramfs-tools/modules       # Add 'simplefb' to initramfs modules
# update-initramfs -k all -u                            # Update all initramfs images
# proxmox-boot-tool refresh                             # Refresh Proxmox boot configuration to apply changes


# Cleanup and reboot
exit
umount /mnt/proc                              # Unmount /proc
umount /mnt/sys                               # Unmount /sys
umount /mnt/dev                               # Unmount /dev (if target is busy, check for nested mounts)
zfs unmount rpool/data                  # Unmount the ZFS dataset
zfs unmount rpool/ROOT/pve-1                  # Unmount the ZFS dataset
zpool export rpool                            # Export the ZFS pool
Ctrl + Alt + Del                              # Use key combination to reboot the system