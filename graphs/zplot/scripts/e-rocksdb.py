#! /usr/bin/env python

import sys
from zplot import *
import sys, getopt

inputfile = ''
outputfile = ''
ymax=35000
yint=5000
xfield='ops'
xlegend='DevFS techniques'
barwidth = 0.9
xfontsize=10.0
yfontsize=9.0
xlabelsize=10.0
xydim=[250, 210]
xystart=[220,170]
xylegend=[70,200]
xycord = [60,20]

dlist = []

dlist.append(table(file='data/rocksdb-naive-os-fastmem-NVM.data'))
dlist.append(table(file='data/rocksdb-optimal-os-fastmem-NVM.data'))
dlist.append(table(file='data/rocksdb-slowmem-migration-only-NVM.data'))
dlist.append(table(file='data/rocksdb-slowmem-obj-affinity-NVM.data'))
dlist.append(table(file='data/rocksdb-slowmem-only-NVM.data'))

dlist.append(table(file='data/rocksdb-naive-os-fastmem-SSD.data'))
dlist.append(table(file='data/rocksdb-optimal-os-fastmem-SSD.data'))
dlist.append(table(file='data/rocksdb-slowmem-migration-only-SSD.data'))
dlist.append(table(file='data/rocksdb-slowmem-obj-affinity-SSD.data'))
dlist.append(table(file='data/rocksdb-slowmem-only-SSD.data'))


color=['white', 'lightgrey', 'darkgray', 'black', 'red']
legendtext=['Naive-OS-FastMem', 'All-FastMem', 'Migration-Only', 'Object-Affinity', 'All-SlowMem']

app = ["RocksDB-NVM", "RocksDB-SSD"]

c = canvas('pdf', title='rocksdb', dimensions=xydim)
d = drawable(canvas=c, xrange=[0,16], yrange=[0,ymax], coord=xycord,
             dimensions=xystart)

L=legend()
p = plotter()
i=0
nolegend_idx=5


for x in range(0, len(dlist)):

	if (i >= nolegend_idx):
		p.verticalbars(drawable=d, table=dlist[i], xfield='c0', yfield='c1', fill=True,
		fillcolor=color[i%5], barwidth=0.9, linewidth=0.5, yloval=0)
	else:
		p.verticalbars(drawable=d, table=dlist[i], xfield='c0', yfield='c1', fill=True,
        	fillcolor=color[i%5], barwidth=0.9, linewidth=0.5, yloval=0,
               	legend=L, legendtext=legendtext[i])

	i=i+1;


#p.verticalbars(drawable=d, table=d2, xfield='c0', yfield='c1', fill=True,
#               fillcolor=color[1], barwidth=0.9, linewidth=0.5, yloval=0,
#               legend=L, legendtext=legendtext[1])
#p.verticalbars(drawable=d, table=d3, xfield='c0', yfield='c1', fill=True,
#               fillcolor=color[2], barwidth=0.9, linewidth=0.5, yloval=0,
#               legend=L, legendtext=legendtext[2])
#p.verticalbars(drawable=d, table=d4, xfield='c0', yfield='c1', fill=True,
#               fillcolor=color[3], barwidth=0.9, linewidth=0.5, yloval=0,
#               legend=L, legendtext=legendtext[3])
#p.verticalbars(drawable=d, table=d5, xfield='c0', yfield='c1', fill=True,
#               fillcolor=color[4], barwidth=0.9, linewidth=0.5, yloval=0,
#               legend=L, legendtext=legendtext[4])


# a bit of a hack to get around that we don't support date fields (yet)
axis(drawable=d, style='xy', xmanual=[[app[0],2.5],[app[1],9.5]],
     #ymanual=[['0',0],['2',2],['4', 4],['6', 6],['8', 8]],
     yauto=[0,ymax,yint],
     linewidth=0.5, xlabelfontsize=xfontsize, xlabelshift=[0,0], ytitleshift = [-2,-10], 
     xtitle='Application', ytitle='Throughput (MB/s)',
     ytitlesize=yfontsize)

L.draw(canvas=c, coord=xylegend, skipnext=6, skipspace=50)

c.render()




