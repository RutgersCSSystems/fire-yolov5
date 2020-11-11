#!/bin/bash

export REUSEFILE=1
export TMPFILE=graph.dat

mpirun -np $NPROC  ./graph500_reference_bfs 21 16
