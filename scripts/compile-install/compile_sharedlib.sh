#!/bin/bash

if [ -z "$NVMBASE" ]; then
    echo "NVMBASE environment variable not defined. Have you ran setvars?"
    exit 1
fi

cd $SHARED_LIBS/pred
make clean; make -j; make install
