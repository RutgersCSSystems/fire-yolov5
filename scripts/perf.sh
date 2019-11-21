#cd $KERN_SRC/tools/perf
#make && sudo make install
perf record -e instructions,mem-loads,mem-stores --vmlinux=/lib/modules/4.17.0/build/vmlinux $1
#perf report --sort=dso --stdio
perf report 
