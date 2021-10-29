#!/usr/bin/env python3

import os
import datetime

test_dir="./fio-test"
time = "28s"
rampup_time = "2s"
file_size = "10G"
io_depths = [1024]
block_sizes = ["4K"]
thread_counts = [4]
workloads = ["write", "randread"] #["read", "write", "randread", "randwrite", "readwrite", "randrw"]
threadings = [""]


fio_python_script = "fio"

base_command = fio_python_script + " --name=_name_ --directory=_directory_ --time_based " + \
            "--size=_file_size_ --runtime=_time_ --ramp_time=_rampup_ " + \
            "--ioengine=libaio --direct=0 --verify=0 --bs=_block_size_ " + \
            "--iodepth=_io_depth_ --rw=_workload_ --group_reporting=1 " + \
            "--numjobs=_thread_count_ _threading_"

workload_time = 28 + 2

num_runs = len(io_depths) * len(block_sizes) * len(thread_counts) * \
            len(workloads) * len(threadings)

time_s = workload_time * num_runs

conversion = datetime.timedelta(seconds=time_s)

def get_echo(string):
    return "echo \"" + string + "\""

print("#!/bin/bash")
print(get_echo("Number of runs: " + str(num_runs)))
print(get_echo("Estimated time to complete: " + str(conversion)))

flushcache = "sudo sh -c \"echo 3 > /proc/sys/vm/drop_caches\"; sudo sh -c \"sync\"; sudo sh -c \"sync\"; sudo sh -c \"echo 3 > /proc/sys/vm/drop_caches\""

ctr = 1
for workload in workloads:
    for block_size in block_sizes:
        for io_depth in io_depths:
            for threading in threadings:
                for thread_count in thread_counts:
                    command = base_command
                    command = command.replace("_name_", "nvme")
                    command = command.replace("_directory_", test_dir)
                    command = command.replace("_time_", time)
                    command = command.replace("_rampup_", rampup_time)
                    command = command.replace("_file_size_", file_size)
                    command = command.replace("_workload_", workload)
                    command = command.replace("_block_size_", str(block_size))
                    command = command.replace("_io_depth_", str(io_depth))
                    command = command.replace("_threading_", threading)
                    command = command.replace("_thread_count_", str(thread_count))
                    
                    print("rm -rf " + test_dir)
                    print("mkdir " + test_dir)
                    print(flushcache)
                    print(command)
                    progress = "{:.2f}".format((ctr / num_runs) * 100)
                    print(get_echo("Progess: completed " + str(ctr) + " runs " + \
                            "out of " + str(num_runs) + " [" + progress + "%]"))
                    ctr = ctr + 1

print("rm -rf " + test_dir)
                
        






