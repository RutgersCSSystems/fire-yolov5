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
export MACHINE_NAME="WISC"
```  
```
source ./scripts/setvars.sh 
```

### Compile Kernel

#### To compile deb for bare metal systems
```
cd $BASE/linux-5.14.0
## This will produce and install the modified kernel
./compile_modified_deb.sh 
sudo reboot ## This will reboot the node with the new Linux. 
```

## Run Experiments
All experiments are in the following folder. Use this script needs to be updated to run different applications Check the scripts before running all_variation.
```
cd $BASE/shared_libs/simple_prefetcher/
./compile.sh
cd $BASE
```

### Starting with Medium Workloads

#### Running Microbenchmark

```
cd shared_libs/simple_prefetcher/benchmarks
make
./run_scalability.sh
```

#### Running RocksDB
First, we will start with running medium workloads, which will take more than 1.5 to 2 hours to complete.
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
./release-run-med.sh
```
To extract and see the results
```
cd $BASE/appbench/apps/RocksDB-YCSB
./compile.sh
python3 extract.py
cat RESULT.csv
```


#### Running Snappy
```
cd $BASE/appbench/apps/snappy-c
# run snappy. The value indicates an input to generate the dataset
./release-run-med.sh 1 
```


### Running Remote Storage Experiments

For remote storage execution, we will use the following script. 
```
./release-remote-run-med.sh
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




