#! /usr/bin/env python

import sys
from zplot import *
import sys, getopt

inputfile = ''
outputfile = ''
ymax=2500
yint=500
xfield='ops'
xlegend='DevFS techniques'
bwidth = 0.8
lwidth = 0.3
xfontsize=8.0
yfontsize=8.0
xlabelsize=8.0
xydim=[270, 170]
xystart=[120, 80]
xylegend=[30,160]
xycord = [45,30]
xmanualarr = []
xmanualstart=2.5
xmanualint=7
skipnextval=4
skipspaceval=75

mechnames = ['All-SlowMem', 'All-FastMem', 'Naive', 'Migration-only', 'KLOC-nomigrate', 'KLOC-migrate-fs-noprefetch', 'KLOC-migrate-fs-nw-noprefetch']
xlabel = ['SET', 'GET']
pattern = ['NVM-SET', 'NVM-GET']
mech = ['slowmem-only', 'optimal-os-fastmem', 'naive-os-fastmem','slowmem-migration-only', 'slowmem-obj-affinity-nomig',  'slowmem-obj-affinity', 'slowmem-obj-affinity-net']
storage=["NVM"]
colors=['white', 'lightgrey', 'darkgray', 'black', 'blue', 'red', 'green']
path='/users/skannan/ssd/NVM/graphs/zplot/data/patern/redis'
yname="Throughput (in 100K OPS/sec)"

dseq = []
L=legend()
p = plotter()

c = canvas('pdf', title='e-redis-breakdown', dimensions=xydim)
d = drawable(canvas=c, xrange=[0,10], yrange=[0,ymax], coord=xycord, dimensions=xystart)

for j in range(0, len(xlabel)):

    xmanualarr.append((xlabel[j],xmanualstart))
    xmanualstart = xmanualstart + xmanualint

    for i in range(0, len(mech)):
	print path+'-'+mech[i]+"-" + pattern[j]+'.data'
        dseq.append(table(file=path+'-'+mech[i] + "-" + pattern[j]+'.data'))
	

s=0
print  xmanualarr

for k in range(0, len(pattern)):
    for j in range(0, len(mech)):
        if(s >= len(mech)):
            p.verticalbars(drawable=d, table=dseq[s], xfield='c0', yfield='c1', fill=True,
                   fillcolor=colors[j], barwidth=bwidth, linewidth=lwidth, yloval=0, labelfield='c1', labelsize=7)
        else:
           p.verticalbars(drawable=d, table=dseq[s], xfield='c0', yfield='c1', fill=True,
                   fillcolor=colors[j], barwidth=bwidth, linewidth=lwidth, yloval=0,
                   legend=L, legendtext=mechnames[j], fillskip=4, labelfield='c1', labelsize=7)
        s=s+1

# a bit of a hack to get around that we don't support date fields (yet)
axis(drawable=d, style='xy',
     xmanual=xmanualarr,
     yauto=[0,ymax, yint],
     linewidth=lwidth, xlabelfontsize=xfontsize, xlabelshift=[0,0], ytitleshift = [-2,0], 
     xtitle='Operation Type', ytitle=yname,
     ytitlesize=yfontsize)

L.draw(canvas=c, coord=xylegend, skipnext=skipnextval, skipspace=skipspaceval, width=8, height=8)

c.render()
