#!/usr/bin/env python3

import os, mmap
from datetime import datetime
import itertools


folder = "/users/shaleen/ssd/NVM/appbench/apps/strided_MADbench/results-sensitivity-nodbg/"
#Data Info

##From Filename
xaxis = ["PROC"]
yaxis = ["PRED"]
invariants = ["LOAD", "READSIZE", "TIMESPFETCH"]
data = ["Elapsed", "nr_filemap_faults"] ##From files

WORKLOADS = ["MADBench"]
PROC = [1, 4, 16]
PRED = [0, 1]
LOAD = [4096, 8192, 16384]
READSIZE = [4096, 131072, 524288, 1048576, 4194304, 16777216]
TIMESPFETCH = [1, 2, 4]


def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False


def get_time_sec(line, delim=":"):
    nums = [float(s) for s in str.split(delim) if is_number(s)]
    time = 0.
    if len(nums) == 3: #hrs, mins, secs
        time = nums[0]*3600 + nums[1]*60 + nums[2]
    elif len(nums) == 2: ## mins, secs
        time = nums[0]*60 + nums[1]
    elif len(nums) == 1: #secs
        time = nums[0]
    return time


def get_num(line, delim=":"):
    nums = [int(s) for s in str.split(delim) if s.isdigit()]
    if len(nums) > 1:
        print("WARNING: get_num has more numbers than anticipated")
    return nums[0]


#def get_filename(workload, PROC, PRED, LOAD, READSIZE, TIMESPFETCH, postfix=".out"):
#def get_filename(workload, invariants, tup_inv, x, x_vals, y, y_vals, postfix=".out"):
def get_filename(para_dict, postfix=".out"):
    filename = ""
    filename += para_dict["workload"]+"_"
    filename += "PROC-"+str(para_dict["PROC"])+"_"
    filename += "PRED-"+str(para_dict["PRED"])+"_"
    filename += "LOAD-"+str(para_dict["LOAD"])+"_"
    filename += "READSIZE-"+str(para_dict["READSIZE"])+"_"
    filename += "TIMESPFETCH-"+str(para_dict["TIMESPFETCH"])
    filename += postfix
    return filename

#given a file name, extracts the numbers corresponding
#to the keywords provided
def Extract(filepath, dataname):
    ret = 0.
    try:
        with open(filepath) as f:
            filedata = f.readlines()
    except IOError:
        print("Error: File does not appear to exist. ", filepath)
        return "-"

    for line in filedata:
        if dataname in line:
            if "Elapsed" in dataname or "time" in dataname:
                ret = get_time_sec(line)
                return ret
            else:
                ret = get_num(line)
                return ret


def main():
    #fname = "MADbench_PROC-4_PRED-1_LOAD-8192_READSIZE-1048576_TIMESPFETCH-1.out"
    #Extract(folder+fname, "Elapsed")
    all_invariants = []
    for inv in invariants:
        all_invariants.append(globals()[inv])

    iter_invariants = list(itertools.product(*all_invariants))
    filename = ""
    para_dict = {}
    for workload in WORKLOADS:
        para_dict["workload"] = workload
        print("Starting to Extract data from " + workload)
        for tup_inv in iter_invariants:
            para_dict[invariants[0]] = tup_inv[0]
            para_dict[invariants[1]] = tup_inv[1]
            para_dict[invariants[2]] = tup_inv[2]
            for x in xaxis:
                list_x = globals()[x]
                for x_vals in list_x:
                    para_dict[x] = x_vals
                    for y in yaxis:
                        list_y = globals()[y]
                        for y_vals in list_y:
                            para_dict[y] = y_vals
                            for dat in data:
                                filename = get_filename(para_dict)
                                print(filename)
                                Extract(filename, dat)

    return

    for inv in invariants:
        for x in xaxis:
            for y in yaxis:
                for dat in data:
                    outfile = ".out"
                    Extract(filename, dat)
    

if __name__ == "__main__":
    main()
