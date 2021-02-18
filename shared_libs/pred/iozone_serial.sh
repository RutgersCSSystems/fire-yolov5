#!/bin/bash

dmesg --clear
sudo apt-get install iozone3 -y

FILE=iozone.tmp
SIZE=`echo "5 * 1024 * 1024" | bc` ##FILESIZE in kb
RECORD=1024 ##Size of read in kb

touch $FILE
chmod 777 $FILE
iozone -f $FILE -i 0 -s $SIZE -w -+N
stat $FILE
sudo sh -c "/bin/echo 3 > /proc/sys/vm/drop_caches"

#export LD_PRELOAD=./libnopred.so 
export LD_PRELOAD=./libcrosslayer.so
/usr/bin/time -v iozone -f $FILE -s $SIZE -i 1 -r $RECORD
export LD_PRELOAD=
