#!/bin/bash

#This script increases the amount of memory spared for PageCache using Cgroups

export NVMALLOC_HOME=$PWD/nvmalloc
sudo rm -rf DATA_RESTART*

sudo apt-get install libcgroup1 cgroup-tools -y # Install cgroups


FILE=PCAnon_gtc.csv

Nproc=`nproc`
#ProgMem=`echo "776024 * $Nproc * 1024" | bc` #in bytes
#ProgMem=`echo "676024 * $Nproc * 1024" | bc` #in bytes for size D
#ProgMem=`echo "56260 * $Nproc * 1024" | bc` #in bytes For size C
ProgMem=`echo "110729625 * 1024" | bc` #in bytes For gtc

sudo cgcreate -g memory:npb

#echo "PCAnonRatio, MemoryGiven(bytes), Command, ElapsedTime, UserTime, KernelTime, %CPU-Usage, MAX_RSS, MajorPageFaults, MinorPageFaults, Vol-ContextSwitch, InVol-ContextSwitch, ExitStat, Page Cache(MB)" > $FILE

for i in $(seq 2.1 0.1 5.0)
do
	TotalMem=`echo "$ProgMem * $i" | bc`
	TotalMem=`echo $TotalMem | perl -nl -MPOSIX -e 'print ceil($_)'`
	echo "Total Allowed memory = $TotalMem"
	echo $TotalMem | sudo tee /sys/fs/cgroup/memory/npb/memory.limit_in_bytes
	echo $i | tr '\n' ',' >> $FILE
	printf "$TotalMem," >> $FILE

	sudo cgexec -g memory:npb /usr/bin/time -f " %C, %e, %U, %S, %P, %M, %F, %R, %w, %c, %x" mpiexec -n $Nproc ./gtc 2>&1 > /dev/null | tail -n 1 | tr '\n' ',' >> $FILE

	buffer=$(free -m | head -n 2 | tail -n 1 | awk -F" " '{print $6}')
	echo $buffer >> $FILE

	sudo rm -rf DATA_RESTART*
	sync
done
