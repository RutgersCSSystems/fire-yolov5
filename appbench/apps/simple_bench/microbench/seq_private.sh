#/bin/bash
set -x
DBHOME=$PWD
cd $PREDICT_LIB_DIR
./compile.sh &> out.txt
cd $DBHOME
./clearcache.sh && LD_PRELOAD=/usr/lib/lib_$1.so ./private_bench DATA/private_file 10000000000 16 $2  1 0 0
