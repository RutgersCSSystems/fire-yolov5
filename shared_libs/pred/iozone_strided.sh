#!/bin/bash

dmesg --clear
sudo apt-get install iozone3 -y

FILE=iozone.tmp
SIZE=5g ##FILESIZE 
STRIDE=13 ## * $RECORD
RECORD=1024 ##Size of read in kb

touch $FILE
chmod 777 $FILE
iozone -i 0 -s $SIZE -w -+N
stat $FILE
sudo sh -c "/bin/echo 3 > /proc/sys/vm/drop_caches"

#export LD_PRELOAD=./libnopred.so 
export LD_PRELOAD=./libcrosslayer.so
/usr/bin/time -v iozone -f $FILE -s $SIZE -j $STRIDE -i 5 -r $RECORD
export LD_PRELOAD=
