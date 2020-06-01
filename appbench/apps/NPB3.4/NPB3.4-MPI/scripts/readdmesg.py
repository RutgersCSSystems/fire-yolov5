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



def main():
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Try: ./readdmesg.py (init), or (readfrom messageID)")

    if sys.argv[1] == 'init':
        out = BashExec('dmesg | tail -1 | awk \'{print $1}\'')
        for line in out.stdout:
            print(line.strip('\n'))

    elif sys.argv[1] == 'readfrom':
        startStamp = sys.argv[2]
        StartConsolidating = False
        out = BashExec('dmesg')

        for line in out.stdout:
            if line.split(' ')[0] == startStamp:
                StartConsolidating = True
            if(StartConsolidating == True):
                ##Add Consolidating logic
                print(line)



###################################################################
def BashExec(Command):
    run = subprocess.Popen([Command], shell=True, stdout=subprocess.PIPE, \
            universal_newlines=True, stderr=subprocess.PIPE, bufsize=0)
    return run
###################################################################



if __name__ == "__main__":
    main()
