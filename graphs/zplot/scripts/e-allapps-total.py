#! /usr/bin/env python

import sys
from zplot import *
import sys, getopt

inputfile = ''
outputfile = ''
ymax=600
yint=100
xfield='ops'
xlegend='DevFS techniques'
bwidth = 0.9
lwidth = 0.3
xfontsize=10.0
yfontsize=9.0
xlabelsize=10.0
xydim=[250, 190]
xystart=[100,100]
xylegend=[50,170]
xycord = [40,20]
xmanualarr = []
xmanualstart=2.5
xmanualint=7


mechnames = ['Naive', 'All-FastMem', 'Migration-only', 'Hetero-Context-NoMigrate', 'Hetero-Context', 'All-SlowMem']
#xlabel = ['SET-SSD', 'SET-NVM', 'GET-SSD', 'GET-NVM']
#pattern = ['SSD-SET','NVM-SET', 'SSD-GET', 'NVM-GET']
mech = ['naive-os-fastmem', 'optimal-os-fastmem', 'slowmem-migration-only', 'slowmem-obj-affinity-nomig', 'slowmem-obj-affinity', 'slowmem-only']
storage=["SSD", "NVM"]
pattern = "NVM"
APPS = ["filebench", "redis", "rocksdb", "cassandra"]
xlabel = ["filebench", "redis", "rocksdb", "cassandra"]



colors=['white', 'lightgrey', 'darkgray', 'black', 'red', 'blue']
path='/users/skannan/ssd/NVM/graphs/zplot/data/'
yname="Throughput (MB/sec)"

dseq = []
L=legend()
p = plotter()

c = canvas('pdf', title='e-allapps', dimensions=xydim)
d = drawable(canvas=c, xrange=[0,16], yrange=[0,ymax], coord=xycord, dimensions=xystart)

for j in range(0, len(xlabel)):

    xmanualarr.append((xlabel[j],xmanualstart))
    xmanualstart = xmanualstart + xmanualint

    for i in range(0, len(mech)):
	print path + xlabel[j] + '-'+mech[i]+"-" + pattern +'.data'
        dseq.append(table(file=path + xlabel[j] + '-'+mech[i]+"-" + pattern +'.data'))
	

s=0
print  xmanualarr

for k in range(0, len(APPS)):
    for j in range(0, len(mech)):
        if(s >= len(mech)):
            p.verticalbars(drawable=d, table=dseq[s], xfield='c0', yfield='c1', fill=True,
                   fillcolor=colors[j], barwidth=bwidth, linewidth=lwidth, yloval=0)
        else:
           p.verticalbars(drawable=d, table=dseq[s], xfield='c0', yfield='c1', fill=True,
                   fillcolor=colors[j], barwidth=bwidth, linewidth=lwidth, yloval=0,
                   legend=L, legendtext=mechnames[j], fillskip=4)
        s=s+1

# a bit of a hack to get around that we don't support date fields (yet)
axis(drawable=d, style='xy',
     xmanual=xmanualarr,
     yauto=[0,ymax, yint],
     linewidth=lwidth, xlabelfontsize=xfontsize, xlabelshift=[0,0], ytitleshift = [0,-10], 
     xtitle='Application', ytitle=yname,
     ytitlesize=yfontsize)

L.draw(canvas=c, coord=xylegend, skipnext=6, skipspace=50)

c.render()
