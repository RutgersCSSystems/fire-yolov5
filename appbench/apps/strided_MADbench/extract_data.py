#!/usr/bin/env python3

import os, mmap
from datetime import datetime
import itertools
import re


folder = "/Users/shaleen/Research/NVM/appbench/apps/strided_MADbench/results-sensitivity-nodbg/"
folder_out = "/Users/shaleen/Research/NVM/appbench/apps/strided_MADbench/cleaned_dat/"
#Data Info

DELIM = ","
NODAT = "-"
##From Filename
xaxis = ["PROC"] #one only
yaxis = ["PRED"] # one only
invariants = ["LOAD", "READSIZE", "TIMESPFETCH"] # multiple
data = ["Elapsed", "nr_filemap_faults"] ##multiple

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
            if "Elapsed" in dataname or "time" in dataname:
                return get_time_sec(line)
            else:
                ret.append(get_num(line, dataname))
    if(len(ret) < 1):
        return NODAT
    return max(ret)




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
            #for dat in data:
            #    outfile += ":"+dat
    
            for x in xaxis: #For all x axis types
                list_x = globals()[x]
                first_x = True #first time writing to outfile_now
                if(first_x == True):
                    outfile_x = outfile + "_Xaxis="+str(x)
                    first_line_x = "#" + x
                for y in yaxis: #for all yaxis types
                    list_y = globals()[y]
                    first_y = True
                    if first_y == True:
                        outfile_now = outfile_x + "_Yaxis="+str(y)
                        first_line = first_line_x + DELIM + y

                    for x_vals in list_x: #for each element in that xaxis
                        para_dict[x] = x_vals
                        for y_vals in list_y: #for each element in that yaxis
                            para_dict[y] = y_vals
                            out_line = str(x_vals) + DELIM + str(y_vals)
                            
                            for dat in data: # For each data types    
                                #Dynamic generation of filename + first line
                                if first_x == True or first_y == True:
                                    first_line += DELIM + dat
                                    outfile_now += ":"+dat
                                
                                in_filename = get_infilename(para_dict)
                                data_val = Extract(folder+in_filename, dat)
                                
                                out_line += DELIM + str(data_val)

                            if first_x == True or first_y == True: #write first line
                                outfile_now += "_CLEANED.dat"
                                print(outfile_now)
                                write_dat(folder_out+outfile_now, first_line)
                                first_x = False
                                first_y = False

                            write_dat(folder_out+outfile_now, out_line)


if __name__ == "__main__":
    main()
