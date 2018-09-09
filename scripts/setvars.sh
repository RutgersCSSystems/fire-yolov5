#!/bin/bash
export QEMU_IMG=/home/joo
export BASE=$PWD
export CODESRC=$BASE
######## DO NOT CHANGE BEYOUND THIS ###########

#Pass the release name
export OS_RELEASE_NAME=$1
export KERN_SRC=$BASE/linux-stable
#CPU parallelism
export PARA="-j40"
export VER="4.17.0"

#QEMU
export QEMU_IMG_FILE=$QEMU_IMG/qemu-image.img
export MOUNT_DIR=$QEMU_IMG/mountdir
export QEMUMEM="4096M"

#BENCHMARKS AND LIBS
export LINUX_SCALE_BENCH=$BASE/linux-scalability-benchmark
export APPBENCH=$CODESRC/appbench
export SHARED_LIBS=$APPBENCH/shared_libs
export QUARTZ=$SHARED_LIBS/quartz

#SCRIPTS
export SCRIPTS=$CODESRC/scripts
export INPUTXML=$SCRIPTS/input.xml
export QUARTZSCRIPTS=$SHARED_LIBS/quartz/scripts

#APP SPECIFIC and APPBENCH
export GRAPHCHI_ROOT=$APPBENCH/graphchi/graphchi-cpp
export SHARED_DATA=$APPBENCH/shared_data
export APPPREFIX=""
export OUTPUTDIR=$APPBENCH/output

#Commands
mkdir $OUTPUTDIR
