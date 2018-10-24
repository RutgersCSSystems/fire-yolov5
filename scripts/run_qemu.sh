#!/bin/bash
set +x

$APPBENCH/scripts/umout_qemu.sh
sleep 1
#Launching QEMU
sudo qemu-system-x86_64 -kernel $KERNEL/vmlinuz-$VER -hda $QEMU_IMG_FILE -append "root=/dev/sda rw" --enable-kvm -m $QEMUMEM -numa node,nodeid=0,cpus=0-15 -numa node,nodeid=1,cpus=16-32 -curses
#-nographic #-display curses
#sudo qemu-system-x86_64 -nographic -kernel $KERNEL/vmlinuz-4.17.0 -hda qemu-image.img -append "root=/dev/sda rw console=ttyAMA0 console=ttyS0" --enable-kvm -m 16G -numa node,nodeid=0,cpus=0-4 -numa node,nodeid=1,cpus=10-13

#sudo qemu-system-x86_64 -kernel $KERNEL/vmlinuz-$VER -hda $QEMU_IMG_FILE -append "root=/dev/sda rw" --enable-kvm -m $QEMUMEM -numa node,nodeid=0,cpus=0-4 -numa node,nodeid=1,cpus=10-13 -nographic -net nic,macaddr=56:44:45:30:31:32,vlan=0 -net tap,script=no,ifname=tap0,vlan=0 &

#--curses

