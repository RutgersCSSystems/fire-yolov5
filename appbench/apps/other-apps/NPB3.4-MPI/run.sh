#!/bin/bash

NPROC=4

rm -rf btio.epio.out*

mpirun -np $NPROC ./bin/bt.A.x.ep_io
