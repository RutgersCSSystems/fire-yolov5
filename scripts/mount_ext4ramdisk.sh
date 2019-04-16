#!/bin/bash -x
#script to create and mount a pmemdir
#requires size as input
#xfs
sudo mkdir /mnt/ramdisk
sudo mount -t ramfs ramfs /mnt/ramdisk
sudo dd if=/dev/zero of=/mnt/ramdisk/ext4.image bs=1M count=16384
mkfs.ext4 /mnt/ramdisk/ext4.image
mkdir /mnt/ext4ramdisk
mount -o loop /mnt/ramdisk/ext4.image /mnt/ext4ramdisk
sudo chown -R $USER /mnt/ext4ramdisk
ln -s /mnt/ext4ramdisk $APPBENCH/shared_data
