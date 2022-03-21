#Holds all the generic functions needed to run scripts
#To use simple call source $RUN_SCRIPTS/generic_funcs.sh in your script

KB=1024
MB=`echo "1024*$KB" | bc`
GB=`echo "1024*$MB" | bc`
PAGE_SZ=`echo "4*$KB" | bc`

NR_REPEATS=5

RIGHTNOW=`date +"%Hhr-%Mmin_%m-%d-%y"`
DATE=`date +'%d-%B-%y'`
APPPREFIX="/usr/bin/time -v"

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
                export LD_PRELOAD=/usr/lib/lib_OSonly.so
        elif [[ "$1" == "CBNMB" ]]; then
                printf "Cross_BlockRA_NoPred_MaxMem_BG\n"
                export LD_PRELOAD=/usr/lib/lib_CBNMB.so
        elif [[ "$1" == "CFNMB" ]]; then
                printf "Cross_FileRA_NoPred_MaxMem_BG\n"
                export LD_PRELOAD=/usr/lib/lib_CFNMB.so
        elif [[ "$1" == "CFPMB" ]]; then
                printf "Cross_FileRA_Pred_MaxMem_BG\n"
                export LD_PRELOAD=/usr/lib/lib_CFPMB.so
        elif [[ "$1" == "CBPMB" ]]; then
                printf "Cross_BlockRA_Pred_MaxMem_BG\n"
                export LD_PRELOAD=/usr/lib/lib_CBPMB.so
        elif [[ "$1" == "CBPBB" ]]; then
                printf "Cross_BlockRA_Pred_Budget_BG\n"
                export LD_PRELOAD=/usr/lib/lib_CBPBB.so
        elif [[ "$1" == "CBNBB" ]]; then
                printf "Cross_BlockRA_NoPred_Budget_BG\n"
                export LD_PRELOAD=/usr/lib/lib_CBNBB.so
        elif [[ "$1" == "MEMUSAGE" ]]; then
                printf "Checks the MemUsage for this App\n"
                export LD_PRELOAD=/usr/lib/lib_memusage.so
        fi
        ##export TARGET_GPPID=$PPID
}

UNSETPRELOAD(){
        export LD_PRELOAD=""
}

#clears cache and unloads
REFRESH() {
        UNSETPRELOAD
        umount_ext4ramdisk
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


umount_ext4ramdisk() {
        sudo umount /mnt/ext4ramdisk
        sudo rm -rf /mnt/ramdisk/ext4.image
        sudo umount /mnt/ramdisk
}

mount_ext4ramdisk() {
        DISKSZ=$1 #Input in MB

        umount_ext4ramdisk

        sudo mkdir /mnt/ramdisk
        sudo mount -t ramfs ramfs /mnt/ramdisk
        sudo dd if=/dev/zero of=/mnt/ramdisk/ext4.image bs=1M count=$DISKSZ
        sudo mkfs.ext4 -F /mnt/ramdisk/ext4.image
        sudo mkdir /mnt/ext4ramdisk
        sudo mount -o loop /mnt/ramdisk/ext4.image /mnt/ext4ramdisk
        sudo chown -R $USER /mnt/ext4ramdisk
        #sudo ln -s /mnt/ext4ramdisk $APPBENCH/shared_data
}

##Reduces size of ram if needed
##1 numa node
SETUPEXTRAM_1() {

        let APP_BUDGET=$1 ##in MB

        echo "APP Budget = $APP_BUDGET MB"

        let SPLIT=$APP_BUDGET ##in MB

        sudo rm -rf  /mnt/ext4ramdisk/*

        umount_ext4ramdisk

        SLEEPNOW

        NUMAFREE0=`numactl --hardware | grep "node 0 free:" | awk '{print $4}'`

        let DISKSZ=$NUMAFREE0-$SPLIT-500

        echo "creating ramdisk of size $DISKSZ MB"

        mount_ext4ramdisk $DISKSZ

        SLEEPNOW
}

##Reduces size of ram if needed
##NOT WORKING RIGHT NOW
##2 numa nodes
SETUPEXTRAM_2() {

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
