#!/bin/bash
set -x
QUARTZ="/proj/fsperfatscale-PG0/sudarsun/quartz"
SCRIPTSHOME=/users/skannan/ssd/schedsp/scripts
STREAMOUT=$SCRIPTSHOME/"stream.txt"
TMPOUT=$SCRIPTSHOME/"tmp.txt"

let bw=$1
let targethigh=$1+300
let targetlow=$1-300
BW=$1
i="0"

RDLAT="300"
WRLAT="500"

export $QUARTZ

SETUP() {

  cd $QUARTZ
  READ="read = "$BW";"
  WRITE="write = "$BW";"

  cd $QUARTZ

  sed -i "/read = /c\    $READ" $QUARTZ/nvmemul.ini
  sed -i "/write = /c\    $WRITE" $QUARTZ/nvmemul.ini


  READLAT="read = "$RDLAT";"
  READLATOLD="read =.*"

  WRITELAT="write = "$WRLAT";"
  WRITELATOLD="write =.*"

  sed -i '0,/'"$READLATOLD"'/s//'"$READLAT"'/' $QUARTZ/nvmemul.ini
  sed -i '0,/'"$WRITELATOLD"'/s//'"$WRITELAT"'/' $QUARTZ/nvmemul.ini

  #install the kernel module
  sudo $QUARTZ/scripts/setupdev.sh &> $TMPOUT

  #copy the register and pci device files
  if [ ! -f /tmp/bandwidth_model ]; then
    sudo cp $SCRIPTSHOME/bandwidth_model /tmp
  fi
  if [ ! -f /tmp/mc_pci_bus ]; then
    sudo cp $SCRIPTSHOME/mc_pci_bus /tmp
  fi
}

CLEANUP() {
  #rm -rf $STREAMOUT
  rm -rf $TMPOUT
}

RUN_STREAM() {
  rm $STREAMOUT"_"$BW
  sudo numactl --membind=1 taskset -c 1-8 $QUARTZ/Thermalthrottling/stream/stream_c.exe &>> $STREAMOUT"_"$BW
  sudo numactl --membind=1 /users/skannan/ssd/schedsp/simplebench/membandwidth test 1000  1 8 1 &>> $STREAMOUT"_"$BW
}

CHECK_TARGET() {
   RUN_STREAM
   bwtemp=`grep -r "(MB/s):" $STREAMOUT"_"$BW | tail -1 | awk '{print $2}'`
   #Remove decimal
   let bwmeasure=`echo ${bwtemp%.*}`
   if [[ ("$bwmeasure" -lt "$targethigh") && ("$bwmeasure" -ge "$targetlow") ]]
   then
     echo $bwmeasure" target acheived"
     #Clean output files
     CLEANUP
     exit
   else 
     echo $bwmeasure
   fi
}

#Attemps 50 times to throttle.
#TODO: Make number of attempts configurable
PERFORM_EMULATION(){
  for i in `seq 1 1`;
  do
   #Now run the quartz scripts
   $QUARTZ/scripts/runenv.sh ls &> $TMPOUT
   CHECK_TARGET
   rm -rf $TMPOUT
  done
}

#Setup
SETUP
#Check if we already have the required bandwidth
#CHECK_TARGET
#If not perform emulation and exit
PERFORM_EMULATION
#Clean output files
CLEANUP
