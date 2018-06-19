#!/bin/bash
set -x

#Pass the release name
export OS_RELEASE_NAME=$1
export QEMU_IMG=$PWD
export KERN_SRC=$PWD/linux-stable
#CPU parallelism
export PARA="-j40"
export VER="4.17.0"
export QEMU_IMG_FILE=$PWD/qemu-image.img
export MOUNT_DIR=$PWD/mountdir

set +x
