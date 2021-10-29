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
bwidth = 0.9
lwidth = 0.3
xfontsize=9.0
yfontsize=9.0
xlabelsize=10.0
xydim=[220, 150]
xystart=[120, 130]
xylegend=[50,140]
xycord = [45,20]
xlabel = ['RandWr', 'RandRd', 'SeqWr', 'SeqRd']
pattern = ['fillrandom', 'readrandom', 'fillseq', 'readseq']
xmanualstart=1.5
xmanualint=4
lablsize=6
xrangesz=12


#mech = ['optimal-os-fastmem', 'slowmem-migration-only',
#        'slowmem-obj-affinity', 'slowmem-obj-affinity-prefetch', 'slowmem-only']
#mechnames = ['Optimal', 'Migration-only', 'Obj-affinity',
#        'Obj-affinity-prefetch', 'SlowMem-only']

mech = ['slowmem-obj-affinity-noprefetch', 'slowmem-obj-affinity-prefetch']
mechnames = ['Hetero-Context', 'Hetero-Context-Prefetch']

colors=['white', 'lightgrey', 'darkgray', 'black', 'red', 'blue']
path='/users/skannan/ssd/NVM/graphs/zplot/data/patern/rocksdb'
yname="Throughput (OPS/sec)"
storage="NVM"

dseq = []
L=legend()
p = plotter()
xmanualarr = []

c = canvas('pdf', title='e-rocksdb-breakdown', dimensions=xydim)
d = drawable(canvas=c, xrange=[0,xrangesz], yrange=[0,ymax], coord=xycord, dimensions=xystart)

for j in range(0, len(pattern)):
    for i in range(0, len(mech)):
	print path+'-'+mech[i]+'-'+ storage + "-" + pattern[j]+'.data'
        dseq.append(table(file=path+'-'+mech[i]+'-'+ storage + "-" + pattern[j]+'.data'))

s=0

for k in range(0, len(pattern)):

    xmanualarr.append((xlabel[k],xmanualstart))
    xmanualstart = xmanualstart + xmanualint

    for j in range(0, len(mech)):
        if(s >= len(mech)):
	    print mech[j]
            p.verticalbars(drawable=d, table=dseq[s], xfield='c0', yfield='c1', fill=True,
                   fillcolor=colors[j], barwidth=bwidth, linewidth=lwidth, yloval=0, labelfield='c1', labelsize=lablsize)
        else:
           p.verticalbars(drawable=d, table=dseq[s], xfield='c0', yfield='c1', fill=True,
                   fillcolor=colors[j], barwidth=bwidth, linewidth=lwidth, yloval=0,
                   legend=L, legendtext=mechnames[j], fillskip=4, labelfield='c1', labelsize=lablsize)
        s=s+1

# a bit of a hack to get around that we don't support date fields (yet)
axis(drawable=d, style='xy',
     xmanual=xmanualarr,
     yauto=[0,ymax, yint],
     linewidth=lwidth, xlabelfontsize=xfontsize, xlabelshift=[0,0], ytitleshift = [-2,-10], 
     xtitle='Application', ytitle=yname,
     ytitlesize=yfontsize)

L.draw(canvas=c, coord=xylegend, skipnext=6, skipspace=50)

c.render()




