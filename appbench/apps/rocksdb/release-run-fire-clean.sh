#!/bin/bash
#set -euo pipefail
set -x

# Set up logging
LOGFILE="rocksdb_yolo_script_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Script started at $(date)"

# Trap for error handling and cleanup
cleanup() {
    local exit_code=$?
    echo "Script exited with code $exit_code at $(date)"
    if [ $exit_code -ne 0 ]; then
        echo "An error occurred. Check the log file $LOGFILE for details."
    fi
    # Add any cleanup code here
    exit $exit_code
}
trap cleanup EXIT INT TERM

# Ensure required environment variables are set
: "${APPS:?APPS environment variable is undefined. Did you setvars?}"
: "${OUTPUTDIR:?OUTPUTDIR is not set}"
: "${PREDICT_LIB_DIR:?PREDICT_LIB_DIR is not set}"
: "${SCRIPTS:?SCRIPTS is not set}"

DBHOME=$PWD
DBDIR=$DBHOME/DATA
RESULTS="RESULTS"
APP=db_bench
APPOUTPUTNAME="ROCKSDB"

# Default values
THREAD=16
VALUE_SIZE=4096
SYNC=0
KEYSIZE=1000
WRITE_BUFF_SIZE=67108864
BATCHSIZE=128
NUM=20000000
USEDB=1
MEM_REDUCE_FRAC=1
ENABLE_MEM_SENSITIVE=1

# Arrays
declare -a num_arr=("20000000")

declare -a membudget=("10" "20" "40" "60" "50" "30")
declare -a membudget=("40" "50" "30" "20" "10")
#declare -a membudget=("10")

declare -a trials=("TRIAL1")

declare -a workload_arr=("multireadrandom" "readseq" "readwhilescanning" "readreverse")
declare -a workload_arr=("multireadrandom")

declare -a thread_arr=("32")
#declare -a config_arr=("Vanilla" "OSonly" "CII" "CIPI_PERF" "CPBI_PERF" "isolated-yolo" "isolated-rocksdb")
declare -a config_arr=("OSonly" "isolated-yolo" "isolated-rocksdb")

declare -a batch_arr=("20" "40" "60" "80")
declare -a batch_arr=("60" "20" "80")


# APPPREFIX options
APPPREFIX="nice -n -20"

# Function definitions
FlushDisk() {
    echo "Flushing disk caches..."
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches && sync && echo 3 > /proc/sys/vm/drop_caches && sync"
    sleep 5
}

