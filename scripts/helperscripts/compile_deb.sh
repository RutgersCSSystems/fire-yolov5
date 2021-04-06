#!/bin/bash -x
sudo apt-get install -y libdpkg-dev kernel-package

PROC=`nproc`
export CONCURRENCY_LEVEL=$PROC
export CONCURRENCYLEVEL=$PROC

touch REPORTING-BUGS
sudo make distclean
sudo make menuconfig
#fakeroot make-kpkg clean
sudo fakeroot make-kpkg -j$PROC --initrd kernel-image kernel-headers
sudo dpkg -i ../*image*.deb ../*header*.deb
exit
