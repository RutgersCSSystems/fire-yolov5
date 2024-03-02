#!/bin/bash -x
sudo apt update; sudo apt-get install -y libdpkg-dev kernel-package libncurses-dev
sudo apt install build-essential dwarves python3 libncurses-dev flex bison libssl-dev bc libelf-dev zstd gnupg2 wget -y

sudo cp modifiednix.config .config
make menuconfig
scripts/config --disable SYSTEM_REVOCATION_KEYS
make localmodconfig

PROC=`nproc`
export CONCURRENCY_LEVEL=$PROC
export CONCURRENCYLEVEL=$PROC

touch REPORTING-BUGS
sudo make -j
sudo make bzImage -j
sudo make modules -j
sudo make modules_install -j
sudo make install
sudo update-grub


#sudo make prepare
#sudo make -j$PROC
