#!/bin/bash

#get data
mkdir $APPBENCH/$SHARED_DATA
cd $APPBENCH/$SHARED_DATA

if [ ! -f com-orkut.ungraph.txt ]; then
        wget https://snap.stanford.edu/data/bigdata/communities/com-orkut.ungraph.txt
fi

if [ ! -f crime.data ]; then
	wget -O crime.data https://norvig.com/big.txt
	for i in {1..8}; do cat crime.data crime.data > crime4GB.data && mv crime4GB.data crime.data ; done && rm crime4GB.data
fi
