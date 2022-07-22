#!/bin/bash

mkdir ../shared_data
cd ../shared_data

if [ ! -f crime.data ]; then
	wget -O crime.data https://norvig.com/big.txt
	for i in {1..8}; do cat crime.data crime.data > crime4GB.data && mv crime4GB.data crime.data ; done && rm crime4GB.data
fi


