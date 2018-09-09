#!/bin/bash -x
cd $KERN_SRC
sudo apt-get install libdpkg-dev kernel-package
export CONCURRENCY_LEVEL=32
export CONCURRENCYLEVEL=32
touch REPORTING-BUGS
mv .config .config_back
make distclean
make menuconfig
#fakeroot make-kpkg clean
fakeroot make-kpkg --initrd kernel-image kernel-headers
dpkg -i ../*image*.deb ../*header*.deb
exit
