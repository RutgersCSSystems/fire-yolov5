#!/bin/bash -x
set -x
#script to create and mount a pmemdir
#requires size as input
#xfs
PREFIX="numactl --membind=0"

scount="$1"
echo $scount

#rm -rf $APPBENCH/shared_data
sudo umount /mnt/ext4ramdisk
sudo umount /mnt/ramdisk
sudo rm -rf /mnt/ramdisk/ext4.image
sudo mkdir /mnt/ramdisk
sudo mount -t ramfs ramfs /mnt/ramdisk

sleep 10

sudo $PREFIX dd if=/dev/zero of=/mnt/ramdisk/ext4.image bs=1M count="$scount"
sudo $PREFIX mkfs.ext4 -F /mnt/ramdisk/ext4.image
sudo mkdir /mnt/ext4ramdisk
sudo mount -o loop /mnt/ramdisk/ext4.image /mnt/ext4ramdisk
sudo chown -R $USER /mnt/ext4ramdisk
sleep 4
let imagesz=$scount-512
echo "imagesz: "$imagesz
fallocate -l $imagesz"M" /mnt/ext4ramdisk/test.img
