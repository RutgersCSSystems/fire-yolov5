#!/bin/bash

SPC=/usr/share/gromacs/top/spc216.gro
gmx editconf -f $SPC -o empty_box.gro -bt cubic -box 10
gmx solvate -cp empty_box.gro -cs $SPC -o water.gro
gmx pdb2gmx -f water.gro -o water.gro -p water.top -n water.ndx
gmx grompp -v -f water_MD.mdp -c water.gro -p water.top -o run_water
