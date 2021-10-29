#! /usr/bin/env python


from zplot import *
import os, mmap
from datetime import datetime
import itertools
import re


one_dat_file = "nopred_nobg_v_bg_oneanalysis.csv"
folder_in = "/Users/shaleen/Research/NVM/HPC-OUTPUT/strided_MADbench/"
folder_out = "/Users/shaleen/Research/NVM/HPC-OUTPUT/strided_MADbench/zplotout1/"


#change if the csv format changes
column_legend = {
    "PROC" : "c0",
    "LOAD" : "c1",
    "READSIZE" : "c2",
    "TIMESPFETCH" : "c3"
}

DELIM = ","
NODAT = "-"
##From Filename
variants = ["PROC", "LOAD", "READSIZE", "TIMESPFETCH"] ##multiple
data = ["Elapsed", "READAHEAD_TIME"] ##multiple

identifier_0 = "nopred_"
identifier_1 = "nobg_"
identifier_2 = "bg_"

out_invariants = ["LOAD", "READSIZE", "TIMESPFETCH"]
xaxis = "PROC"
y1axis = "Elapsed"
y2axis = "READAHEAD_TIME"


WORKLOADS = ["strided_MADbench"]
PROC = [1, 4, 16]
LOAD = [4096, 8192, 16384]
READSIZE = [4096, 131072, 524288, 1048576, 4194304, 16777216]
TIMESPFETCH = [1, 2, 4]


def get_outfilename(para_dict, postfix=".eps"):
    invariants = get_invariants(para_dict)
    filename = para_dict["workload"]+"_" + invariants + postfix
    return filename


##Get the output filename
def get_invariants(para_dict):
    string = ""
    for inv in out_invariants:
        string += inv+"-"+str(para_dict[inv])+"_"
    string = string.rstrip("_")
    return string


def main():
    try:
        os.stat(folder_out)
    except:
        os.mkdir(folder_out)

    tbl = table(folder_in+one_dat_file, separator=',')
    all_variants = []
    for inv in out_invariants:
        all_variants.append(globals()[inv])
    iter_invariants = list(itertools.product(*all_variants))
    para_dict = {}
    for workload in WORKLOADS: 
        para_dict["workload"] = workload
        for tup_inv in iter_invariants: #for each invariant permutation
            query = ""
            for i in range(len(out_invariants)): #populate para_dict
                para_dict[out_invariants[i]] = tup_inv[i]
                #query += str(column_legend[out_invariants[i]])
                query += str(out_invariants[i])
                query += str(' = ')
                query += str(tup_inv[i])
                query += ' and '
            
            query = query.rstrip(' and ')
            print(query)
            this_table = table(table=tbl, where=query)
            #this_table.dump()
            canvas = postscript(folder_out+get_outfilename(para_dict))
            
            max_y = this_table.getmax(column="nopred_Elapsed")
            d = drawable(canvas, xrange=[0,20], yrange=[0,max_y])

            axis(d, xtitle='Cores', xauto=[0,16,4], ytitle='time(sec)', yauto=[0,max_y,max_y/10],
                xlabelfontsize=10, ylabelfontsize=3)
            p = plotter()
            L = legend()
            p.line(d, this_table, xfield='PROC', yfield='nopred_Elapsed', linewidth=1,
                linecolor='1,0,0', legend=L, legendtext='No user-lvl prefetch')

            p.line(d, this_table, xfield='PROC', yfield='bg_Elapsed', linewidth=1,
                linecolor='0,1,0', legend=L, legendtext='background prefetch')

            p.line(d, this_table, xfield='PROC', yfield='nobg_Elapsed', linewidth=1,
                linecolor='0,0,1', legend=L, legendtext='foreground prefetch')

            L.draw(canvas, coord=[d.right()-50, d.top()], fontsize=5)

            canvas.render()
            #break





##main
if __name__ == "__main__":
    main()