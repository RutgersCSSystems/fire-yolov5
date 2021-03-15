#!/bin/bash

sudo apt-get install iozone3 -y

FILE=iozone.tmp
SIZE=1g ##FILESIZE 
STRIDE=128k ##STRIDE OF READS
RECORD=16m ##Size of read

touch $FILE
chmod 777 $FILE
iozone -i 0 -s $SIZE -w -+N
stat $FILE
sudo sh -c "/bin/echo 3 > /proc/sys/vm/drop_caches"
/usr/bin/time -v iozone -f $FILE -s $SIZE -j $STRIDE -i 5 -y $RECORD -q $RECORD -+N
