#!/bin/bash -x
#script to create and mount a pmemdir
#requires size as input
#xfs
rm -rf $APPBENCH/shared_data
sudo umount /mnt/ext4ramdisk
sudo mkdir /mnt/ramdisk
sudo mount -t ramfs ramfs /mnt/ramdisk
sudo dd if=/dev/zero of=/mnt/ramdisk/ext4.image bs=1M count=49152
sudo mkfs.ext4 /mnt/ramdisk/ext4.image
sudo mkdir /mnt/ext4ramdisk
sudo mount -o loop /mnt/ramdisk/ext4.image /mnt/ext4ramdisk
sudo chown -R $USER /mnt/ext4ramdisk
sudo ln -s /mnt/ext4ramdisk $APPBENCH/shared_data
