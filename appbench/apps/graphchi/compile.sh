#!/bin/bash
pushd $APPS/graphchi/graphchi-cpp
make clean && make -j
popd
