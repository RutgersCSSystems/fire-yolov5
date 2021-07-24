#!/bin/bash

set -x
sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"

OPTIONS="-DBACKWARD" #-DCLEAR_CACHE

gcc readback.c $OPTIONS -o readback

set +x
/usr/bin/time -v ./readback
