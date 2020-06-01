#!/usr/bin/env python3.6
##This script runs the Given program BTIO with different conditions

import csv
import sys
import os
import re
import subprocess
from subprocess import STDOUT, check_call

REDO_TIMES=3
PATH="/users/shaleen/ssd/Crosslayer/ECP-proxy/NPB3.4/NPB3.4-MPI"
WORKLOAD="bt"
LOADCLASS="C"
#BASE_MEM=56260 * 40 * 1024 ##Original BTIO "C"
BASE_MEM=74828 * 36 * 1024 ##Original BTIO "C"
MEMRATIOSTART=1
MEMRATIOEND=4.5
STEP=0.5
NPROC=36
FILE=""
PERF=0 ##0->NOPERF, 1->vtune, 2->perf

########VTUNE#############
AMPLXE_COMMAND=" amplxe-cl "
CONFIG_AMPLXE=" -trace-mpi -collect hotspots -data-limit=5000 -k enable-stack-collection=true -k sampling-mode=hw "
VTUNERESFOLDER="/users/shaleen/ssd/Crosslayer/ECP-proxy/NPB3.4/NPB3.4-MPI/vtune-analysis" ##saves vtune output data
#####perf################
PERF_COMMAND=" perf " 
CONFIG_PERF= " record --call-graph dwarf -e cpu-cycles:uk,instructions:uk --vmlinux=/lib/modules/4.17.0/build/vmlinux "
PERFRESFOLDER="/users/shaleen/ssd/Crosslayer/ECP-proxy/NPB3.4/NPB3.4-MPI/perf-analysis" ##saves perf output data


##############################################################################
##Installs prereqs
def InstallPrereq():
    check_call(['sudo', 'apt-get', 'install', '-y', 'libcgroup1', 
        'cgroup-tools'], stdout=open(os.devnull,'wb'), stderr=STDOUT) 
##############################################################################

#def CompileBTIO():
#    check_call(['make', 'bt', 'CLASS=C', 'SUBTYPE=btio'], stdout=STDOUT, stderr=STDOUT) 

##############################################################################
#ElapsedTime %e, UserTime %U, KernelTime %S, %CPU-Usage %P, MAX_RSS %M, MajorPageFaults %F, 
#MinorPageFaults %R, Vol-ContextSwitches %w, InVol-ContextSwitches %c, ExitStat %x
def GetCommand(Perf, NumPages, perfstore_location=''):
    Command = ''
    Preload = ' LD_PRELOAD=/usr/lib/pre.so '
    cgexec = ' cgexec -g memory:npb '
    time = ' /usr/bin/time -f \"%e, %U, %S, %P, %M, %F, %R, %w, %c, %x\" '
    mpi = ' mpirun -NP '
    workload_command = PATH+"/bin/"+WORKLOAD+"."+LOADCLASS+".x.ep_io"

    if Perf == 0: ##Without Perf, using time
        if NumPages >= 0:
            Command = Preload + cgexec + time + mpi + str(NPROC) + " " + workload_command

        if NumPages == 0:
            Command = cgexec + time + mpi + str(NPROC) + " " + workload_command

    if Perf == 1: ##Vtune
        if NumPages >= 0:
            Command = Preload + AMPLXE_COMMAND + CONFIG_AMPLXE + '-r ' + VTUNERESFOLDER + perfstore_location + ' -- ' + cgexec + mpi + str(NPROC) + " " + workload_command

        if NumPages == 0:
            Command = AMPLXE_COMMAND + CONFIG_AMPLXE + '-r ' + VTUNERESFOLDER + perfstore_location + ' -- ' + cgexec + mpi + str(NPROC) + " " + workload_command

    if Perf == 2: ##Perf
        if NumPages >= 0:
            Command = Preload + PERF_COMMAND + CONFIG_PERF + ' -o ' + PERFRESFOLDER + perfstore_location + '.perf' + ' -- ' + cgexec + mpi + str(NPROC) + " " + workload_command

        if NumPages == 0:
            Command = PERF_COMMAND + CONFIG_PERF + ' -o ' + PERFRESFOLDER + perfstore_location + '.perf' + ' -- ' + cgexec + mpi + str(NPROC) + " " + workload_command
    

    return [Command]

'''
    if NumPages == 0:
        return ['cgexec -g memory:npb /usr/bin/time -f \"%e, %U, %S, %P, %M, %F, %R, %w, %c, %x\" mpirun -NP' + " " + str(NPROC) + " " + workload_command]
    elif NumPages >= 0:
        return ['LD_PRELOAD=/usr/lib/pre.so cgexec -g memory:npb /usr/bin/time -f \"%e, %U, %S, %P, %M, %F, %R, %w, %c, %x\" mpirun -NP' + " " + str(NPROC) + " " + workload_command ]
'''
##############################################################################



