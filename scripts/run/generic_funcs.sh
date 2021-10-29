#Holds all the generic functions needed to run scripts
#To use simple call source $RUN_SCRIPTS/generic_funcs.sh in your script

if [ -z "$APPS" ]; then
    echo "APPS environment variable is undefined."
    echo "Did you setvars? goto Base directory and $ source ./scripts/setvars.sh"
    exit 1
fi

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo dmesg --clear
}

ENABLE_LOCK_STATS()
{
	sudo sh -c "echo 0 > /proc/lock_stat"
	#sudo sh -c "echo 1 > /proc/sys/kernel/lock_stat"
}

DISABLE_LOCK_STATS()
{
	sudo sh -c "echo 0 > /proc/sys/kernel/lock_stat"
}


##Builds the preload library
BUILD_PRED_LIB()
{
    pushd $PREDICT_LIB_DIR
    ./compile.sh
    popd
}

#Preloads the appropriate library
SETPRELOAD()
{
    if [[ "$1" == "APPLIBOS" ]]; then ##All three
        echo "enabling all predictors"
        export LD_PRELOAD=/usr/lib/libcrosslayer.so
    elif [[ "$1" == "NOPRED" ]]; then ##None
        echo "setting nopred"
        export LD_PRELOAD=/usr/lib/libnopred.so
    elif [[ "$1" == "ONLYAPP" ]]; then
        echo "only app pred"
        export LD_PRELOAD=/usr/lib/libonlyapppred.so
    elif [[ "$1" == "ONLYLIB" ]]; then
        echo "only Lib pred"
        export LD_PRELOAD=/usr/lib/libonlylibpred.so
    elif [[ "$1" == "ONLYOS" ]]; then
        echo "only OS pred"
        export LD_PRELOAD=/usr/lib/libonlyospred.so
    elif [[ "$1" == "APPOS" ]]; then
        echo "App+OS pred"
        export LD_PRELOAD=/usr/lib/libos_apppred.so
    elif [[ "$1" == "LIBOS" ]]; then
        echo "Lib+OS pred"
        export LD_PRELOAD=/usr/lib/libos_libpred.so
    elif [[ "$1" == "JUSTSTATS" ]]; then
        echo "preload lib enable just global stats hit/miss rate"
        export LD_PRELOAD=/usr/lib/libjuststats.so
    fi

    ##export TARGET_GPPID=$PPID
}

SLEEPNOW() {
    sleep 2
}


REFRESH() {
    export LD_PRELOAD=""
    $NVMBASE/scripts/compile-install/clear_cache.sh
    sudo sh -c "dmesg --clear" ##clear dmesg
    SLEEPNOW
}


##Reduces size of ram if needed
SETUPEXTRAM() {

    let CAPACITY=$1

    let SPLIT=$CAPACITY/2
    echo "SPLIT" $SPLIT

    sudo rm -rf  /mnt/ext4ramdisk0/*
    sudo rm -rf  /mnt/ext4ramdisk1/*

    $NVMBASE/scripts/mount/umount_ext4ramdisk.sh 0
    $NVMBASE/scripts/mount/umount_ext4ramdisk.sh 1

    SLEEPNOW

    NUMAFREE0=`numactl --hardware | grep "node 0 free:" | awk '{print $4}'`
    NUMAFREE1=`numactl --hardware | grep "node 1 free:" | awk '{print $4}'`

    let DISKSZ=$NUMAFREE0-$SPLIT-712
    let ALLOCSZ=$NUMAFREE1-$SPLIT-712

    echo "NODE 0 $DISKSZ NODE 1 $ALLOCSZ"

    $NVMBASE/scripts/mount/mount_ext4ramdisk.sh $DISKSZ 0
    $NVMBASE/scripts/mount/mount_ext4ramdisk.sh $ALLOCSZ 1

    SLEEPNOW
}
