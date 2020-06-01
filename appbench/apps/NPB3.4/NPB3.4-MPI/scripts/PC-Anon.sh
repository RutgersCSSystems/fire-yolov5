#!/bin/bash

#This script increases the amount of memory spared for PageCache using Cgroups

LOADCLASS=C  ##Workload size
RatioStart=1 ##Start of loop Minimum should be 1
Step=0.5     ##Step size
RatioEnd=4.5 ##End of for loop
TYPE="IntelliOS"  ##IntelliOS or Vanilla?
Nproc=38 ##Number of processes to create for this workload
FILE="${TYPE}_btio_${LOADCLASS}.csv"

#make clean
make bt CLASS=$LOADCLASS SUBTYPE=epio ##Compiles the btio program

sudo apt-get install libcgroup1 cgroup-tools -y # Install cgroups


#ProgMem=`echo "776024 * $Nproc * 1024" | bc` #in bytes
#ProgMem=`echo "676024 * $Nproc * 1024" | bc` #in bytes for size D
ProgMem=`echo "56260 * 40 * 1024" | bc` #in bytes For size C
#ProgMem=`echo "28000000 * 1024" | bc` #in bytes For smaller size D

sudo cgcreate -g memory:npb

echo "PCAnonRatio, MemoryGiven(bytes), Command, ElapsedTime (${TYPE}), UserTime, KernelTime, %CPU-Usage(${TYPE}), MAX_RSS, MajorPageFaults, MinorPageFaults, Vol-ContextSwitch, InVol-ContextSwitch, ExitStat, Page Cache(MB)" > $FILE

for i in $(seq $RatioStart $Step $RatioEnd)
do
	TotalMem=`echo "$ProgMem * $i" | bc`
	TotalMem=`echo $TotalMem | perl -nl -MPOSIX -e 'print ceil($_)'`
	echo "Total Allowed memory = $TotalMem"
	echo $TotalMem | sudo tee /sys/fs/cgroup/memory/npb/memory.limit_in_bytes
	echo $i | tr '\n' ',' >> $FILE
	printf "$TotalMem," >> $FILE

	sudo cgexec -g memory:npb /usr/bin/time -f " %C, %e, %U, %S, %P, %M, %F, %R, %w, %c, %x" mpirun -NP $Nproc ../bin/bt.${LOADCLASS}.x.ep_io 2>&1 > /dev/null | tail -n 1 | tr '\n' ',' >> $FILE

	buffer=$(free -m | head -n 2 | tail -n 1 | awk -F" " '{print $6}')
	echo $buffer >> $FILE

	sudo rm -rf btio.epio*
	sync
done
