#!/bin/bash
# Source: https://forum.proxmox.com/threads/native-full-disk-encryption-with-zfs.140170/

set -e 
set -v

read input
export ZFSPASSWORD="$input"
echo "The password is: $ZFSPASSWORD"



zfs create -o encryption=on -o keyformat=passphrase nas_pool/enc_test <<< "$ZFSPASSWORD"      # Create a new 'rpool/ROOT' with encryption
