#!/bin/bash -x
cd $KERN_SRC
sudo apt-get install -y libdpkg-dev kernel-package libncurses-dev
export CONCURRENCY_LEVEL=40
export CONCURRENCYLEVEL=40
touch REPORTING-BUGS

#Disable them
scripts/config --disable SYSTEM_REVOCATION_KEYS
scripts/config --disable SYSTEM_TRUSTED_KEYS



#mv .config .config_back
#make distclean
#sudo make menuconfig
#fakeroot make-kpkg clean
sudo fakeroot make-kpkg -j`nproc` --initrd kernel-image kernel-headers
sudo dpkg -i ../*image*.deb ../*header*.deb
exit
