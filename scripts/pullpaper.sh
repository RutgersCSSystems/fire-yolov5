#!/bin/bash
set -x
git clone https://github.com/RutgersCSHeteroLab/IntelliOS-paper
cd $NVMBASE/IntelliOS-paper
git pull
git commit -am "basic commit"
git push origin master
