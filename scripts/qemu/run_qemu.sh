#!/bin/bash
set -x

$NVMBASE/scripts/qemu/umount_qemu.sh
sleep 1
#Launching QEMU

$NVMBASE/scripts/qemu/killqemu.sh

KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`

HALF_MEM=`echo "$QEMUMEM/2" | bc`

sudo qemu-system-x86_64 \
	-kernel $KERNEL/vmlinuz-$VER \
	-hda $QEMU_IMG_FILE \
	-append "root=/dev/sda rw" \
	--enable-kvm -m ${QEMUMEM}G \
	-numa node,nodeid=0,cpus=0-9,mem=${HALF_MEM}G \
	-numa node,nodeid=1,cpus=20-39,mem=${HALF_MEM}G \
	-smp sockets=2,cores=5,threads=2,maxcpus=40 \
	-curses -device e1000,netdev=net0 \
	-netdev user,id=net0,hostfwd=tcp::5555-:22