#RunExperiment Gets one data point with
#BaseMem = Min Mem used by the program
#MemRatio => MemBudget = MemRatio*BaseMem
#NumPages => If Running with Page Reclaimer how many at once?
#TimeGranul => How Many seconds before next reclaimer?
def RunExp(Perf, BaseMem, MemRatio=1, NumPages=0, TimeGranul=1):
    run = subprocess.Popen(['echo ' + str(BaseMem*MemRatio) + ' | sudo tee /sys/fs/cgroup/memory/npb/memory.limit_in_bytes'], \
            shell=True, stdout=subprocess.PIPE, universal_newlines=True, stderr=subprocess.PIPE, bufsize=0)


    if (Perf >= 1): ###VTUNE/PERF - run only once.
        VtuneStoreLoc = '/'+WORKLOAD+'_'+LOADCLASS+'_Pages-'\
                +str(NumPages)+'_Time-'+str(TimeGranul)+'_Ratio-'+str(MemRatio)
        Command = GetCommand(Perf, NumPages, VtuneStoreLoc)
        print(VtuneStoreLoc)
        print(Command)
        run = subprocess.Popen(Command, shell=True, stdout=subprocess.PIPE, universal_newlines=True, stderr=subprocess.PIPE, bufsize=0)
        for line in run.stdout:
            print(line)
        run = subprocess.Popen(['rm -rf btio*'], shell=True, stdout=subprocess.PIPE, universal_newlines=True, stderr=subprocess.PIPE, bufsize=0)
        return []

    PagesReclaimed = 0
    MaxCPU = 0
    MinCPU = 100000
    TotalCPU = 0

    MinElapsedTime = 1000000000
    MaxElapsedTime = 0
    ElapsedTime = 0
    FinalLine = []

    Command = GetCommand(Perf, NumPages, '')
    print(Command)

    for x in range(REDO_TIMES):
        run = subprocess.Popen(Command, shell=True, stdout=subprocess.PIPE, universal_newlines=True, stderr=subprocess.PIPE, bufsize=0)

        for line in run.stdout: ##To Get Destructor Value
            if line.find('Destructor') != -1:
                PagesReclaimed += int(line.split()[1])

        for line in run.stderr: ##TO Get /usr/bin/time data
            pass
        line = line.rstrip("\n").split(',')

        ElapsedTime += float(line[0])
        if MaxElapsedTime < float(line[0]): MaxElapsedTime = float(line[0])
        if MinElapsedTime >= float(line[0]): MinElapsedTime = float(line[0])
        
        TotalCPU += int(line[3].rstrip("%"))
        if MaxCPU <= int(line[3].rstrip("%")): MaxCPU = int(line[3].rstrip("%"))
        if MinCPU >= int(line[3].rstrip("%")): MinCPU = int(line[3].rstrip("%"))
        
        run = subprocess.Popen(['rm -rf btio*'], shell=True, stdout=subprocess.PIPE, universal_newlines=True, stderr=subprocess.PIPE, bufsize=0)
    
    FinalLine = line.copy()
    FinalLine.insert(0, str(MemRatio))
    FinalLine.insert(1, str(MemRatio*BaseMem))
    #FinalLine[5] = str(round(int(FinalLine[5].rstrip("%"))/NPROC, 3))+"%" ##Average CPU%


    FinalLine.insert(5, str(round((MinCPU/NPROC), 3))+"%" ) ##Insert MinCPU%
    FinalLine[6] = str(TotalCPU/(REDO_TIMES*NPROC))+"%" ##Update average CPUUtil
    FinalLine.insert(7, str(round((MaxCPU/NPROC), 3))+"%" ) ##Insert MaxCPU%

    FinalLine.insert(2, str(MinElapsedTime)) ## add the Min Elapsed Time
    FinalLine.insert(4, str(MaxElapsedTime)) ## add the Min Elapsed Time
    FinalLine[3] = str(ElapsedTime/REDO_TIMES) ##Update the average Elapsed Time

    FinalLine.append(str(PagesReclaimed/REDO_TIMES)) ##add Avg PagesReclaimed
    #print(FinalLine)
    return FinalLine

#PCAnonRatio, MemBudget, MinElapsed, Elapsed, MaxElapsed, User, Kernel, LowCPU, CPU, High CPU, MAXRSS, MajorPageFaults, MinorPageFaults, Vol-ContextSwitches, InVol-ContextSwitches, ExitStat, PagesReclaimed


def main():
#    InstallPrereq()
#    CompileBTIO()
    Header = ["#PCAnonRatio", "MemBudget(Bytes)", "Min Elapsed Time (sec)", "Elapsed Time (sec)", "Max Elapsed Time (sec)", "User Time", "Kernel Time", "LowCPU %", "CPU %", "HighCPU %", "MAX_RSS", "MajorPageFaults", "MinorPageFaults", "Vol-ContextSwitches", "InVol-ContextSwitches", "ExitStat", "PagesReclaimed"]
    check_call(['sudo', 'cgcreate', '-g', 'memory:npb'], 
            stdout=open(os.devnull,'wb'), stderr=STDOUT)

    #for NumPages in range(0, 501, 100):
    for NumPages in [0, 1000]:
        os.environ['RECNUMPAGES'] = str(NumPages)

        #for Time in range(10, 150, 40):
        for Time in [5]: ##Time interval of run
            os.environ['RECTIME'] = str(Time)

            FILE = WORKLOAD+"_"+LOADCLASS+"_Page-"+str(NumPages)\
                    +"_Time-"+str(Time)+".csv"
            mf = open(FILE, 'w')
            wr = csv.writer(mf, quoting=csv.QUOTE_ALL)
            wr.writerow(Header)
            for MemRatio in [1, 1.5, 2, 2.5, 3, 3.5]:
                print(NumPages, Time, MemRatio)
                Line = RunExp(PERF, BASE_MEM, MemRatio, NumPages, Time)
                if (Line == [] and PERF >= 1):
                    continue
                print(Line) ##THis is the line to be added to csv
                wr.writerow(Line)
            mf.close()
            if (NumPages == 0):
                break;

if __name__ == "__main__":
    main()
