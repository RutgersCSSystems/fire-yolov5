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
└── shared_libs/simple_prefetcher    # shared lib predictor src
└── shared_libs/memory_analysis    # returns the anon and cache usage during an apprun
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

Now, you would have to set up a filesystem and mount it. 

```
sudo mkfs.ext4 /dev/nvme0n1p4

mkdir ~/ssd; sudo mount /dev/nvme0n1p4 ~/ssd

cd ~/ssd; sudo chown $USER .
```


Now, get the appropriate repo.

```
cd ssd
git clone https://github.com/RutgersCSSystems/ioopt
cd ioopt
```

You now have the repo. Before compiling and set up things, let's set the environmental variable
```
source ./scripts/setvars.sh 
```

### Compile Kernel

#### To compile deb for bare metal systems
```
cd $BASE/linux-5.14.0
./compile_modified_deb.sh ## This will produce and install the modified kernel
sudo reboot ## This will reboot the node with the new Linux. 
```

### Run Experiments
All experiments are in the following folder. Use this script needs to be updated to run different applications Check the scripts before running all_variation.
```
cd $BASE/shared_libs/simple_prefetcher/
./compile.sh
cd $BASE
```

## Running RocksDB: A Persistent Key-Value Store for Flash and RAM Storage
To compile, assuming the environmental variables are set using set_vars.sh
```
cd $NVMBASE/appbench/apps/rocksdb
./compile.sh
```

The following script runs multiple configurations of RocksDB by varying 
Cross-prefetch configurations and vanilla configurations, thread counts, and workloads.

For local storage execution, we will use rocksdb-exp-test.sh script. 
```
./rocksdb-exp-test.sh 

```
For remote storage execution, we will use rocksdb-exp-test.sh script. 
```
./rocksdb-exp-test-remote.sh
```


#### Varying Parameters
To vary either RocksDB parameters, workloads, or the technique used for prefetching, vary one of these parameters in the 
rocksdb-exp-test.sh script

For the number of keys, we set the values here. We use by default 20M keys and 100-byte keys. If you want to change the number 
of keys, update this
```
declare -a num_arr=("20000000")
NUM=20000000
```

#### Varying Parameters
```
declare -a workload_arr=("readseq" "readrandom" "readwhilescanning" "readreverse" "multireadrandom")
declare -a config_arr=("OSonly" "Vanilla" "Cross_Info" "Cross_Info_sync" "CII" "CIP" "CIP_sync" "CIPI")
declare -a thread_arr=("4" "8" "16" "32")
```


## Deprecated After this.


## Result extraction and Graph Generation (script under progress)









