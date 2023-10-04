### Artifact Evaluation Submission for CrossPrefetch [ASPLOS '24]

This repository contains the artifact for reproducing our ASPLOS '24 paper "CrossPrefetch: Accelerating I/O Prefetching for Modern Storage".

### Directory structure
```
.
├── README.md
├── appbench/apps       # Application workloads
├── linux-5.14.0        # Modified Linux kernel (Cross-OS)
├── results             # Folder with all results 
├── scripts             # All scripts for setup and benchmark running
└── shared_libs/simple_prefetcher    # The user-level library (Cross-Lib)
```

### Setup Environment

(1) First, we encourage users to use NSF CloudLab Clemson node (`c6525-100g`), which has 48 CPUs and two Samsung NVMe SSDs. We have created a cloudlab profile "c6525" to create the instance easily.

(2) Cloudlab Machine Setup

First, you would have to set up a filesystem and mount it on a NVMe SSD

```
sudo mkfs.ext4 /dev/nvme0n1p4
mkdir ~/ssd; sudo mount /dev/nvme0n1p4 ~/ssd
cd ~/ssd; sudo chown $USER .
```

Now, get the appropriate repo.
```
cd ssd
git clone https://github.com/RutgersCSSystems/crossprefetch-asplos24-artifacts
cd crossprefetch-asplos24-artifacts
```

You now have the repo. Before compiling and setting up things, let's set the environmental variable and install the required packages by using the following commands.

```
source ./scripts/setvars.sh
# Let's install the Debian packages
scripts/install_packages.sh
```

### Compile and install modified Linux kernel

First compile and install the CrossPrefetch OS components

```
cd $BASE/linux-5.14.0
## This will produce and install the modified kernel
./compile_modified_deb.sh 
sudo reboot ## This will reboot the node with the new Linux. 
```

After rebooting, we need mount the storage again.

```
sudo mount /dev/nvme0n1p4 ~/ssd
cd ~/nvme0n1p4; sudo chown $USER .
```
### Run Experiments

We need **setup the environment variables and install the user-level library first before running any experiments**. 

This followwing script will setup the environment variables and install the user-level library
```
# Navigate to the source folder
cd ~/ssd/ioopt
source ./scripts/setvars.sh
cd $BASE/shared_libs/simple_prefetcher/
./compile.sh
```

#### Basic Run (Shorter duration: less than 1 hour)

##### Running RocksDB + YCSB
First, we will start with running medium workloads. As a first step, we will start running RocksDB with a real-world YCSB workload.  

Before compiling, we need to make sure the environmental variables are set by `set_vars.sh`.

 The following commands will install the necessary packages to compile RocksDB with YCSB. 
```
cd $BASE/appbench/apps/RocksDB-YCSB
./compile.sh

```

We run YCSB with multiple configurations of RocksDB by varying APPonly (i.e.,
application-controlled prefetching, which is a Vanilla RocksDB), OSonly (OS
controlled) by turning off application prefetch operations and Cross-prefetch
configurations for various thread counts, and workloads.

Then run YCSB, extract and see the results
```
cd $BASE/appbench/apps/RocksDB-YCSB
./release-run-med.sh
python3 release-extract-med.py
cat RESULT.csv
```

##### Running RocksDB + DB_bench

Next, we will run RocksDB with a widely used KV benchmark DB_bench.

```
cd $BASE/appbench/apps/rocksdb
./compile.sh
./gendata-run-med.sh
./release-run-med.sh
```
The above script will first warm up and generate the database with a raw uncompressed size of 100GB and run the experiment on 4 million key-value pairs.   

Results will be generated in the following folder for 4M keys for different access patterns.

To extract and see the results 
```
python3 release-extract-med.py
cat RESULT.csv
```

Note: We observe that OSonly performance may vary on different machines with varying SSD
storage due to its reliance on OS prefetching, which can be unpredictable and occasionally 
improve performance. This highlights the need for a Cross-layered approach.

##### Running MMAP 

Next, to run the microbenchmark for MMAP, which will create a large data file (64GB) and issue 32 threads to access it concurrently.

```
cd $BASE/appbench/apps/simple_bench/mmap_exp/
./compile.sh
./release-run-med.sh
python3 release-extract-med.py
cat RESULT.csv
```

#### Long Running (> 1 hour)
We now discuss the results for long-running workloads which can vary from tens
of minutes to few hours dependent on the machine configuration.

##### Running Snappy (Memory Budget)

Snappy experiment runs benchmark that concurrently compresses different
folders across threads. We generate an input of around 300GB-350GB of data. The
scripts also reduce the available memory for the application to study the
effectivenss of CrossPrefetch under reducing memory capacity.

```
cd $BASE/appbench/apps/snappy-c
# The value indicates an input to generate the dataset
./gendata-run-med.sh 1
./release-run-med.sh 
python3 release-extract-med.py
cat RESULT.csv
```

##### Running Microbenchmark
The microbenchmarks can take different duration depending on the storage
hardware and the available memory in the system.  Let's run the microbenchmark,
where we generate 100GB of files, vary the size of each request, and measure
the throughput.

First, to compile the microbenchmark with different workloads, use the
following steps:
```
cd  $BASE/appbench/apps/simple_bench/multi_thread_read
./compile.sh
```
To run the workload and see the results.
```
./release-run-med.sh
python3 release-extract-med.py
cat RESULT.csv
```

#### Running Remote Storage Experiments
For remote storage experiments, we will use `m510` with remote NVMe support.
These nodes are easily available and quick to launch!  We have already created
a publically available cloudlab profile where one could launch two `m510` NVMe
nodes with NVMe-oF setup across these nodes. In addition, we also provide a easy to use script to setup the NVMe-oF.

Please follow the following steps:

**1. Instantiating the nodes**

(1) First, create two CloudLab UTAH `m510` nodes by using the profile `2-NVMe-Nodes`

(2) Next, clone our provided script on both nodes to setup the NVMe-oF

```
git clone https://github.com/RutgersCSSystems/crossprefetch-asplos24-artifacts
cd scripts/remote-nvme-setup/
```

(3)  Next, we need to setup the target and client node seperately. 

On Target Node:

You can pick whatever node you want as a target node, but just make sure the machine RDMA IP is match with the `IP_ADDR` in the `target_setup.sh` script
```
# First format the NVMe partition that you want the client to use.
sudo mkfs.ext4 /dev/nvme0n1p4

# Then replace ""/dev/nvme0n1p4" in target_setup.sh with the target block device.
# Also modify IP_ADDR in target_setup.sh to be the addr of the TARGET machine, and run the script.
sudo ./target_setup.sh
```

On Client Node:

The remaining node will be the client node. Before running the script, make sure the `IP_ADDR` in the `client_setup.sh` is using the IP address of the **target machine RDMA IP**.

```
# Replace ADDR with the IP address of the target RDMA interface.
sudo ./client_setup.sh
```
After that you can run `lsblk` to check that the `/mnt/remote` is mount on the remote disk `/dev/nvme1n1` 

After that, same as local experiment we need to get the appropriate repo, set the environmental variable  and install the user-level library. Please refer to aboev local experiment instructions

**4. Running experiments**

For remote storage execution, we need to run the following scripts on client node.

```
cd $BASE/appbench/apps/rocksdb
./release-remote-run-med.sh
python3 release-run-remote-med.sh
#Display the results
cat REMOTE-RESULT.csv
```

