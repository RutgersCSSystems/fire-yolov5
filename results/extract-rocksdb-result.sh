#!/bin/bash
declare -a nproc=("1" "4" "8" "16" "32")
declare -a techarr=("Vanilla" "OSonly" "Cross_Info" "CII")
declare -a rocksworkarr=("readseq" "readrandom" "readwhilescanning")

TARGETDIR=$OUTPUTDIR

DATA_FOLDER=$OUTPUT_FOLDER/ROCKSDB-stats
BASENAME=stats_rocksdb

#Checks if the OUTFILE exists, 
TOUCH_OUTFILE(){
        if [[ ! -e $1 ]]; then
                touch $1
                printf "# reader" >> $1
                for TECH in "${techarr[@]}"
                do
                        printf " $TECH" >> $1
                done
                printf "\n" >> $1
        else
                echo "$1 Exists!"
        fi
}

EXTRACT_PERF() {
        #cat $1 | grep "READ_SEQUENTIAL Bandwidth" | awk '{print $4}'
        cat $1 | grep $2 | awk 'BEGIN {SUM=0}; {SUM=SUM+$5}; END {print SUM}'
}

GET_PERF() {

        for WORKLOAD in "${rocksworkarr[@]}"
        do
                resultfile=$TARGETDIR/${BASENAME}_${WORKLOAD}_perf.dat
                echo "RESUlt FILE : $resultfile"
                TOUCH_OUTFILE $resultfile

                for NPROC in "${nproc[@]}"
                do
                        printf "$NPROC" >> $resultfile
                        for TECH in "${techarr[@]}"
                        do
                                FILENAME=${WORKLOAD}/${NPROC}/${TECH}.out
                                echo "$FILENAME"

                                perf=`EXTRACT_PERF $DATA_FOLDER/$FILENAME $WORKLOAD`
                                #echo "perf = $perf"
                                printf " $perf" >> $resultfile
                        done
                        printf "\n" >> $resultfile
                done
        done
}


EXTRACT_MISS_RATIO() {
        line=`cat $1 | grep "GlobalReport"`

        total_read_pg=`echo $line | awk -F '[\ :,]' 'BEGIN {SUM=0}; {SUM=SUM+$7}; END {print SUM}'`
        total_miss_pg=`echo $line | awk -F '[\ :,]' 'BEGIN {SUM=0}; {SUM=SUM+$13}; END {print SUM}'`

        miss_ratio=`echo "scale=3; $total_miss_pg/$total_read_pg" | bc -l`

        echo $miss_ratio
}

GET_MISS_RATIO() {
        for WORKLOAD in "${rocksworkarr[@]}"
        do
                resultfile=$TARGETDIR/${BASENAME}_${WORKLOAD}_missratio.dat
                echo "RESUlt FILE : $resultfile"
                TOUCH_OUTFILE $resultfile

                for NPROC in "${nproc[@]}"
                do
                        printf "$NPROC" >> $resultfile
                        for TECH in "${techarr[@]}"
                        do
                                FILENAME=${WORKLOAD}/${NPROC}/${TECH}.out
                                echo "$FILENAME"

                                ratio=`EXTRACT_MISS_RATIO $DATA_FOLDER/$FILENAME`
                                echo "ratio = $ratio"
                                printf " $ratio" >> $resultfile
                        done
                        printf "\n" >> $resultfile
                done
        done
}


EXTRACT_NR_RA() {
        nr_ra=`cat $1 | grep "nr_ra" | awk 'BEGIN {SUM=0}; {SUM=SUM+$4}; END {print SUM}'`

        echo $nr_ra
}

EXTRACT_NR_RA_BYTES() {
        nr_bytes_ra=`cat $1 | grep "nr_bytes_ra" | awk 'BEGIN {SUM=0}; {SUM=SUM+$4}; END {print SUM}'`
        echo $nr_bytes_ra
}

GET_NR_RA() {
        for WORKLOAD in "${rocksworkarr[@]}"
        do
                ra_resultfile=$TARGETDIR/${BASENAME}_${WORKLOAD}_nr_ra.dat
                ra_bytes_resultfile=$TARGETDIR/${BASENAME}_${WORKLOAD}_nr_ra_bytes.dat

                echo "RESUlt FILE : $ra_resultfile"
                echo "RESUlt FILE : $ra_bytes_resultfile"

                TOUCH_OUTFILE $ra_resultfile
                TOUCH_OUTFILE $ra_bytes_resultfile

                for NPROC in "${nproc[@]}"
                do
                        printf "$NPROC" >> $ra_resultfile
                        printf "$NPROC" >> $ra_bytes_resultfile
                        for TECH in "${techarr[@]}"
                        do
                                FILENAME=${WORKLOAD}/${NPROC}/${TECH}.out
                                echo "$FILENAME"

                                nr_ra=`EXTRACT_NR_RA $DATA_FOLDER/$FILENAME`
                                nr_ra_bytes=`EXTRACT_NR_RA_BYTES $DATA_FOLDER/$FILENAME`

                                echo "nr_ra = $nr_ra"
                                echo "nr_ra_bytes = $nr_ra_bytes"

                                printf " $nr_ra" >> $ra_resultfile
                                printf " $nr_ra_bytes" >> $ra_bytes_resultfile
                        done
                        printf "\n" >> $ra_resultfile
                        printf "\n" >> $ra_bytes_resultfile
                done
        done
}

#GET_PERF

#GET_MISS_RATIO

GET_NR_RA
