CrossPrefetch
==================================================
DELETE THIS: Best Performing:
```
refactor-sudarsun-perf-3 commit a4eb9bf4e5ac34c759afafb7925753f30a0ec4e9
Author: sudarsun <kannan11@node-0.prefetch5.lsm-pg0.clemson.cloudlab.us>
```


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

(1) First, use the following CloudLab Wisconsin node, which is easy to reserve and use. Use the following profile:

**Machine Node Name:** c220g5 
**Profile Name:** single-raw-ubuntu-18

(2) Partition Setup & cloning
If you use CloudLab, the root partition is only 16GB for some profiles.
First, set up the CloudLab node with SSD and install all the required libraries.
```
lsblk
```

Now, you would have to set up a filesystem and mount it. 

```
sudo mkfs.ext4 /dev/sda4
mkdir ~/ssd; sudo mount /dev/sda4 ~/ssd
cd ~/ssd; sudo chown $USER .
```

Now, get the appropriate repo.
```
cd ssd
git clone https://github.com/RutgersCSSystems/ioopt
cd ioopt
```

You now have the repo. Before compiling and setting up things, let's set the environmental variable.

First in the file **scripts/setvars.sh**, set the machine data center to identify the results by changing this variable. 
Because we are using Wisconsin, you could do something like this and save the file.
```
source ./scripts/setvars.sh
# Let's install the Debian packages
scripts/install_packages.sh
```

### Compile Kernel

#### To compile deb for bare metal systems
```
cd $BASE/linux-5.14.0
## This will produce and install the modified kernel
./compile_modified_deb.sh 
sudo reboot ## This will reboot the node with the new Linux. 
```

After rebooting, we need mount the storage again.

```
sudo mount /dev/sda4 ~/ssd
cd ~/ssd; sudo chown $USER .
```
## Run Experiments
All experiments are in the following folder. This script needs to be updated to run different applications. 
Check the scripts before running all_variation.
```
# Navigate to the source folder
cd ~/ssd/ioopt
source ./scripts/setvars.sh
cd $BASE/shared_libs/simple_prefetcher/
./compile.sh
```

### Starting with Medium Workloads

#### Running Microbenchmark

Let's run the Microbenchmark, where we generate 100GB of files, vary the size of each request, and measure the throughput.

First, to compile the microbenchmark with different workloads, use the following steps:
```
cd  $BASE/appbench/apps/simple_bench/multi_thread_read
mkdir bin
make -j4
```

To run the workload and see the results.
```
./release-run-med.sh
python3 release-extract-med.py
cat RESULT.csv
```

##### MMAP 

```
cd $BASE/appbench/apps/simple_bench/mmap_exp/
./compile.sh
./release-run-med.sh
```

##### File Sharing
```
cd shared_libs/simple_prefetcher/benchmarks
make
./run_scalability.sh
```

#### Running RocksDB
First, we will start with running medium workloads, which will take between 3-5 hours (or longer) to complete.
As a first step, we will start running RocksDB, a persistent key-value store.  
To compile, assuming the environmental variables are set using set_vars.sh

Let's compile RocksDB first. The script will install the necessary packages to install RocksDB.
```
cd $BASE/appbench/apps/rocksdb
./compile.sh
```

The following script runs multiple configurations of RocksDB by varying APPonly (i.e., application-controlled prefetching, which is a Vanilla RocksDB), 
OSonly (OS controlled), and Cross-prefetch configurations for various thread counts, and workloads.
```
./release-run-med.sh
```
The following script will first warm up and generate the database with a raw uncompressed size of 100GB and run the experiment on 4 million key-value pairs.   

Results will be generated in the following folder for 4M keys for different access patterns.
```
ls $OUTPUT_FOLDER/ROCKSDB/4M-KEYS/
```

To extract the results, 
```
./generate_values.sh
```

#### Running YCSB

To run YCSB workload
```
cd $BASE/appbench/apps/RocksDB-YCSB
./compile.sh
./release-run-med.sh
```
To extract and see the results
```
cd $BASE/appbench/apps/RocksDB-YCSB
python3 release-extract-med.py
cat RESULT.csv
```


#### Running Snappy
```
cd $BASE/appbench/apps/snappy-c
# run snappy. The value indicates an input to generate the dataset
./release-run-med.sh 1 
```


### Running Remote Storage Experiments
For remote storage experiments, we will use m510 with remote NVMe support.
These nodes are easily available and quick to launch!  We have already created
a publically available cloudlab profile where one could launch two m510 NVMe
nodes with NVMeOF setup across these nodes.

Please follow the following steps:

**1. Instantiating the nodes**

(1) First, use the following CloudLab UTAH m510 nodes, which is easy to reserve and use. Use the following profile:
**Machine Node Name:** m510
**Profile Name:** 2-NVMe-Nodes

(2) Now, you would have to set up a filesystem and mount it. 
```
sudo mkfs.ext4 /dev/nvme0n1
mkdir ~/ssd; sudo mount /dev/nvme0n1p1 ~/ssd
cd ~/ssd; sudo chown $USER .
```
Now, get the appropriate repo.
```
cd ssd
git clone https://github.com/RutgersCSSystems/ioopt
cd ioopt
```
You now have the repo. Before compiling and setting up things, let's set the environmental variable.

First in the file **scripts/setvars.sh**, set the machine data center to identify the results by changing this variable. 
Because we are using Wisconsin, you could do something like this and save the file.
```
source ./scripts/setvars.sh 
```

**2. Compiling the the OS on these nodes**
Compiling the OS is very similar to the one described earlier. First, let's
compile the OS for the client node where we run the application. Note the
client node is different from the storage node that hosts the storage.

```
cd ssd/$BASE/linux-5.14.0
## This will produce and install the modified kernel
./compile_modified_deb.sh 
sudo reboot ## This will reboot the node with the new Linux 5.14
```

**3. Remote NVMe setup using NVMeOF and RDMA**
@Jian add detailed steps for Remote NVMe setup. Please describe clearly

**4. Running experiments**

For remote storage execution, we will use the following script. 
```
cd $BASE/appbench/apps/rocksdb
./release-remote-run-med.sh
python3 release-run-remote-med.sh
#Display the results
cat REMOTE-RESULT.csv
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




