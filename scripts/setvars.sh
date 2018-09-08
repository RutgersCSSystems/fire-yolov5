#!/bin/bash
export QEMU_IMG=/home/joo
export BASE=$PWD
######## DO NOT CHANGE BEYOUND THIS ###########

#Pass the release name
export OS_RELEASE_NAME=$1
export KERN_SRC=$BASE/linux-stable
#CPU parallelism
export PARA="-j40"
export VER="4.17.0"
export QEMU_IMG_FILE=$QEMU_IMG/qemu-image.img
export MOUNT_DIR=$QEMU_IMG/mountdir
export LINUX_SCALE_BENCH=$BASE/linux-scalability-benchmark
export QEMUMEM="4096M"
export CODESRC=$BASE
export SCRIPTS=$CODESRC/scripts
export INPUTXML=$SCRIPTS/input.xml
export APPBENCH=$BASE/appbench
export OUTPUTDIR=$APPBENCH/output
export SHARED_LIBS=$APPBENCH/shared_libs
export QUARTZ=$SHARED_LIBS/quartz
export QUARTZSCRIPTS=$SHARED_LIBS/quartz/scripts
