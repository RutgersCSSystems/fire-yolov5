
set -x
sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"

#OPTIONS="-DREADAHEAD -DFORWARD -DSTRIDE=3" #-DDEBUG -DREAD -DCLEAR_CACHE
OPTIONS="-DREAD -DBACKWARD -DSTRIDE=3" #-DDEBUG -DREAD -DCLEAR_CACHE
mpicc readers.c $OPTIONS

set +x
/usr/bin/time -v mpirun -np 2 ./a.out
