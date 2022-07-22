#!/bin/bash

NPROC=36
DMESGREADER="$HOME/ssd/NVM/appbench/apps/NPB3.4/NPB3.4-MPI/scripts/readdmesg.py"

rm -rf btio*

LD_PRELOAD=/usr/lib/libmigration.so /usr/bin/time -v mpirun -NP $NPROC ./bin/bt.C.x.ep_io &
$DMESGREADER init
while :
do
	sleep 1
	if pgrep -x "mpirun" >/dev/null
	then
		$DMESGREADER readfrom Cum_mem-unlimited.csv
	else
		break
	fi
	sleep 1
done
./clean_out.sh
