#!/bin/bash

NPROC=36

#gmx editconf -f /usr/share/gromacs/top/spc216.gro -o empty_box.gro -bt cubic -box 10
#gmx solvate -cp empty_box.gro -cs /usr/share/gromacs/top/spc216.gro -o water.gro
#gmx pdb2gmx -f water.gro -o water.gro -p water.top -n water.ndx
#gmx grompp -v -f water_MD.mdp -c water.gro -p water.top -o run_water

/usr/bin/time -v gmx mdrun -ntmpi $NPROC -ntomp 1 -nt $NPROC -s run_water.tpr -o -x -deffnm md_water
