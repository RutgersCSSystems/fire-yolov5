#!/usr/bin/env python3.6
##Read input json and generate csv

import csv
import json
import sys
import os
import re
import subprocess
from subprocess import STDOUT, check_call

MAX = 100000000000000000
MIN = -10000000000000000

TimeReturns = ['Elapsed', 'Usertime', 'Kerneltime', 'CPU', 'MAXRSS', 'MajorPageFaults', \
        'MinorPageFaults', 'Vol-ContextSwitches', 'InVol-ContextSwitches', 'ExitStat']

ToReturn = ['Elapsed']

Header = ["#PCAnonRatio", "DirtyBackgroundRatio", "DirtyRatio", "Min Elapsed Time (sec)", "Elapsed Time (sec)", "Max Elapsed Time (sec)"]

def main():
    if len(sys.argv) != 3:
        print('Add filename to read from and write to')
        sys.exit("Incorrect number of arguments")
    filename = sys.argv[1]
    #print(filename)
    Data = []
    outfile = open(sys.argv[2], 'w+')
    writeout = csv.writer(outfile, quoting=csv.QUOTE_ALL)
    writeout.writerow(Header)

    with open(filename) as json_file:
        Data = json.load(json_file)

    #print(len(Data))
    
    thisconfig = {}
    for thisconfig in Data:
        OUTData = []
        #print(thisconfig['PCRatio'])
        OUTData.append(thisconfig['PCRatio'])
        OUTData.append(thisconfig['DirtyBgRatio'])
        OUTData.append(thisconfig['DirtyRatio'])
        MinElapsed = MAX
        MaxElapsed = MIN
        Runs = thisconfig['Run'] ##List of all runs
        totalElapsed = 0
        for eachrun in Runs:
            Elapsed = float(eachrun['Elapsed'])
            totalElapsed += Elapsed
            if Elapsed > MaxElapsed: MaxElapsed = Elapsed
            if Elapsed <= MinElapsed: MinElapsed = Elapsed
        OUTData.append(str(MinElapsed))
        OUTData.append(str(totalElapsed/len(Runs)))
        OUTData.append(str(MaxElapsed))
        writeout.writerow(OUTData)



if __name__ == "__main__":
    main()