CLEAR_DATA() {
    echo "Clearing data..."
    sudo killall -9 $APP || true
    rm -rf "$DBDIR"/* *.sst CURRENT IDENTITY LOCK MANIFEST-* OPTIONS-* WAL_LOG/
}

RUN_FIRE_ML() {
    echo "Running Fire ML with batch size $2..."
    cd ../yolov5-fire-detection || { echo "Failed to change directory to yolov5-fire-detection"; exit 1; }
    ./train-run-med.sh "$2" &> "$1"
    sleep 5
}

GEN_RESULT_PATH() {
    local WORKLOAD=$1
    local CONFIG=$2
    local THREAD=$3
    local NUM=$4
    local BATCHSIZE=$5
    local KEYCOUNT=$((NUM/1000000))

    if [ "$ENABLE_MEM_SENSITIVE" -eq "0" ]; then
        RESULTS="$OUTPUTDIR/$APPOUTPUTNAME/${KEYCOUNT}M-KEYS/$THREAD/batchsize-$BATCHSIZE/$WORKLOAD/"
    else
        RESULTS="$OUTPUTDIR/$APPOUTPUTNAME/${KEYCOUNT}M-KEYS/$THREAD/batchsize-$BATCHSIZE/MEMFRAC$MEM_REDUCE_FRAC/$WORKLOAD/"
    fi

    mkdir -p "$RESULTS"
    RESULTFILE="$RESULTS/$CONFIG.out"
    YOVLOV_RESULTFILE="$RESULTS/YOVLOVOUT-$CONFIG.out"
    echo "Results will be written to $RESULTFILE"
}

CLEAR_PROCESS() {
    echo "Clearing processes..."
    sudo killall -9 python pt_main_thread || true
    sleep 5
}

RUN() {
    echo "Starting RUN function..."
    echo "BEGINNING TO WARM UP ......."
    cd "$PREDICT_LIB_DIR" || { echo "Failed to change directory to $PREDICT_LIB_DIR"; exit 1; }
    ./compile.sh &> compile.out
    cd "$DBHOME" || { echo "Failed to change directory to $DBHOME"; exit 1; }
    echo "FINISHING WARM UP ......."
    echo "..................................................."
    FlushDisk
    sudo dmesg -c

    for NUM in "${num_arr[@]}"; do
        echo "Running for NUM=$NUM"
        ./compile.sh &>> out.txt
        cd "$DBHOME" || { echo "Failed to change directory to $DBHOME"; exit 1; }
        for THREAD in "${thread_arr[@]}"; do
            echo "Running for THREAD=$THREAD"
            PARAMS="--db=$DBDIR --value_size=$VALUE_SIZE --wal_dir=$DBDIR/WAL_LOG --sync=$SYNC --key_size=$KEYSIZE --write_buffer_size=$WRITE_BUFF_SIZE --num=$NUM --num_levels=6 --target_file_size_base=33554432 -max_background_compactions=8 --seed=100000000"
            for CONFIG in "${config_arr[@]}"; do
                echo "Running for CONFIG=$CONFIG"
                for BATCHSIZE in "${batch_arr[@]}"; do
                    echo "Running for BATCHSIZE=$BATCHSIZE"
                    cd "$DBHOME" || { echo "Failed to change directory to $DBHOME"; exit 1; }
                    for WORKLOAD in "${workload_arr[@]}"; do
                        echo "Running for WORKLOAD=$WORKLOAD"
                        cd "$DBHOME" || { echo "Failed to change directory to $DBHOME"; exit 1; }
                        GEN_RESULT_PATH "$WORKLOAD" "$CONFIG" "$THREAD" "$NUM" "$BATCHSIZE"
                        echo "RUNNING $CONFIG and writing results to $RESULTFILE"
                        echo "..................................................."
                        
                        case "$CONFIG" in
                            "isolated-yolo")
                                echo "Running isolated YOLO configuration"
                                RUN_FIRE_ML "$YOVLOV_RESULTFILE" "$BATCHSIZE"
                                wait $! # Wait for YOLO process to complete
                                ;;
                            "isolated-rocksdb")
                                echo "Running isolated RocksDB configuration"
                                READARGS="--benchmarks=$WORKLOAD --use_existing_db=$USEDB --mmap_read=0 --threads=$THREAD"
                                rm -rf "$DBDIR/LOCK"
                                echo "$APPPREFIX ./$APP $PARAMS $READARGS"
                                $APPPREFIX "./$APP" $PARAMS $READARGS &> "$RESULTFILE"
                                ;;
                            *)
                                READARGS="--benchmarks=$WORKLOAD --use_existing_db=$USEDB --mmap_read=0 --threads=$THREAD"
                                rm -rf "$DBDIR/LOCK"
                                echo "$APPPREFIX ./$APP $PARAMS $READARGS"
                                $APPPREFIX "./$APP" $PARAMS $READARGS &> "$RESULTFILE" &
                                ROCKSDB_PID=$!
                                
                                echo "$YOVLOV_RESULTFILE"
                                RUN_FIRE_ML "$YOVLOV_RESULTFILE" "$BATCHSIZE" &
                                YOLO_PID=$!
                                
                                echo "Waiting for RocksDB (PID: $ROCKSDB_PID) and YOLO (PID: $YOLO_PID) to complete..."
                                wait $ROCKSDB_PID
                                wait $YOLO_PID
                                ;;
                        esac
                        
                        sudo dmesg -c &>> "$RESULTFILE"
                        echo ".......FINISHING $CONFIG......................"
                        echo ".......FINISHING $CONFIG......................"
                        FlushDisk
                        CLEAR_PROCESS
                    done
                done
            done
        done
    done
    echo "RUN function completed."
}

GETMEMORYBUDGET() {
    local PERCENTAGE=$1
    echo "Getting memory budget for percentage $PERCENTAGE%"
    
    sudo rm -rf /mnt/ext4ramdisk/*
    "$SCRIPTS/mount/umount_ext4ramdisk.sh"
    sudo rm -rf /mnt/ext4ramdisk /mnt/ext4ramdisk/*
    "$SCRIPTS/mount/releasemem.sh" "NODE0"
    "$SCRIPTS/mount/releasemem.sh" "NODE1"

    FlushDisk    
    
    let NUMAFREE0=$(numactl --hardware | grep "node 0 free:" | awk '{print $4}')
    let NUMAFREE1=$(numactl --hardware | grep "node 1 free:" | awk '{print $4}')
    
    #local REDUCTION_FACTOR=$(awk "BEGIN {printf \"%.2f\", $PERCENTAGE/100}")
    local REDUCTION_FACTOR=$(awk "BEGIN {printf \"%.2f\", (100 - $PERCENTAGE)/100}")
    local NUMANODE0=$(awk "BEGIN {printf \"%.0f\", $NUMAFREE0 * $REDUCTION_FACTOR}")
    #local NUMANODE1=$(awk "BEGIN {printf \"%.0f\", $NUMAFREE0 * $REDUCTION_FACTOR}")
    #We reduce the memory node 1 to 500MB
    local NUMANODE1=500
    
    local DISKSZ0=$((NUMAFREE0 - NUMANODE0))
    local DISKSZ1=$((NUMAFREE1 - NUMANODE1))
    
    echo "MEMORY $PERCENTAGE%"
    echo "REDUCING NODE 0: $DISKSZ0 ****NODE 1: $DISKSZ1"
    
    numactl --membind=0 "$SCRIPTS/mount/reducemem.sh" $DISKSZ0 "NODE0"
    numactl --membind=1 "$SCRIPTS/mount/reducemem.sh" $DISKSZ1 "NODE1"

    let NUMAFREE0=$(numactl --hardware | grep "node 0 free:" | awk '{print $4}')
    let NUMAFREE1=$(numactl --hardware | grep "node 1 free:" | awk '{print $4}')

    echo "AFTER REDUCING MEMORY NODE 0: $NUMAFREE0 ****NODE 1: $NUMAFREE1"


}


# Main execution
echo "Setting ulimit..."
ulimit -n 1000000

for G_TRIAL in "${trials[@]}"; do
    echo "Starting trial $G_TRIAL"
    if [ "$ENABLE_MEM_SENSITIVE" -eq "1" ]; then
        for MEM_REDUCE_FRAC in "${membudget[@]}"; do
            echo "Running with MEM_REDUCE_FRAC=$MEM_REDUCE_FRAC"
            GETMEMORYBUDGET "$MEM_REDUCE_FRAC"
            RUN
            "$SCRIPTS/mount/releasemem.sh" "NODE0"
            "$SCRIPTS/mount/releasemem.sh" "NODE1"
        done
    else
        echo "Running without memory sensitivity"
        RUN
    fi
done

echo "Script completed successfully at $(date)"
