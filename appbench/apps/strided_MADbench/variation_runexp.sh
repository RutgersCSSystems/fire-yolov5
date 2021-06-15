#!/bin/bash
#set -x

if [ -z "$NVMBASE" ]; then
    echo "NVMBASE environment variable not defined. Have you ran setvars?"
    exit 1
fi

##prefetch window multiple factor 1, 2, 4
##grep the elapsed time, file faults, minor faults, system time, user time

APP="strided_MADbench"
RIGHTNOW=`date +"%H-%M_%m-%d-%y"`
APPDIR=$APPS/strided_MADbench
RESULTS_FOLDER=$OUTPUTDIR/$APP/bg-ra_size_sensitivity_$RIGHTNOW
DEV=/dev/sda4 ##device being used for this experiment
mkdir -p $RESULTS_FOLDER
cd $APPDIR

declare -a predict=("0" "1")
declare -a workarr=("4096" "8192")
declare -a thrdarr=("1" "4" "16")
##application read size 4KB, 512KB, 1MB, 4MB
declare -a readsize=("4096" "524288" "1048576" "4194304")
#sizeofprefetch = prefetchwindow * readsize
declare -a prefetchwindow=("1" "2")
declare -a futureprefetch=("1" "4" "10" "20" "50") 

#force_page_cache_readahead - max_pages = 320, 512, 1024, 2048 ($maxpages*4096/512)
declare -a rasize=("2560" "4096" "8192" "16384") 


#APPPREFIX="numactl --membind=0"
APPPREFIX=""
FLUSH=1 ##FLUSHES and clears cache AFTER EACH WRITE

export IOMODE=SYNC
export FILETYPE=UNIQUE
export IOMETHOD=POSIX

STRIDE=7 # set stride to $STRIDE * RECORD_SIZE

REFRESH() {
    export LD_PRELOAD=""
    rm -rf files/
    $NVMBASE/scripts/compile-install/clear_cache.sh
    sudo sh -c "dmesg --clear" ##clear dmesg
    sleep 2
}

#Here is where we run the application
RUNAPP() 
{
    echo "**********RUNAPP**********"
    #Run application
    cd $APPDIR

    NPROC=$1
    WORKLOAD=$2
    PREDICT=$3
    RECORD=$4
    TPREFETCH=$5
    FPREFETCH=$6


    #set RAsize for the device
    RASIZE=$7
    sudo blockdev --setra  $RASIZE $DEV
    echo -n "blockdev getra = "; sudo blockdev --getra $DEV

    OUTPUT=$RESULTS_FOLDER/$APP"_PROC-"$NPROC"_PRED-"$PREDICT"_LOAD-"$WORKLOAD"_READSIZE-"$RECORD"_TIMESPFETCH-"$TPREFETCH"_FUTUREPREFETCH-"$FPREFETCH"_RASIZE-"$RASIZE".out"

    echo "*********** running $OUTPUT ***********"

    export TIMESPREFETCH=$TPREFETCH
    export FUTUREPREFETCH=$FPREFETCH

    APPPREFIX="/usr/bin/time -v"

    if [[ "$PREDICT" == "1" ]]; then
        export LD_PRELOAD=/usr/lib/libcrosslayer.so
    else
        export LD_PRELOAD=/usr/lib/libnopred.so
    fi

    COMMAND="$APPPREFIX mpiexec -n $NPROC ./MADbench2_io $WORKLOAD 30 1 8 64 1 1 $RECORD $STRIDE $FLUSH"
    echo "$COMMAND"
    numactl --hardware &> $OUTPUT
    wait; sync
    $COMMAND &>> $OUTPUT
    export LD_PRELOAD=""
    wait; sync
    echo "*******************DMESG OUTPUT******************" >> $OUTPUT
    dmesg | grep -v -F "systemd-journald" >> $OUTPUT
    wait; sync

}


make clean; make -j ##Make MADBench
REFRESH

for NPROC in "${thrdarr[@]}"
do	
    for WORKLOAD in "${workarr[@]}"
    do
        for READSIZE in "${readsize[@]}"
        do
            for PREDICT in "${predict[@]}"
            do 
                for RASIZE in "${rasize[@]}"
                do
                    for PREFETCHTIMES in "${prefetchwindow[@]}"
                    do 
                        for FUTUREPREFETCH in "${futureprefetch[@]}"
                        do
                            RUNAPP $NPROC $WORKLOAD $PREDICT $READSIZE $PREFETCHTIMES $FUTUREPREFETCH $RASIZE
                            REFRESH

                            if [ "$PREDICT" -eq "0" ]; then
                                break;
                            fi
                        done
                        if [ "$PREDICT" -eq "0" ]; then
                            break;
                        fi
                    done
                done
            done
        done 
    done	
done

git add $RESULTS_FOLDER
message="results_at "
message+=$RIGHTNOW
git commit -m "$message"
git push
