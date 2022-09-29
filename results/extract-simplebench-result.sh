
FILESIZE=100 ##GB
NR_RA_PAGES=2560L #nr_pages
NR_READ_PAGES=512

declare -a nproc=("1" "4" "8" "16" "32")
declare -a techarr=("VanillaRA" "VanillaOPT" "OSonly" "CrossInfo" "CII" "CIP" "MINCORE")

READSIZE=128pg
RASIZE=2560Lpg

TARGETDIR=$OUTPUTDIR/SIMPLEBENCH-21SEPT-STATS

DATA_FOLDER=$OUTPUT_FOLDER/SIMPLEBENCH-21SEPT-STATS/read_shared_seq
BASENAME=stats_shared_seq

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
        cat $1 | grep "READ_RANDOM Bandwidth" | awk '{print $4}'
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
                        echo "perf = $perf"
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

        total_read_pg=`echo $line | awk -F'[\ :,]' '{print $7}'`
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


EXTRACT_NR_RA() {
        nr_ra_lines=`cat $1 | grep "nr_ra" | wc -l`

        if [ $nr_ra_lines -eq 0 ]; then
                echo "ERROR: EXTRACT_NR_RA no nr_ra lines"
                exit
        fi
        
        nr_ra=`cat $1 | grep "nr_ra" | awk '{print $4}'`
        nr_bytes_ra=`cat $1 | grep "nr_bytes_ra" | awk '{print $4}'`

        echo $nr_ra
       # echo "nr_bytes_ra = $nr_bytes_ra"
}

EXTRACT_NR_RA_BYTES() {
        nr_ra_lines=`cat $1 | grep "nr_bytes_ra" | wc -l`

        if [ $nr_ra_lines -eq 0 ]; then
                echo "ERROR: EXTRACT_NR_RA no nr_ra lines"
                exit
        fi
        
        nr_bytes_ra=`cat $1 | grep "nr_bytes_ra" | awk '{print $4}'`

        echo $nr_bytes_ra
}

GET_NR_RA() {
	ra_resultfile=$TARGETDIR/${BASENAME}_nr_ra.dat
	ra_bytes_resultfile=$TARGETDIR/${BASENAME}_nr_ra_bytes.dat

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
                        FILENAME=${TECH}_${BASENAME}_${READSIZE}r_${RASIZE}ra_${NPROC}
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
}

GET_PERF

#GET_MISS_RATIO

#GET_NR_RA
