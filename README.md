Crosslayer: Random One liner
==================================================

A small description


### Directory structure
```
.
├── README.md
├── appbench            # application workloads
├── linux-5.14.0        # Modified Linux kernel
├── references.txt      # list of references for paper
├── results             # folder with all results 
├── scripts             # all scripts for setup and microbench running
└── shared_libs/pred    # shared lib predictor src
```


### Setup Environment


#### Cloudlab Node allocation
Recommendation to use c6525-100g@Utah; this one has two large NVMe SSDs.
Use Profile CS764Fall2018/single-raw-ubuntu-18 to setup the node.
```
https://www.cloudlab.us/show-profile.php?uuid=76d501c8-02fb-11e9-9331-90e2ba22fee4
```

#### Partition Setup & cloning

If you are using CloudLab, the root partition is only 16GB for some profiles.
First setup the CloudLab node with SSD and install all the required libraries.

```
lsblk
```

You should see the following indicating the root partition size is very small:

```
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
nvme0n1     259:1    0  1.5T  0 disk 
├─nvme0n1p1 259:2    0   16G  0 part /
├─nvme0n1p2 259:3    0    3G  0 part 
├─nvme0n1p3 259:4    0    3G  0 part [SWAP]
└─nvme0n1p4 259:5    0  1.4T  0 part 
nvme1n1     259:7    0  1.5T  0 disk  ##This partition fails the node sometimes
```

Now you would have to setup a filesystem and mount it 

```
sudo mkfs.ext4 /dev/nvme0n1p4

mkdir ~/ssd; sudo mount /dev/nvme0n1p4 ~/ssd

cd ~/ssd; sudo chown $USER .
```


Now to get the appropriate branch

```
cd ssd
git clone git@github.com:RutgersCSSystems/prefetching.git
cd prefetching
```

You now have the repo. Before running things, run

```
cd prefetching
source ./scripts/setvars.sh ## This sets appropriate env variables
```



### Compile Kernel

#### To compile deb for baremetal

Before running the following commands, make sure you dont have other deb files in the NVM folder.

```
cd prefetching/linux-5.14.0
./compile_modified_deb.sh ## This will produce and install the modified kernel
#./compile_vanilla_deb.sh ## This will produce and install the vanilla kernel
sudo reboot ## this will reboot the node with the new linux 
```

#### To compile for qemu

```
source ./scripts/setvars.sh
cd prefetching/linux-5.14.0
./compile_qemu.sh
cd prefetching
./scripts/compile-install/compile_kern_kvm.sh
```

### Qemu Management

#### Qemu Setup

```
./scripts/qemu/qemu_create.sh ## has to be done only once
```

#### Installing all the required libraries in the QEMU
```
scripts/compile-install/set_appbench.sh 
```

#### Run Qemu
To run qemu, first compile the kernel for qemu; then

```
./scripts/qemu/run_qemu.sh
```


### Run Experiments
All the experiments are in the following folder.
this script needs to be updated to run different applications

Check the scripts before running all_variation.

```
./scripts/run/run_all_variation.sh
```

## Running RocksDB: A Persistent Key-Value Store for Flash and RAM Storage

### Run rocksdb with or without using the new pread_ra syscall

To enable pread_ra syscall that is enabled for crossfs
```
//vim Makefile
//## add -DCROSSLAYER_SYSCALLS to CXXFLAGS (line 20)
//CXXFLAGS += ${EXTRA_CXXFLAGS} -DCROSSLAYER_SYSCALLS

vim build_tools/build_detect_platform
COMMON_FLAGS="$COMMON_FLAGS ${CFLAGS} -DCROSSLAYER_SYSCALLS"
./compile.sh
```

### Alternatively, navigate to RocksDB folder
To enable pread_ra syscall
```
cp build_tools/build_detect_platform_cross build_tools/build_detect_platform
./compile.sh
```

To disable pread_ra syscall
```
cp build_tools/build_detect_platform_orig build_tools/build_detect_platform
./compile.sh
```

### Alternatively, to run all for RocksDB
```
./run.sh 
```

The script uses the following options
```
       if [[ "$PREDICT" == "LIBONLY" ]]; then
                #uses read_ra but disables OS prediction
                echo "setting LIBONLY pred"
                cp $DBHOME/build_tools/build_detect_platform_cross $DBHOME/build_tools/build_detect_platform
                $DBHOME/compile.sh &> compile.out
                export LD_PRELOAD=/usr/lib/libonlylibpred.so
        elif [[ "$PREDICT" == "CROSSLAYER" ]]; then
                #uses read_ra
                echo "setting CROSSLAYER pred"
                cp $DBHOME/build_tools/build_detect_platform_cross $DBHOME/build_tools/build_detect_platform
                $DBHOME/compile.sh &> compile.out
                export LD_PRELOAD=/usr/lib/libos_libpred.so

        elif [[ "$PREDICT" == "OSONLY" ]]; then
                #does not use read_ra and disables all application read-ahead
                echo "setting OS pred"
                cp $DBHOME/build_tools/build_detect_platform_orig $DBHOME/build_tools/build_detect_platform
                $DBHOME/compile.sh &> compile.out
                export LD_PRELOAD=/usr/lib/libonlyospred.so
        else [[ "$PREDICT" == "VANILLA" ]]; #does not use read_ra
                echo "setting VANILLA"
                cp $DBHOME/build_tools/build_detect_platform_orig $DBHOME/build_tools/build_detect_platform
                $DBHOME/compile.sh &> compile.out
                export LD_PRELOAD=""
        fi
```


