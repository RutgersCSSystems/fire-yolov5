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
