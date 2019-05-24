#! /usr/bin/env python

import sys
from zplot import *
import sys, getopt

inputfile = ''
outputfile = ''
ymax=2500000
yint=500000
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


d1 = table(file='data/e-rocksdb-naive.data')
d2 = table(file='data/e-rocksdb-migrateonly.data')

app = ["RocksDB","filebench","Redis"]

c = canvas('pdf', title='e-rocksdb', dimensions=xydim)
d = drawable(canvas=c, xrange=[0,16], yrange=[0,ymax], coord=xycord,
             dimensions=xystart)

L=legend()

p = plotter()
p.verticalbars(drawable=d, table=d1, xfield='c0', yfield='c1', fill=True,
               fillcolor='white', barwidth=0.9, linewidth=0.5, yloval=0,
               legend=L, legendtext='Naive OS Use')
p.verticalbars(drawable=d, table=d2, xfield='c0', yfield='c1', fill=True,
               fillcolor='lightgrey', barwidth=0.9, linewidth=0.5, yloval=0,
               legend=L, legendtext='OS Migration Use')
#p.verticalbars(drawable=d, table=d3, xfield='c0', yfield='c1', fill=True,
#               fillcolor='darkgray', barwidth=0.9, linewidth=0.5, yloval=0,
#               legend=L, legendtext='AppSlowMem-OSFastMem')
#p.verticalbars(drawable=d, table=d3, xfield='c0', yfield='c1', fill=True,
#               fillcolor='black', barwidth=0.9, linewidth=0.5, yloval=0,
#               legend=L, legendtext='DevFS [+cap +direct]')

# a bit of a hack to get around that we don't support date fields (yet)
axis(drawable=d, style='xy', xmanual=[[app[0],2.5],[app[1],7.5],[app[2],12.5]],
     #ymanual=[['0',0],['2',2],['4', 4],['6', 6],['8', 8]],
     yauto=[0,ymax,yint],
     linewidth=0.5, xlabelfontsize=xfontsize, xlabelshift=[0,0], ytitleshift = [-2,-10], 
     xtitle='Application', ytitle='Slowdown factor (AppFastMem-OSFastMem)',
     ytitlesize=yfontsize)

L.draw(canvas=c, coord=xylegend, skipnext=4, skipspace=50)

c.render()




