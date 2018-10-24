#!/bin/bash
export NVMBASE=$PWD
######## DO NOT CHANGE BEYOUND THIS ###########

#Pass the release name
export OS_RELEASE_NAME=$1
export KERN_SRC=$NVMBASE/linux-stable
#CPU parallelism
export PARA="-j56"
export VER="4.17.0"

#QEMU
export QEMU_IMG=$NVMBASE
#export QEMU_IMG_FILE=$QEMU_IMG/qemu-image-full.img
export QEMU_IMG_FILE=$QEMU_IMG/qemu-image.img
export MOUNT_DIR=$QEMU_IMG/mountdir
export QEMUMEM="4096M"
export KERNEL=$NVMBASE/KERNEL

#BENCHMARKS AND LIBS
export LINUX_SCALE_BENCH=$NVMBASE/linux-scalability-benchmark
export APPBENCH=$NVMBASE/appbench
export SHARED_LIBS=$APPBENCH/shared_libs
export QUARTZ=$SHARED_LIBS/quartz

#SCRIPTS
export SCRIPTS=$NVMBASE/scripts
export INPUTXML=$SCRIPTS/input.xml
export QUARTZSCRIPTS=$SHARED_LIBS/quartz/scripts

#APP SPECIFIC and APPBENCH
export GRAPHCHI_ROOT=$APPBENCH/graphchi/graphchi-cpp
export SHARED_DATA=$APPBENCH/shared_data
export APPPREFIX="numactl --membind=0 --cpunodebind=0"
export APP_PREFIX="numactl --membind=0 --cpunodebind=0"
export OUTPUTDIR=$APPBENCH/output

#Commands
mkdir $OUTPUTDIR
mkdir $KERNEL
