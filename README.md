# NVM

### Compiling and launching QEMU 

From the NVM source directory set the environment variables.
trusty specifies the host systems linux version/codename 
Pass your own OS version name
```
$ source scripts/setvars.sh "trusty"   
```

Create the QEMU IMAGE and exit.  If prompted (y,n), enter yes
```
$ scripts/qemu_create.sh  
$ exit
```

Install the 4.17 kernel with QEMU support and copy kernel files to boot directory
```
$  scripts/compile_kern.sh
```

Now launch the QEMU
```
$  scripts/run_qemu.sh
```

### Compiling only the kernel
```
$ source scripts/setvars.sh "trusty"
$ scripts/compile_kern.sh
```

### Compiling Linux scalability benchmark
```
$ scripts/makes_scale_bench.sh
```

### Running mmap benchmark
```
$ cd linux-scalability-benchmark/mmapbench

//e.g. ./mmapbench 1 500000 
$ ./mmapbench NUMCORES NUMPAGES
```

### Automatically Tracing an application

To enable tracing and disable or stop tracing without modifying 
an application, use the following steps

1. Compile a shared library with methods to handle application launch.<br />
This is just a one time operation to install the shared library

```
$ source scripts/setvars.sh "trusty"
$ scripts/compile_sharedlib.sh
```
2. Install the shared library in QEMU. Again, this is one time operation. <br />
Note: Make sure your QEMU is not running

```
$ scripts/copy_data_to_qemu.sh shared_libs/construct/libmigration.so mountdir/usr/lib/
```

3. Once you have installed the libraries first time, any time you run  <br />
an application, either do a LD_PRELOAD or link the library when compiling  <br />
from inside the QEMU

```
//RUN this inside QEMU
$ LD_PRELOAD=/usr/lib/libmigration.so ./APP
```
