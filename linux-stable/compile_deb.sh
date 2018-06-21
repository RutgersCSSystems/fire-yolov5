#!/bin/bash -x

sudo apt-get install libdpkg-dev
export CONCURRENCY_LEVEL=40
export CONCURRENCYLEVEL=40
fakeroot make-kpkg --initrd kernel-image kernel-headers
dpkg -i ../*image*.deb ../*header*.deb
exit
