#! /usr/bin/env python

from zplot import *
import os, mmap
from datetime import datetime
import itertools
import re


one_dat_file = "sleep_oneanalysis.csv"
folder_in = "/Users/shaleen/Research/NVM/HPC-OUTPUT/strided_MADbench/"
folder_out = "/Users/shaleen/Research/NVM/HPC-OUTPUT/strided_MADbench/sleep-zplotout/"


DELIM = ","
NODAT = "-"
##From Filename
variants = ["PROC", "LOAD", "READSIZE", "TIMESPFETCH"] ##multiple
data = ["Elapsed", "READAHEAD_TIME"] ##multiple

identifier_0 = "nopred_"
identifier_1 = "sleep_nobg_"
#identifier_2 = "bg_"

out_invariants = ["LOAD", "READSIZE", "TIMESPFETCH"]
xaxis = "PROC"
y1axis = "Elapsed"
y2axis = "READAHEAD_TIME"


WORKLOADS = ["strided_MADbench"]
PROC = [4, 16]
LOAD = [4096, 8192, 16384]
READSIZE = [4096, 131072, 524288, 1048576, 4194304, 16777216]
TIMESPFETCH = [1, 2, 4]


def get_outfilename(para_dict, postfix=".eps"):
    invariants = get_invariants(para_dict)
    filename = para_dict["workload"]+"_" + invariants
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

    tbl = table(file=folder_in+one_dat_file, separator=DELIM)
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
                query += str(out_invariants[i])
                query += str(' = ')
                query += str(tup_inv[i])
                query += ' and '
            query = query.rstrip(' and ')
            print(query)

            this_table = table(table=tbl, where=query)
            #this_table.dump()
            c = canvas('eps', title=folder_out+get_outfilename(para_dict))
                    #dimensions=[215, 68])
            
            max_y = this_table.getmax(column="nopred_Elapsed")
            d = drawable(canvas=c, coord=[15,15], 
                    xrange=[-0.5,this_table.getmax('rownumber')+0.5], 
                    yrange=[0, max_y])#, dimensions=[95, 50])

            axis(drawable=d, linewidth=0.5, xtitle='# of Cores',
	        xtitlesize=5, xmanual=this_table.getaxislabels(column='PROC'), 
                xlabelfontsize=5, ytitle='time(sec)',
	        ytitlesize=5, ylabelfontsize=5, yauto=[0, max_y, max_y/10], 
                ticmajorsize=2, xlabelshift=[0,2], ylabelshift=[2,0], 
                xtitleshift=[0,3])

            p = plotter()
            L = legend()


            barargs = {'drawable':d, 'table':this_table, 'xfield':'rownumber',
                    'linewidth':0, 'fill':True, 'barwidth':0.7,
		    'legend':L}

            barargs['yfield'] = 'nopred_Elapsed'
            barargs['legendtext'] = 'No user-lvl prefetch'
            barargs['fillcolor'] = 'royalblue'
            barargs['fillstyle'] = 'solid'
            barargs['fillsize'] = '0.5'
            barargs['fillskip'] = '0.5'
            barargs['cluster'] = [0, 2]
            p.verticalbars(**barargs)

            #TEMP p.line(d, this_table, xfield='PROC', yfield='bg_Elapsed', linewidth=1,
            #    linecolor='0,1,0', legend=L, legendtext='background prefetch')

            barargs['yfield'] = 'sleep_nobg_Elapsed'
            barargs['legendtext'] = 'sleep foreground prefetch'
            barargs['fillcolor'] = 'darkorange'
            barargs['fillstyle'] = 'solid'
            barargs['fillsize'] = '1'
            barargs['fillskip'] = '1'
            barargs['cluster'] = [1, 2]
            p.verticalbars(**barargs)

            L.draw(c, coord=[d.right()-70, d.top()], fontsize=5)

            c.render()


##main
if __name__ == "__main__":
    main()
