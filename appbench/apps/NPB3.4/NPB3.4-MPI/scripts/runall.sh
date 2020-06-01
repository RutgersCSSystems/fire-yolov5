#!/bin/bash

##This script runs the btio D benchmark with increasing dirty_background_ratio

FILE=dirtyBgRatio.csv

echo "Dirty, Command, ElapsedTime, UserTime, KernelTime, %CPU-Usage, MAX_RSS, MajorPageFaults, MinorPageFaults, Vol-ContextSwitch, InVol-ContextSwitch, ExitStat, Page Cache(MB)" > $FILE
set +x 
#for ((i=10; i<100 ; i++))
for i in {10..100..10}
do
	sudo sysctl vm.dirty_background_ratio=$i
	echo $i | tr '\n' ',' >> $FILE
	/usr/bin/time -f " %C, %e, %U, %S, %P, %M, %F, %R, %w, %c, %x" mpirun -NP 64 ../bin/bt.D.x.ep_io 2>&1 > /dev/null | tail -n 1 | tr '\n' ',' >> $FILE
	#/usr/bin/time -f " %C, %e, %U, %S, %P, %M, %F, %R, %w, %c, %x" ls 2>&1 > /dev/null | tr '\n' ',' >> $FILE
	buffer=$(free -m | head -n 2 | tail -n 1 | awk -F" " '{print $6}')
	echo $buffer >> $FILE
	rm btio.epio*
	sync
done
sudo sysctl vm.dirty_background_ratio=10
