#!/usr/bin/env python3.6
##This script runs the Given program BTIO with different conditions

import csv
import json
import sys
import os
import re
import subprocess
from subprocess import STDOUT, check_call

REDO_TIMES=5

RatioStart=1.5 ##Start of loop
Step=0.5     ##Step size
RatioEnd=1.5 ##End of for loop
NPROC=38 ##Number of processes to create for this workload
PATH="/users/shaleen/ssd/Crosslayer/ECP-proxy/NPB3.4/NPB3.4-MPI"
WORKLOAD='bt'
LOADCLASS='C'

PROGRAM='bt'

ProgMem=74828 * 36 * 1024  ##This is the PCAnon 1


#Elapsed, User, Kernel, CPU, MAXRSS, MajorPageFaults, MinorPageFaults, Vol-ContextSwitches, InVol-ContextSwitches, ExitStat, PagesReclaimed

###########
usertime = 'User time (seconds)'
kerneltime = 'System time (seconds)'
wallclock = ''
###########

TimeReturns = ['Elapsed', 'Usertime', 'Kerneltime', 'CPU', 'MAXRSS', 'MajorPageFaults', \
        'MinorPageFaults', 'Vol-ContextSwitches', 'InVol-ContextSwitches', 'ExitStat']

#runs the program with /usr/bin/time
def TimeRun():
    cgexec = ' sudo cgexec -g memory:npb '
    #Elapsed, User, Kernel, CPU, MAXRSS, MajorPageFaults, MinorPageFaults, Vol-ContextSwitches, 
    #InVol-ContextSwitches, ExitStat
    time = ' /usr/bin/time -f \"%e, %U, %S, %P, %M, %F, %R, %w, %c, %x\" '
    mpi = ' mpirun -NP '
    workload_command = PATH+"/bin/"+WORKLOAD+"."+LOADCLASS+".x.ep_io"
    Command = time + cgexec + mpi + str(NPROC) + " " + workload_command
    print(Command)
    run = BashExec(Command)

    RetDict = {} ##Contains the data from this run in the form of dict

    for line in run.stderr: ##Run through the stderr for the end line to get time return
        pass
    line = line.rstrip("\n").split(',') ##Split the lines with ','

    if len(TimeReturns) != len(line): ##Check if the intended contents are == what we get from time
        print("ERROR: TimeReturns != time output in TimeRun()")
        return {}

    for i in range(len(line)): ##Populate the RetDict
        RetDict[TimeReturns[i]] = line[i].strip(' ')

    return RetDict



def main():
    BashExec('sudo cgcreate -g memory:npb')
    JsonDat = []
    for PCRatio in [1, 1.5, 2, 2.5, 3, 3.5]:
        print('Running PCAnonRatio = ', PCRatio)
        run = subprocess.Popen(['echo ' + str(ProgMem*PCRatio) + ' | sudo tee /sys/fs/cgroup/memory/npb/memory.limit_in_bytes'], \
                shell=True, stdout=subprocess.PIPE, universal_newlines=True, stderr=subprocess.PIPE, bufsize=0)

        for Ratios in [[1,100], [10, 20], [50,50], [100, 10], [100,1]]:
            PCDat = {}
            print (Ratios[0], Ratios[1])
            DBR=Ratios[0] ##DirtyBackgroundRatio
            DR=Ratios[1]  ##DirtyRatio
            BashExec('sudo echo ' + str(DBR) + ' > /proc/sys/vm/dirty_background_ratio')
            BashExec('sudo echo ' + str(DR) + ' > /proc/sys/vm/dirty_ratio')
            
            PCDat['PCRatio'] = str(PCRatio)
            PCDat['DirtyBgRatio'] =  str(DBR)
            PCDat['DirtyRatio'] =  str(DR)
            PCDat['Nproc'] = str(NPROC)

            EachRun = []
            for Redo in range(0, REDO_TIMES):
                print ("Running Time = ", Redo)
                thisrun = TimeRun()
                print(thisrun)
                EachRun.insert(Redo, thisrun)
                BashExec('rm -rf btio*')
                ##Get the data for this run

            PCDat['Run'] = EachRun
            JsonDat.append(PCDat)

    print(JsonDat)
    #json_data = json.dumps(JsonDat)
    with open('bt_C_allknobs.json', 'w+') as outfile:
        json.dump(JsonDat, outfile)


###################################################################
def BashExec(Command):
    run = subprocess.Popen([Command], shell=True, stdout=subprocess.PIPE, \
            universal_newlines=True, stderr=subprocess.PIPE, bufsize=0)
    return run
###################################################################

if __name__ == "__main__":
    main()
