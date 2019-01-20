#!/bin/bash
cd $NVMBASE
source scripts/setvars.sh
$APPBENCH/install_quartz.sh
$APPBENCH/throttle.sh
$APPBENCH/throttle.sh
$NVMBASE/scripts/mount_dax.sh
$NVMBASE/scripts/set_appbench.sh
$NVMBASE/compile_all.sh
$APPBENCH/runapps.sh
