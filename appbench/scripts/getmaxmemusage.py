#!/usr/bin/env python3.6


#this program takes file with free -m spits and prints out max memusage

import csv
import json
import sys
import os
import re
import subprocess
from subprocess import STDOUT, check_call


AnonField=2
SharedField=4
PCField=5

def RepresentsInt(s):
    try:
        int(s)
        return True
    except ValueError:
        return False



def main():
    if len(sys.argv) != 2:
        print("Try: ./getmaxmemusage.py filename")
        sys.exit()

    firsttime = True
    infile = open(sys.argv[1], 'r')
    InitAnon = 0
    InitShared = 0
    InitPC = 0
    #########
    MaxRSS = 0
    MaxAnon = 0
    MaxShared = 0
    MaxPC = 0

    for line in infile.readlines():
        split = line.split()
        if firsttime == True:
            if RepresentsInt(split[AnonField]):
                InitAnon = int(split[AnonField])
            if RepresentsInt(split[SharedField]):
                InitShared = int(split[SharedField])
            if RepresentsInt(split[PCField]):
                InitPC = int(split[PCField])

            if InitAnon != 0 and InitShared != 0 and InitPC != 0:
                firsttime = False
                print("InitAnon:" + str(InitAnon))
                print("InitShared:" + str(InitShared))
                print("InitPC:" + str(InitPC))
        else:
            Anon = 0
            Shared = 0
            PC = 0
            if RepresentsInt(split[AnonField]):
                Anon = int(split[AnonField]) - InitAnon
            if RepresentsInt(split[SharedField]):
                Shared = int(split[SharedField]) - InitShared
            if RepresentsInt(split[PCField]):
                PC = int(split[PCField]) - InitPC

            if MaxRSS < (Anon + Shared + PC):
                MaxRSS = Anon + Shared + PC
                MaxAnon = Anon
                MaxShared = Shared
                MaxPC = PC

    print("MaxRSS: " + str(MaxRSS) + " Anon:" + str(MaxAnon) + " PC:" + str(MaxPC) + " Shared:" + str(MaxShared))



if __name__ == "__main__":
    main()
