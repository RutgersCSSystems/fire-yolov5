#!/bin/bash

VERSION=4.15.1
KERNEL=linux-$VERSION
export CONCURRENCY_LEVEL=`nproc`
export CONCURRENCYLEVEL=`nproc`
PROCS=`nproc`

sudo apt-get update; sudo apt-get install -y libdpkg-dev kernel-package

wget https://mirrors.edge.kernel.org/pub/linux/kernel/v4.x/$KERNEL.tar.gz
tar -xvf  $KERNEL.tar.gz
cd $KERNEL

touch REPORTING-BUGS
 
make distclean -j
make menuconfig
sudo fakeroot make-kpkg -j$PROCS --initrd kernel-image kernel-headers
sudo dpkg -i ../*image*.deb ../*header*.deb
