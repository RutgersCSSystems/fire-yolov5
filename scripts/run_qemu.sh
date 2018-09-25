#!/bin/bash
set +x

$APPBENCH/scripts/umout_qemu.sh
sleep 1
#Launching QEMU
sudo qemu-system-x86_64 -kernel $KERNEL/vmlinuz-$VER -hda $QEMU_IMG_FILE -append "root=/dev/sda rw" --enable-kvm -m $QEMUMEM -numa node,nodeid=0,cpus=0-4 -numa node,nodeid=1,cpus=10-13 -net user,hostfwd=tcp::10022-:22 --curses

#sudo qemu-system-x86_64 -kernel $KERNEL/vmlinuz-$VER -hda $QEMU_IMG_FILE -append "root=/dev/sda rw" --enable-kvm -m $QEMUMEM -numa node,nodeid=0,cpus=0-4 -numa node,nodeid=1,cpus=10-13 --curses -netdev user,hostfwd=tcp::45455-:45455,guestfwd=tcp::45456-,id=net0
#  -nographic #--curses

#--curses

