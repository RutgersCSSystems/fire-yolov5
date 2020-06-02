#!/usr/bin/env python3.6
##This script goes through dmesg and consolidates messages like
#PID 3053 Proc-name mpirun page cache 0 kernel buffs 42149 app pages 2603139


import csv
import json
import sys
import os
import re
import subprocess
from subprocess import STDOUT, check_call


MESSAGE_IDENTIFIER='ATOMICs'

STATICFILE='/tmp/LastStamp.time'

Counters = ['FilePages', 'AnonPages', 'SharedPages', 'SwapEntries']

#################################################################
def main():
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Try: ./readdmesg.py (init), or (readfrom filename)")
        sys.exit()

    OutDict = {}

    if sys.argv[1] == 'init':
        out = BashExec('dmesg | tail -1')
        for line in out.stdout:
            laststamp = re.findall("\d+\.\d+", line)[0]
            #print(laststamp)
            outfile = open(STATICFILE, 'w+')
            outfile.write(laststamp)
            outfile.close()


    elif sys.argv[1] == 'readfrom':
        outfile = open(STATICFILE, 'r')
        startStamp = outfile.readline()
        #startStamp = sys.argv[2]
        StartConsolidating = False
        out = BashExec('dmesg')

        for line in out.stdout:
            if(StartConsolidating == True):
                if(len(re.findall(MESSAGE_IDENTIFIER, line)) > 0):
                    #print(line)
                    split = line.split(' ')
                    for item in Counters:
                        try:
                            OutDict[item] += int(split[split.index(item)+1])
                        except:
                            OutDict[item] = int(split[split.index(item)+1])
        
            if re.findall("\d+\.\d+", line)[0] == startStamp:
                StartConsolidating = True
        AppendToFile(OutDict, sys.argv[2], startStamp)
#################################################################


#################################################################
def AppendToFile(OutDict, filename, TimeStamp):
    outfile = open(filename, 'a+')
    writeout = csv.writer(outfile, quoting=csv.QUOTE_ALL)
    Header = Counters.copy()
    Header.insert(0, 'TimeStamp')
    writeout.writerow(Header)

    OutDat = []
    OutDat.insert(0, str(TimeStamp))
    for item in Counters:
        OutDat.append(str(OutDict[item]))

    writeout.writerow(OutDat)
    outfile.close()

#################################################################



###################################################################
def BashExec(Command):
    run = subprocess.Popen([Command], shell=True, stdout=subprocess.PIPE, \
            universal_newlines=True, stderr=subprocess.PIPE, bufsize=0)
    return run
###################################################################



if __name__ == "__main__":
    main()
