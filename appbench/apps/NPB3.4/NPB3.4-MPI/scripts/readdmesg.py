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

def getLastStamp():
    laststamp = 0
    out = BashExec('dmesg | tail -1')
    for line in out.stdout:
        laststamp = re.findall("\d+\.\d+", line)[0]
        break
    return laststamp

#################################################################
def main():
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Try: ./readdmesg.py (init), or (readfrom filename)")
        sys.exit()

    OutDict = {}

    if sys.argv[1] == 'init':
        laststamp = getLastStamp()
        #print(laststamp)
        outfile = open(STATICFILE, 'w+')
        outfile.write(laststamp)
        outfile.close()


    elif sys.argv[1] == 'readfrom':
        outfile = open(STATICFILE, 'r')
        startStamp = outfile.readline()
        outfile.close()
        outfile = open(STATICFILE, 'w')
        #startStamp = sys.argv[2]
        StartConsolidating = False
        laststamp = getLastStamp()
        outfile.write(laststamp)
        outfile.close()
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
    #writeout = csv.writer(outfile, quoting=csv.QUOTE_ALL)
    writeout = csv.writer(outfile)
    Header = Counters.copy()
    Header.insert(0, 'TimeStamp')
    #writeout.writerow(Header)

    OutDat = []
    OutDat.insert(0, str(TimeStamp))
    MaxRSS = 0
    for item in Counters:
        if item == 'SwapEntries':
            continue
        MaxRSS += int(OutDict[item])
        #OutDat.append(str(OutDict[item]))
    OutDat.append(str(MaxRSS))
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
