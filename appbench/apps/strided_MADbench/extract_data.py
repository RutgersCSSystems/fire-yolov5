#!/usr/bin/env python3

import os, mmap
from datetime import datetime
import itertools
import re


folder = "/users/shaleen/ssd/NVM/appbench/apps/strided_MADbench/results-sensitivity-nodbg/"
folder_out = "/users/shaleen/ssd/NVM/appbench/apps/strided_MADbench/cleaned_dat/"
#Data Info

NODAT = "-"
##From Filename
xaxis = ["PROC"]
yaxis = ["PRED"]
invariants = ["LOAD", "READSIZE", "TIMESPFETCH"]
data = ["Elapsed", "nr_filemap_faults"] ##From files

WORKLOADS = ["MADbench"]
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


def get_time_sec(line, delim=':| |,'):
    nums = [float(s.strip()) for s in re.split(delim, line) if is_number(s.strip())]
    time = 0.
    if len(nums) == 3: #hrs, mins, secs
        time = nums[0]*3600 + nums[1]*60 + nums[2]
    elif len(nums) == 2: ## mins, secs
        time = nums[0]*60 + nums[1]
    elif len(nums) == 1: #secs
        time = nums[0]
    return time


def get_num(in_line, keyword = "", delim=':| |,'):
    line = in_line.split(keyword, 1)[-1]
    nums = [int(s.strip()) for s in re.split(delim, line) if s.strip().isdigit()]
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
    ret = []
    try:
        with open(filepath) as f:
            filedata = f.readlines()
    except IOError:
        print("Error: File does not appear to exist. ", filepath)
        return NODAT

    for line in filedata:
        if dataname in line:
            if "Elapsed" in dataname or "time" in dataname:
                return get_time_sec(line)
            else:
                ret.append(get_num(line, dataname))
    if(len(ret) < 1):
        return NODAT
    return max(ret)




def write_dat(filepath, x, y, z, delim=", "):
    try:
         f = open(filepath, "a")
         string = str(x) + delim + str(y) + delim + str(z) 
         f.write(string + "\n")

    except IOError:
        print("Error: Unable to open file ", filepath)
        return False

    finally:
        f.close()


def main():
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
            outfile = para_dict["workload"]
            for i in range(len(invariants)):
                para_dict[invariants[i]] = tup_inv[i]
                outfile += "_"+invariants[i]+"-"+ str(tup_inv[i])
            for dat in data:
                outfile_now = outfile + "_"+dat+"_CLEANED.dat"
                first = True
                for x in xaxis:
                    list_x = globals()[x]
                    for x_vals in list_x:
                        para_dict[x] = x_vals
                        for y in yaxis:
                            list_y = globals()[y]
                            for y_vals in list_y:
                                para_dict[y] = y_vals
                                if first == True:
                                    write_dat(folder_out+outfile_now, "#"+x, y, dat)
                                    first = False
                                filename = get_filename(para_dict)
                                data_val = Extract(folder+filename, dat)
                                write_dat(folder_out+outfile_now, x_vals, y_vals, data_val)



if __name__ == "__main__":
    main()
