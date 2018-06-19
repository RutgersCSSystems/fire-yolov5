#!/bin/bash
set -x

sudo umount $MOUNT_DIR

#Compile the kernel
cd $KERN_SRC

#Enable the KVM mode in your kernel config file
sudo make x86_64_defconfig
sudo make kvmconfig 

#Compile the kernel with '-j' (denotes parallelism) in sudo mode
sudo make $PARA
sudo make modules
sudo make modules_install
sudo make install
