#!/bin/bash
set -x

$APPBENCH/scripts/umout_qemu.sh
sleep 1
#Launching QEMU

$APPBENCH/scripts/killqemu.sh

#sudo qemu-system-x86_64 -kernel $KERNEL/vmlinuz-$VER -hda $QEMU_IMG_FILE -append "root=/dev/sda rw" --enable-kvm -m $QEMUMEM -smp maxcpus=16  -numa node,nodeid=0,cpus=0-4 -curses -vga std -numa node,nodeid=1,cpus=10-13

sudo qemu-system-x86_64 -kernel $KERNEL/vmlinuz-$VER -hda $QEMU_IMG_FILE -append "root=/dev/sda rw" --enable-kvm -m $QEMUMEM -numa node,nodeid=0,cpus=0-8 -numa node,nodeid=1,cpus=9-15 -smp sockets=2,cores=2,threads=2,maxcpus=16 -curses -netdev user,id=mynet0,net=192.168.122.0/24,dhcpstart=192.168.122.4


#-nographic #-display curses
#sudo qemu-system-x86_64 -nographic -kernel $KERNEL/vmlinuz-4.17.0 -hda qemu-image.img -append "root=/dev/sda rw console=ttyAMA0 console=ttyS0" --enable-kvm -m 16G -numa node,nodeid=0,cpus=0-4 -numa node,nodeid=1,cpus=10-13

#sudo qemu-system-x86_64 -kernel $KERNEL/vmlinuz-$VER -hda $QEMU_IMG_FILE -append "root=/dev/sda rw" --enable-kvm -m $QEMUMEM -numa node,nodeid=0,cpus=0-4 -numa node,nodeid=1,cpus=10-13 -nographic -net nic,macaddr=56:44:45:30:31:32,vlan=0 -net tap,script=no,ifname=tap0,vlan=0 &

#--curses

