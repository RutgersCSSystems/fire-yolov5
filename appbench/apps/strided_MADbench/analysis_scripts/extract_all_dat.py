#!/usr/bin/env python3

#This program takes two in_folders and prints out 


import os, mmap
from datetime import datetime
import itertools
import re

one_dat_file = "bg_pinned_analysis.csv"
in_folder1 = "/Users/shaleen/Research/NVM/HPC-OUTPUT/strided_MADbench/sensitivity-bg-pinned-17-02_04-07-21/"
#in_folder2 = "/Users/shaleen/Research/NVM/HPC-OUTPUT/strided_MADbench/nanosleep-20000-sensitivity-03-48_03-31-21"
folder_out = "/Users/shaleen/Research/NVM/HPC-OUTPUT/strided_MADbench/"

DELIM = ","
NODAT = "-"
##From Filename
variants = ["PROC", "LOAD", "READSIZE", "TIMESPFETCH"] ##multiple
#data = ["Elapsed", "READAHEAD_TIME"] ##multiple
data = ["Elapsed"]

identifier_0 = "nopred_"
identifier_1 = "sleep_nobg_"
#identifier_2 = "bg_"


#out_order = variants + [identifier_1 + s for s in data] + [identifier_2 + s for s in data]
out_order = variants + [identifier_1 + s for s in data]
out_order += [identifier_0+"Elapsed"]

WORKLOADS = ["strided_MADbench"]
PROC = [1, 4]
PRED = [0, 1]
LOAD = [4096, 8192]
READSIZE = [1048576, 4194304]
TIMESPFETCH = [1, 4]
RASIZE = [2560, 4096, 8192, 16384]



def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False


def micro_to_sec(line, delim=':| |,'):
    print(line)
    nums = [float(s.strip()) for s in re.split(delim, line) if is_number(s.strip())]
    return nums[0]/1000000


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
#def get_filename(workload, variants, tup_inv, x, x_vals, y, y_vals, postfix=".out"):
def get_infilename(para_dict, postfix=".out"):
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
            if "Elapsed" in dataname:
                return get_time_sec(line)
            elif "READAHEAD_TIME" in dataname:
                ret.append(micro_to_sec(line))
            else:
                ret.append(get_num(line, dataname))
    if(len(ret) < 1):
        return NODAT
    return max(ret)


def write_from_dict(filepath, para_dict):
    line = ""
    for s in out_order:
        line += str(para_dict[s])+","

    line = line.rstrip(",")
    write_dat(filepath, line)


def write_dat(filepath, line):
    try:
         f = open(filepath, "a")
         #string = str(x) + delim + str(y) + delim + str(z) 
         f.write(line + "\n")

    except IOError:
        print("Error: Unable to open file ", filepath)
        return False

    finally:
        f.close()


def main():
    all_variants = []
    for inv in variants:
        all_variants.append(globals()[inv])

    iter_variants = list(itertools.product(*all_variants))
    para_dict = {}
    for workload in WORKLOADS:
        first_time = True
        para_dict["workload"] = workload
        if first_time == True: #Write the first line in file
            write_dat(folder_out+one_dat_file, ",".join(out_order))
            first_time = False
        #for each invariant permutation
        for tup_inv in iter_variants:

            for i in range(len(variants)): #populate para_dict
                para_dict[variants[i]] = tup_inv[i]

            para_dict["PRED"] = 0 
            timesprefetch = para_dict["TIMESPFETCH"]
            para_dict["TIMESPFETCH"] = 1
            no_pred_infilename = get_infilename(para_dict)
            para_dict["PRED"] = 1
            para_dict["TIMESPFETCH"] = timesprefetch
            pred_infilename = get_infilename(para_dict)

            #first populate no_pred
            for dat in data:
                data_val = Extract(in_folder1+no_pred_infilename, dat)
                para_dict[identifier_0+dat] = str(data_val)

                data_val = Extract(in_folder1+pred_infilename, dat)
                para_dict[identifier_1+dat] = str(data_val)

                #data_val = Extract(in_folder2+pred_infilename, dat)
                #para_dict[identifier_2+dat] = str(data_val)

            write_from_dict(folder_out+one_dat_file, para_dict)



##main
if __name__ == "__main__":
    main()
