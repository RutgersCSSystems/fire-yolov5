#!/bin/bash
set -x

PATH=/users/kannan11/ssd/NVM/graphs/zplot
SCRIPTS=$PATH/scripts
DATA=$PATH/data


#Hetero Objalloc
NAME=e-hetero-objalloc
/usr/bin/python $SCRIPTS/$NAME.py -i $DATA/$NAME.csv -o $PATH/$NAME -y 1000 -r 100

NAME=m-memusestack
/usr/bin/python $SCRIPTS/$NAME.py -i $DATA/$NAME.data -o $PATH/$NAME -y 3000 -r 500

NAME=m-osslowmem
/usr/bin/python $SCRIPTS/$NAME.py -i $DATA/$NAME.data -o $PATH/$NAME -y 2800 -r 400
