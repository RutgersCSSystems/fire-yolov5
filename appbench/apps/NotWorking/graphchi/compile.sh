#!/bin/bash

if [ -z "$NVMBASE" ]; then
    echo "NVMBASE environment variable not defined. Have you sourced setvars?"
    exit 1
fi


pushd $APPS/graphchi/graphchi-cpp
make clean && make -j
popd
