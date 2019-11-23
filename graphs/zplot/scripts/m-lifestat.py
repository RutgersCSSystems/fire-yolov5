#! /usr/bin/env python

import sys
from zplot import *
import sys, getopt

inputfile = ''
outputfile = ''
ymax=800
yint=100
xfield='ops'
xlegend='DevFS techniques'
bwidth = 0.9
lwidth = 0.3
xydim=[210, 115]
xystart=[100,80]
xylegend=[60,95]
xycord = [45,30]
xmanualarr = []
xmanualstart=1.5
xmanualint=5

xfontsize=9.0
yfontsize=9.0
xlabelsize=9.0



mech = ['CACHE-PAGE-LIFE', 'BUFF-PAGE-LIFE']
mechnames = ['cache', 'kernbuff']
#storage=["SSD", "NVM"]
#pattern = "NVM"
#APPS = ["filebench", "redis", "rocksdb", "cassandra", "spark"]
#xlabel = ["filebench", "redis", "rocksdb", "cassandra", "spark-bench"]

APPS = ["filebench", "redis", "rocksdb",  "    cassandra"]
xlabel = ["filebench", "redis", "rocksdb", "cassandra"]

titletxt='m-allapps-lifetimestat'


colors=['white', 'lightgrey', 'black', 'black', 'blue', 'red']
path='/users/skannan/ssd/NVM/graphs/zplot/data/lifestat/'
yname="Pages (in 100K)"

dseq = []
L=legend()
p = plotter()

c = canvas('pdf', title=titletxt, dimensions=xydim)
d = drawable(canvas=c, xrange=[0,16], yrange=[0,ymax], coord=xycord, dimensions=xystart)

for j in range(0, len(xlabel)):

    xmanualarr.append((APPS[j],xmanualstart))
    xmanualstart = xmanualstart + xmanualint

    for i in range(0, len(mech)):
	print path + xlabel[j] + "-lifetime-stats-" + mech[i]+ '.data'
        dseq.append(table(file=path + xlabel[j] + "-lifetime-stats-" + mech[i] + '.data'))


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
     linewidth=lwidth, xlabelfontsize=xfontsize, xlabelshift=[0,0], ytitleshift = [-5,-10], 
     xtitle='Application', ytitle=yname, xtitleshift = [-10,0],
     ytitlesize=yfontsize, xtitlesize=xfontsize)


L.draw(canvas=c, coord=xylegend, skipnext=6, skipspace=95, fontsize=yfontsize)
c.render()
