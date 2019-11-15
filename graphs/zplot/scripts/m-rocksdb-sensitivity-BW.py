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
bwidth = 0.6
lwidth = 0.3
xfontsize=9.0
yfontsize=9.0
xlabelsize=9.0
xydim=[270, 140]
xystart=[80,100]
xylegend=[60,135]
xycord = [50,45]
xmanualarr = []
xmanualstart=2.5
xmanualint=5
skipnextval=2
skipspaceval=100
xname= "                             RocksDB                           Spark"
canvascordx=140
canvascordy=5
ytitleshiftx=0
ytitleshifty=-10

EXT=str(sys.argv[1])

graphname='m-rocks-sensitivity-' + EXT

print graphname

if (EXT == "BW"):
	CONFIG = ['BW500', 'BW1000', 'BW2000', 'BW4000']
else:
	CONFIG = ['CAP2048', 'CAP4096', 'CAP8192', 'CAP10240']


mechnames = ['App Slow + OS Slow', 'App Fast + OS Fast', 'App Fast + OS Slow', 'App Slow + OS Fast']
mech = ['APPSLOW-OSSLOW', 'APPFAST-OSFAST', 'APPFAST-OSSLOW', 'APPSLOW-OSFAST']
xlabel = ["1/16", "1/8", "1/4", "1/2"]
storage=["NVM"]
pattern = ["NVM", "NVM", "NVM", "NVM", "NVM"]

colors=['white', 'lightgrey', 'darkgray', 'black', 'red', 'blue']
path='/users/skannan/ssd/NVM/graphs/zplot/data/motivate/'
#APPS="rocksdb"
apps=["rocksdb", "spark-bench"]
yname="Throughput (10K Ops/sec)"

dseq = []
L=legend()
p = plotter()

c = canvas('pdf', title=graphname, dimensions=xydim)

if (EXT == "BW"):
	c.text(text="Slow Memory Bandwidth Relative to Fast Memory", coord=[canvascordx,canvascordy])
else:
	c.text(text="Fast and Slow Memory Capacity Ratio", coord=[canvascordx,canvascordy])

d = drawable(canvas=c, xrange=[0,16], yrange=[0,ymax], coord=xycord, dimensions=xystart)


for k in range(0, len(apps)):

	for j in range(0, len(CONFIG)):

	    xmanualarr.append((xlabel[j],xmanualstart))
	    xmanualstart = xmanualstart + xmanualint

	    for i in range(0, len(mech)):
		filepath=path + apps[k] + '-' +  mech[i] + "-" + pattern[i] + "-" + CONFIG[j] + '.data'
		print filepath + "************"
	        dseq.append(table(file=filepath))

	xmanualstart = xmanualstart + 2

s=0
legendflag=0
print  xmanualarr

for n in range(0, len(apps)):

	for k in range(0, len(CONFIG)):

	    for j in range(0, len(mech)):

		if(s > len(mech)-1):
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
     linewidth=lwidth, xlabelfontsize=xfontsize, xlabelshift=[0,0], ytitleshift = [ytitleshiftx,ytitleshifty], xtitleshift = [15,0],
     xtitle=xname, ytitle=yname,
     ytitlesize=yfontsize, xtitlesize=xfontsize)

L.draw(canvas=c, coord=xylegend, skipnext=skipnextval, skipspace=skipspaceval, fontsize=9.0)

c.render()
