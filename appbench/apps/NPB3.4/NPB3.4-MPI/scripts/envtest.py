
import csv
import sys
import os
import re
import subprocess
from subprocess import STDOUT, check_call


A = os.getenv('RECNUMPAGES')
print(A)
os.environ['RECNUMPAGES'] = '134'
run = subprocess.Popen(['echo $RECNUMPAGES'], shell=True)
A = os.getenv('RECNUMPAGES')
print(A)
