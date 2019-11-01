#! /usr/bin/env python

import sys
from zplot import *
import sys, getopt

inputfile = ''
outputfile = ''
ymax=600
yint=200
xfield='ops'
xlegend='DevFS techniques'
bwidth = 0.9
lwidth = 0.3
xfontsize=9.0
yfontsize=9.0
xlabelsize=9.0
xydim=[200, 170]
xystart=[100,100]
xylegend=[50,160]
xycord = [50,30]
xmanualarr = []
xmanualstart=2.5
xmanualint=6

#graphname='m-all-sensitivity-CAP'
graphname='e-rocks-sensitivity-BW'

xname="Bandwidth Relative to Fast Memory"
#xname="Capacity Relative to All Fast Memory"

CONFIG = ['BW500', 'BW1000', 'BW2000', 'BW4000']
#CONFIG = ['CAP2048', 'CAP4096', 'CAP8192', 'CAP10240']

mechnames = ['All-SlowMem', 'Naive', 'Migration-only', 'Hetero-Context', 'All-FastMem']
mech = ['slowmem-only', 'naive-os-fastmem', 'slowmem-migration-only',  'slowmem-obj-affinity-prefetch', 'optimal-os-fastmem']


xlabel = ["1/16", "1/8", "1/4", "1/2"]
storage=["NVM"]
pattern = ["NVM", "NVM", "NVM", "NVM", "NVM"]

colors=['white', 'lightgrey', 'darkgray', 'black', 'red', 'blue']
path='/users/skannan/ssd/NVM/graphs/zplot/data/result-sensitivity/'
APPS="rocksdb"
yname="Throughput (10K Ops/sec)"

dseq = []
L=legend()
p = plotter()

c = canvas('pdf', title=graphname, dimensions=xydim)
d = drawable(canvas=c, xrange=[0,16], yrange=[0,ymax], coord=xycord, dimensions=xystart)

for j in range(0, len(CONFIG)):

    xmanualarr.append((xlabel[j],xmanualstart))
    xmanualstart = xmanualstart + xmanualint

    for i in range(0, len(mech)):
	filepath=path + APPS + '-' +  mech[i] + "-" + pattern[i] + "-" + CONFIG[j] + '.data'
	print filepath + "************"
        dseq.append(table(file=filepath))


s=0
legendflag=0
print  xmanualarr

for k in range(0, len(CONFIG)):

    for j in range(0, len(mech)):

        if( s % (len(mech)) == len(mech)-1):

	    style='star'
            color='green'	

	    p.line(drawable=d, table=dseq[s], xfield='c0', yfield='c1', linecolor=color, linewidth=0.5)	

	    if( legendflag == 0):
	    	p.points(drawable=d, table=dseq[s], xfield='c0', yfield='c1', linecolor=color,
        	         linewidth=0.5, style=style, legend=L, legendtext=mechnames[j], fill=True, size=8)
		legendflag = 1
	    else:
	    	p.points(drawable=d, table=dseq[s], xfield='c0', yfield='c1', linecolor=color,
        	         linewidth=0.5, style=style, fill=True, size=8)


	elif(s > len(mech)-1):
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
     linewidth=lwidth, xlabelfontsize=xfontsize, xlabelshift=[0,0], ytitleshift = [-5,0], 
     xtitle=xname, ytitle=yname,
     ytitlesize=yfontsize)

L.draw(canvas=c, coord=xylegend, skipnext=6, skipspace=50)

c.render()
