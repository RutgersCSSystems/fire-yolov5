#!/usr/bin/env python3

##This program will take a results folder as input and print out performance
#characteristics for each parameter combination.
#It will not require list of all parameters values up front

import os, mmap, sys
from datetime import datetime
import itertools
import re

results_folder = "/users/shaleen/ssd/NVM/HPC-OUTPUT/strided_MADbench/"
results_folder += "bg-ra_size_sensitivity_08-35_06-21-21"

DELIM = ","
NODAT = "-" #writes this in a no data point situation
RESULT_FILE_FORMAT = ".out"

##These should be in the same order as the result filenames
list_of_knobs = ["PROC", "PRED", "LOAD", "READSIZE", "TIMESPFETCH", "FUTUREPREFETCH", "RASIZE"]

#What are the different parameters to consider to pick a filename
variants = ["PROC", "PRED", "LOAD", "READSIZE", "TIMESPFETCH"] ##multiple
data = ["Elapsed"] #Output data extracted from files


WORKLOADS = ["strided_MADbench"]
PROC = []
PRED = []
LOAD = []
READSIZE = []
TIMESPFETCH = []
FUTUREPREFETCH = []
RASIZE = []


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



def main():
    get_all_knob_values(results_folder, list_of_knobs)



##main
if __name__ == "__main__":
    main()
