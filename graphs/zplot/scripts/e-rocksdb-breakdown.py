#! /usr/bin/env python

import sys
from zplot import *
import sys, getopt

inputfile = ''
outputfile = ''
ymax=1200
yint=200
xfield='ops'
xlegend='DevFS techniques'
bwidth = 0.9
lwidth = 0.3
xfontsize=10.0
yfontsize=9.0
xlabelsize=10.0
xydim=[300, 200]
xystart=[150,100]
xylegend=[50,160]
xycord = [45,20]
xlabel = ['writerand', 'readrand', 'writerseq', 'readseq']
pattern = ['fillrandom', 'readrandom', 'fillseq', 'readseq']
mech = ['naive-os-fastmem', 'optimal-os-fastmem', 'slowmem-migration-only',
        'slowmem-obj-affinity', 'slowmem-obj-affinity-prefetch']
mechnames = ['Naive', 'Optimal', 'Migration-only', 'Obj-affinity',
        'Obj-affinity-prefetch']
colors=['white', 'lightgrey', 'darkgray', 'black', 'red']
path='/users/skannan/ssd/NVM/graphs/zplot/data/patern/rocksdb'
yname="Throughput (OPS/sec)"
storage="SSD"

dseq = []
L=legend()
p = plotter()
xmanualarr = []
xmanualstart=2.5
xmanualint=5

c = canvas('pdf', title='e-rocksdb-breakdown', dimensions=xydim)
#d = drawable(canvas=c, xrange=[0,16], yrange=[0,ymax], coord=xycord,
 #            dimensions=xystart)
d = drawable(canvas=c, xrange=[0,16], yrange=[0,ymax], coord=xycord, dimensions=xystart)

for j in range(0, len(pattern)):
    for i in range(0, len(mech)):
        dseq.append(table(file=path+'-'+mech[i]+'-'+ storage + "-" + pattern[j]+'.data'))

s=0

for k in range(0, len(pattern)):
    for j in range(0, len(mech)):
        if(s >= len(mech)):
            p.verticalbars(drawable=d, table=dseq[s], xfield='c0', yfield='c1', fill=True,
                   fillcolor=colors[j], barwidth=bwidth, linewidth=lwidth, yloval=0)
	    #p.verticalbars(drawable=d, table=dseq[s], xfield='c0', yfield='c1', barwidth=0.8, fillcolor='lightgrey', linewidth=0, fill=True)
        else:
           p.verticalbars(drawable=d, table=dseq[s], xfield='c0', yfield='c1', fill=True,
                   fillcolor=colors[j], barwidth=bwidth, linewidth=lwidth, yloval=0,
                   legend=L, legendtext=mechnames[j], fillskip=4)
	    #p.verticalbars(drawable=d, table=dseq[s], xfield='c0', yfield='c1', barwidth=0.8, fillcolor='lightgrey', linewidth=0, fill=True)
        s=s+1

# a bit of a hack to get around that we don't support date fields (yet)
axis(drawable=d, style='xy',
     xmanual=[[xlabel[0],0.5],[xlabel[1],7.5],[xlabel[2],13.5],[xlabel[3],21.5]],
     yauto=[0,ymax, yint],
     linewidth=lwidth, xlabelfontsize=xfontsize, xlabelshift=[0,0], ytitleshift = [-2,-10], 
     xtitle='Application', ytitle=yname,
     ytitlesize=yfontsize)

L.draw(canvas=c, coord=xylegend, skipnext=6, skipspace=50)

c.render()




