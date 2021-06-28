#!/usr/bin/env python3

##This program will take a results folder as input and print out performance
#characteristics for each parameter combination.
#It will not require list of all parameters values up front

import os, mmap, sys
from datetime import datetime
import itertools
import re

folder_out = "/users/shaleen/ssd/NVM/appbench/apps/strided_MADbench/analysis_scripts/"
one_dat_file = "2MB_limit_removed_oneanalysis.csv"
results_folder = "/users/shaleen/ssd/NVM/HPC-OUTPUT/strided_MADbench/"
results_folder += "bg-ra_size_sensitivity_08-35_06-21-21/"

DELIM = ","
NODAT = "-" #writes this in a no data point situation
RESULT_FILE_FORMAT = ".out"

##These should be in the same order as the result filenames
list_of_knobs = ["PROC", "PRED", "LOAD", "READSIZE", "TIMESPFETCH", "FUTUREPREFETCH", "RASIZE"]

#What are the different parameters to consider to pick a filename
variants = ["PROC", "PRED", "LOAD", "READSIZE", "TIMESPFETCH", "FUTUREPREFETCH", "RASIZE"] ##multiple
data = ["Elapsed"] #Output data extracted from files
out_order = variants + [s for s in data]


WORKLOADS = ["strided_MADbench"]
PROC = []
PRED = []
LOAD = []
READSIZE = []
TIMESPFETCH = []
FUTUREPREFETCH = []
RASIZE = []


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


#Doesnt handle anything other than numbers for the knob values
#gets all the values assigned to list_of_knobs in this results folder
def get_all_knob_values(results_folder, knobs_list):
    ##Get list of all files
    file_list = []
    for(dirpat, dirnames, filenames) in os.walk(results_folder): 
        file_list.extend(filenames) #TODO: Check if file is RESULT_FILE_FORMAT
    print(len(file_list))

    #go through all files and find unique knob values, populate the corresponding list
    for filename in file_list:
        temp = re.findall(r'\d+', filename)
        res = list(map(int, temp))

        #check if the nr of numbers extracted is equal to different knobs available
        if(len(res) != len(list_of_knobs)):
            print("ERR: filenames dont match the list_of_knobs")
            print("please fix the list_of_knobs in the script")
            sys.exit()

        ##Add unique elements to corresponding lists from list_of_knobs
        for i in range(len(list_of_knobs)):
            if(res[i] not in globals()[list_of_knobs[i]]):
                globals()[list_of_knobs[i]].append(res[i])
                globals()[list_of_knobs[i]].sort()


    print(PROC)
    print(PRED)
    print(LOAD)
    print(READSIZE)
    print(TIMESPFETCH)
    print(FUTUREPREFETCH)
    print(RASIZE)
    return


#given para_dict, get result filename
def get_infilename(para_dict, postfix=".out"):
    filename = ""
    filename += para_dict["workload"]+"_"
    filename += "PROC-"+str(para_dict["PROC"])+"_"
    filename += "PRED-"+str(para_dict["PRED"])+"_"
    filename += "LOAD-"+str(para_dict["LOAD"])+"_"
    filename += "READSIZE-"+str(para_dict["READSIZE"])+"_"
    filename += "TIMESPFETCH-"+str(para_dict["TIMESPFETCH"])+"_"
    filename += "FUTUREPREFETCH-"+str(para_dict["FUTUREPREFETCH"])+"_"
    filename += "RASIZE-"+str(para_dict["RASIZE"])
    filename += postfix
    return filename


#given a file name, extracts the numbers corresponding
#to the keywords provided
#Does Elapsed and READAHEAD_TIME
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


def write_from_dict(filepath, para_dict_1):
    line = ""
    for s in variants:
        line += str(para_dict_1[s])+","

    for s in data: ##adding first 
    	line += str(para_dict_1[s])+","

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
    get_all_knob_values(results_folder, list_of_knobs)

    all_variants = []
    for inv in variants:
        all_variants.append(globals()[inv])

    #Permutation of all knob values
    iter_variants = list(itertools.product(*all_variants))

    filename = ""
    para_dict = {}
    for workload in WORKLOADS:
        first_time = True
        para_dict["workload"] = workload
        print("Starting to Extract data from " + workload)
        for tup_inv in iter_variants: #For each permutation 
            for i in range(len(variants)): #Populate para_dict
                para_dict[variants[i]] = tup_inv[i]

            if first_time == True: ##Write first line to outfile
                write_dat(folder_out+one_dat_file, ",".join(out_order))
                first_time = False

            in_filename = get_infilename(para_dict)
            for dat in data: # For each data types    
                data_val = Extract(results_folder+in_filename, dat)
                para_dict[dat] = str(data_val)
                
            write_from_dict(folder_out+one_dat_file, para_dict)



##main
if __name__ == "__main__":
    main()
