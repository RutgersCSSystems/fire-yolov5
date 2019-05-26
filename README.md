# NVM

### Compiling and launching QEMU 

From the NVM source directory set the environment variables.
trusty specifies the host systems linux version/codename 
Pass your own OS version name
```
 source scripts/setvars.sh "trusty"   
```
Create the QEMU IMAGE only for the first time. You should 
not create an image (which is your disk now) every time you will be 
compiling and testing your kernel.

During installation, if prompted (y,n), enter yes

```
 scripts/qemu_create.sh  
```

Install the 4.17 kernel with QEMU support and copy kernel files to boot directory
```
  scripts/compile_kern_kvm.sh
```

Now launch the QEMU
```
  scripts/run_qemu.sh
```

### Compiling only the kernel
```
 source scripts/setvars.sh "trusty"
 scripts/compile_kern.sh
```

### Compiling Linux scalability benchmark
```
 scripts/makes_scale_bench.sh
```

### Running mmap benchmark
```
 cd linux-scalability-benchmark/mmapbench

//e.g. ./mmapbench 1 500000 
 ./mmapbench NUMCORES NUMPAGES
```

### Automatically Tracing an application

To enable tracing and disable or stop tracing without modifying 
an application, use the following steps

1. Compile a shared library with methods to handle application launch.<br />
This is just a one time operation to install the shared library

```
 source scripts/setvars.sh "trusty"
 scripts/compile_sharedlib.sh
```
2. Install the shared library in QEMU. Again, this is one time operation. <br />
Note: Make sure your QEMU is not running

```
 scripts/copy_data_to_qemu.sh shared_libs/construct/libmigration.so mountdir/usr/lib/
```

3. Once you have installed the libraries first time, any time you run  <br />
an application, either do a LD_PRELOAD or link the library when compiling  <br />
from inside the QEMU

```
//RUN this inside QEMU
 LD_PRELOAD=/usr/lib/libmigration.so ./APP
```

### Installing appbench
Below are the short steps; for more details, see appbench README

Step 1: First, get the appbench, setup libraries, download datasets
```
 git clone https://github.com/SudarsunKannan/appbench
 source scripts/setvars.sh
 cd $APPBENCH
 source setvars.sh
 $APPBENCH/setup.sh
 $APPBENCH/compile_all.sh
```
Step 2: For running a benchmark, say LevelDB

 $APPBENCH/leveldb/out-static/db_bench


### Changing bandwidth of a NUMA node 

Step 1: Run the throttling script

```
 source scripts/setvars.sh "trusty"
 $APPBENCH/install_quartz.sh
 $APPBENCH/throttle.sh
```

Step 2: For modifying bandwidth of throttled node, open the following file

```
     vim $APPBENCH/shared_libs/quartz/nvmemul.ini
```

Step 3: Change the read and write to same bandwidth values
```
        bandwidth:
        {
            enable = true;
            model = "/tmp/bandwidth_model";
            read = 5000;
            write = 5000;
        };
   ```
Step 4: Run the throttling script again to check the value

```
 $APPBENCH/throttle.sh
```

### Compiling RocksDB build mode

Change this line in make file and execute compile command
```
LDFLAGS += $(EXTRA_LDFLAGS) -L/usr/lib -lgflags
DEBUG_LEVEL=0 make shared_lib db_bench -j32
```



