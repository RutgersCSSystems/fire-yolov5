
FILESIZE=100 ##GB
NR_RA_PAGES=2560L #nr_pages
NR_READ_PAGES=512

declare -a nproc=("1" "4" "8" "16")
declare -a techarr=("VanillaRA" "VanillaOPT" "OSonly" "CrossInfo" "CII")

READSIZE=2M
RASIZE=10M


TARGETDIR=$OUTPUTDIR

DATA_FOLDER=$OUTPUT_FOLDER/SIMPLE_BENCH_PVT/STATS
BASENAME=stats_pvt_seq

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
        cat $1 | grep "READ_SEQUENTIAL Bandwidth" | awk '{print $4}'
}

GET_PERF() {
	resultfile=$TARGETDIR/${BASENAME}_perf.dat
        echo "RESUlt FILE : $resultfile"
        TOUCH_OUTFILE $resultfile

        for NPROC in "${nproc[@]}"
        do
                printf "$NPROC" >> $resultfile
                for TECH in "${techarr[@]}"
                do
                        FILENAME=${TECH}_${BASENAME}_${READSIZE}r_${RASIZE}ra_${NPROC}
                        echo "$FILENAME"

                        perf=`EXTRACT_PERF $DATA_FOLDER/$FILENAME`
                        #echo "perf = $perf"
                        printf " $perf" >> $resultfile
                done
                        printf "\n" >> $resultfile
        done
}


EXTRACT_MISS_RATIO() {
        nr_global_reports=`cat $1 | grep "GlobalReport" | wc -l`

        if [ $nr_global_reports -gt 1 ]; then
                echo "ERROR: EXTRACT_MISS_RATIO doesnt support multiple GlobalReport right now"
                exit
        fi
        
        line=`cat $1 | grep "GlobalReport"`

        total_read_pg=`echo $line | awk -F'[\ :,]' '{print $6}'`
        total_miss_pg=`echo $line | awk -F'[\ :,]' '{print $NF}'`

        miss_ratio=`echo "scale=3; $total_miss_pg/$total_read_pg" | bc -l`

        echo $miss_ratio
}

GET_MISS_RATIO() {
	resultfile=$TARGETDIR/${BASENAME}_missratio.dat
        echo "RESUlt FILE : $resultfile"
        TOUCH_OUTFILE $resultfile

        for NPROC in "${nproc[@]}"
        do
                printf "$NPROC" >> $resultfile
                for TECH in "${techarr[@]}"
                do
                        FILENAME=${TECH}_${BASENAME}_${READSIZE}r_${RASIZE}ra_${NPROC}
                        echo "$FILENAME"

                        ratio=`EXTRACT_MISS_RATIO $DATA_FOLDER/$FILENAME`
                        echo "ratio = $ratio"
                        printf " $ratio" >> $resultfile
                done
                        printf "\n" >> $resultfile
        done
}


GET_LOCK_OVERHEADS() {
        echo "TODO: GET_LOCK_OVERHEADS"
        return
	resultfile=$TARGETDIR/${BASENAME}_contention.dat
        echo "RESUlt FILE : $resultfile"
        TOUCH_OUTFILE $resultfile

        for NPROC in "${nproc[@]}"
        do
                printf "$NPROC" >> $resultfile
                for TECH in "${techarr[@]}"
                do
                        FILENAME=${TECH}_${BASENAME}_${READSIZE}r_${RASIZE}ra_${NPROC}
                        echo "$FILENAME"

                        ratio=`EXTRACT_MISS_RATIO $DATA_FOLDER/$FILENAME`
                        echo "ratio = $ratio"
                        printf " $ratio" >> $resultfile
                done
                        printf "\n" >> $resultfile
        done
}

#GET_PERF

GET_MISS_RATIO
