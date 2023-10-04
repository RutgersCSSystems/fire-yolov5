## Artifact Evaluation Submission for CrossPrefetch [ASPLOS '24]

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

(1) First, we encourage users to use the CloudLab (Clemson cluster) (c6525-100g), which has 48 CPUs and two Samsung NVMe SSDs. We have created a Cloudlab profile, "c6525" to create the instance easily.

(2) Cloudlab Machine Setup

First, you would have to set up a filesystem and mount it on an NVMe SSD

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

First, compile and install the CrossPrefetch OS components.

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

The following script will set the environment variables and install the user-level library.
```
# Navigate to the source folder
cd ~/ssd/ioopt
source ./scripts/setvars.sh
cd $BASE/shared_libs/simple_prefetcher/
./compile.sh
```

#### Basic Run (Shorter duration: less than 1 hour)

##### Running RocksDB
First, we will start with running medium workloads. As a first step, we will start running RocksDB, a persistent key-value store.  

To compile, assuming the environmental variables are set using `set_vars.sh`. The following commands will install the necessary packages to compile RocksDB.
```
cd $BASE/appbench/apps/rocksdb
./compile.sh
```

To run multiple configurations of RocksDB by varying APPonly (i.e., application-controlled prefetching, which is a Vanilla RocksDB), 
OSonly (OS controlled), and Cross-prefetch configurations for various thread counts, and workloads.
```
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

##### Running YCSB

To run a real-world YCSB workload

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

##### Running MMAP 

Next, to run the microbenchmark for MMAP, which will create a large data file (64GB) and issue 32 threads to concurrently access it.

```
cd $BASE/appbench/apps/simple_bench/mmap_exp/
./compile.sh
./release-run-med.sh
python3 release-extract-med.py
cat RESULT.csv
```

#### Long Running (> 1 hour)
We now discuss the results for long-running workloads, which can vary from tens
of minutes to a few hours, depending on the machine configuration.

##### Running Snappy (Memory Budget)

Snappy experiment runs the Snappy benchmark that concurrently compresses different
folders across threads. We generate an input of around 300GB-350GB of data. The
scripts also reduce the available memory for the application to study the
effectiveness of CrossPrefetch under reducing memory capacity.

```
cd $BASE/appbench/apps/snappy-c
# The value indicates an input to generate the dataset
./gendata-run-med.sh 1
./release-run-med.sh 
python3 release-extract-med.py
cat RESULT.csv
```

##### Running Microbenchmark
The microbenchmarks can take different durations depending on the storage
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
For remote storage experiments, we will use m510 with remote NVMe support.
These nodes are easily available and quick to launch!  We have already created
a publically available CloudLab profile where one could launch two m510 NVMe
nodes with NVMeOF setup across these nodes.

Please follow the following steps:

**1. Instantiating the nodes**

(1) First, use the following CloudLab UTAH m510 nodes, which are easy to reserve and use. Use the following profile:
**Machine Node Name:** m510
**Profile Name:** 2-NVMe-Nodes

(2) Now, you must set up a filesystem and mount it. 
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
