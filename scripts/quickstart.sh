#!/bin/bash
cd $NVMBASE
source scripts/setvars.sh
$APPBENCH/install_quartz.sh
$APPBENCH/throttle.sh
$APPBENCH/throttle.sh
$APPBENCH/runapps.sh
