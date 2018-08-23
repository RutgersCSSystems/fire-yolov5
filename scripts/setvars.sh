#!/bin/bash
set -x

export QEMU_IMG=/users/kannan11/ssd/schedsp/NVM

######## DO NOT CHANGE BEYOUND THIS ###########

#Pass the release name
export OS_RELEASE_NAME=$1
export KERN_SRC=$PWD/linux-stable
#CPU parallelism
export PARA="-j40"
export VER="4.17.0"
export QEMU_IMG_FILE=$QEMU_IMG/qemu-image.img
export MOUNT_DIR=$QEMU_IMG/mountdir
export LINUX_SCALE_BENCH=$PWD/linux-scalability-benchmark
export QEMUMEM="4096M"
export CODESRC=$PWD
set +x
