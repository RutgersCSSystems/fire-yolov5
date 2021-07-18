#!/bin/bash

if [ -z "$NVMBASE" ]; then
    echo "PREFIX environment variable not defined. Have you ran setvars?"
    echo "Dont forget to change \$VER in setvars.sh"
    exit 1
fi

VERSION=4.19.197
KERNEL=linux-$VERSION
PROC=`nproc`
export CONCURRENCY_LEVEL=$PROC
export CONCURRENCYLEVEL=$PROC 

cd $NVMBASE
#git clone https://github.com/shaleengarg/$KERNEL.git
wget https://mirrors.edge.kernel.org/pub/linux/kernel/v4.x/$KERNEL.tar.gz
tar -xf  $KERNEL.tar.gz
cp $NVMBASE/scripts/helperscripts/linuxMakefile-$VERSION $KERNEL/Makefile
if [ $? -ne 0 ]
then
	echo "no custom makefile for $KERNEL"
	exit
fi
cp $NVMBASE/scripts/helperscripts/compile_deb.sh $KERNEL/compile_deb.sh
cp $NVMBASE/scripts/helperscripts/compile_make.sh $KERNEL/compile_make.sh
cd $KERNEL

sudo apt-get update
sudo apt-get install -y libdpkg-dev kernel-package libncurses5-dev build-essential bison flex libssl-dev libelf-dev


./compile_deb.sh ##To be called only once, next time, call compile_make.sh

exit

#touch REPORTING-BUGS
#make distclean -j
#make menuconfig
#sudo fakeroot make-kpkg -j$PROCS --initrd kernel-image kernel-headers

##dpkg only if this is the first time, next time, only need to compile
##TODO
#sudo dpkg -i ../*image*.deb ../*header*.deb
