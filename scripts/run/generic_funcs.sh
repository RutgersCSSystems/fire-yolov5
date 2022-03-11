#Holds all the generic functions needed to run scripts
#To use simple call source $RUN_SCRIPTS/generic_funcs.sh in your script

KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`
PAGE_SZ=`echo "4*$KB" | bc`

NR_REPEATS=5

RIGHTNOW=`date +"%Hhr-%Mmin_%m-%d-%y"`
DATE=`date +'%d-%B-%y'`

FlushDisk()
{
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches"
    sudo sh -c "sync"
    sleep 5
}

SLEEPNOW() {
    sleep 2
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


SETPRELOAD()
{
    if [[ "$1" == "VANILLA" ]]; then ##No library involvement
        printf "Running Vanilla\n"
        export LD_PRELOAD=""
    elif [[ "$1" == "OSONLY" ]]; then ##Only OS prefetching enabled
        printf "Only OS prefetching enabled\n"
        export LD_PRELOAD=/usr/lib/libsimplenoprefetcher.so
    elif [[ "$1" == "CFNMB" ]]; then
        printf "Cross_FileRA_NoPred_MaxMem_BG\n"
        export LD_PRELOAD=/usr/lib/libsmpl_fullprefetcher.so
    elif [[ "$1" == "APPLIBOS" ]]; then ##All three
        printf "setting pred\n"
        export LD_PRELOAD=/usr/lib/libcrosslayer.so
    elif [[ "$1" == "NOPRED" ]]; then ##None
        printf "setting nopred\n"
        export LD_PRELOAD=/usr/lib/libnopred.so
    elif [[ "$1" == "ONLYAPP" ]]; then
        printf "only app pred\n"
        export LD_PRELOAD=/usr/lib/libonlyapppred.so
    elif [[ "$1" == "ONLYLIB" ]]; then
        printf "only Lib pred\n"
        export LD_PRELOAD=/usr/lib/libonlylibpred.so
    elif [[ "$1" == "ONLYOS" ]]; then
        printf "only OS pred\n"
        export LD_PRELOAD=/usr/lib/libonlyospred.so
    elif [[ "$1" == "APPOS" ]]; then
        printf "App+OS pred\n"
        export LD_PRELOAD=/usr/lib/libos_apppred.so
    elif [[ "$1" == "LIBOS" ]]; then
        printf "Lib+OS pred\n"
        export LD_PRELOAD=/usr/lib/libos_libpred.so
    elif [[ "$1" == "ONLYINTERCEPT" ]]; then
        printf "Only Intercepting\n"
        export LD_PRELOAD=/usr/lib/libonlyintercept.so
    elif [[ "$1" == "CACHELIMIT" ]]; then
        printf "OS and LIB pred with Cache Limit\n"
        export LD_PRELOAD=/usr/lib/libcache_lim_os_libpred.so
    elif [[ "$1" == "FETCHALL" ]]; then
        printf "OS and LIB pred without Cache Limit\n"
        export LD_PRELOAD=/usr/lib/libos_fetch_at_open.so
    elif [[ "$1" == "FETCHALLSINGLE" ]]; then
        printf "OS and LIB pred without Cache Limit\n"
        export LD_PRELOAD=/usr/lib/libos_fetch_at_open_single.so
    elif [[ "$1" == "SIMPLEBGPREFETCH" ]]; then
        printf "Simple BG prefetcher\n"
        export LD_PRELOAD=/usr/lib/libsimpleprefetcher.so
    elif [[ "$1" == "SIMPLENOPREFETCH" ]]; then
        printf "Simple NO prefetcher\n"
        export LD_PRELOAD=/usr/lib/libsimplenoprefetcher.so
    elif [[ "$1" == "SIMPLEBGFULLPREFETCH" ]]; then
        printf "Simple BG FULL prefetcher\n"
        export LD_PRELOAD=/usr/lib/libsmpl_fullprefetcher.so
    elif [[ "$1" == "SIMPLEPREADRA" ]]; then
        printf "Simple Seq prefetch using pread_ra\n"
        export LD_PRELOAD=/usr/lib/libsimplepreadra.so
    fi

    ##export TARGET_GPPID=$PPID
}

UNSETPRELOAD(){
    export LD_PRELOAD=""
}

#clears cache and unloads
REFRESH() {
    UNSETPRELOAD
    FlushDisk
}

#Checks if the folder exits, if not, create new
CREATE_OUTFOLDER() {
        if [[ ! -e $1 ]]; then
                mkdir -p $1
        else
                echo "$1 already exists"
        fi
}


#returns the min out of list of numbers
min_number() {
	printf "%s\n" "$@" | sort -g | head -n1
}

#returns the max out of list of numbers
max_number() {
	printf "%s\n" "$@" | sort -gr | head -n1
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
