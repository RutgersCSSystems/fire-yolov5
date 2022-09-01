#! /usr/bin/env python

from zplot import *


#change the parameters here

color=['dimgray', 'darkorange', 'dimgray', 'black', 'bisque', 'red', 'green']

legends=['VanillaRA', 'VanillaOPT', 'OSonly', 'CrossInfo', 'CII']
legendtext=['VanillaRA', 'VanillaRA_OPT', 'OSonly', 'Cross-Info', 'Cross-Info-IOOPT']

filestyle=['hline', 'solid', 'dline1', 'dline2', 'dline1', 'solid', 'solid']

clusterlen=len(legendtext)

output='SIMPLE_BENCH.data' if len(sys.argv) < 2 else sys.argv[1]
graptitle='SIMPLE_BENCH' if len(sys.argv) < 2 else sys.argv[2]


ymax=4500
yinterval=1000

# Font Sizes
XTSIZE=4
YTSIZE=4

ctype = 'eps' if len(sys.argv) < 2 else sys.argv[1]
#c = pdf('figure1.pdf')
c = canvas('pdf', title=graptitle, dimensions=[130, 90])
t = table(file=output)

d = drawable(canvas=c, coord=[25,18], xrange=[-0.5,t.getmax('rownumber')+0.5], yrange=[0, ymax], dimensions=[100, 70])

# because tics and axes are different, call axis() twice, once to
# specify x-axis, the other to specify y-axis
axis(d, linewidth=0.5, xtitle='Threads',
        xtitlesize=XTSIZE, xmanual=t.query(select='reader,rownumber'), xlabelfontsize=3, ytitle='Throughput (MB/sec)',
        ytitlesize=YTSIZE, ylabelfontsize=5, yauto=[0,ymax,yinterval], ticmajorsize=2, xlabelshift=[0,1], ylabelshift=[-1,0], xtitleshift=[0,3])


p = plotter()
L = legend()

barargs = {'drawable':d, 'table':t, 'xfield':'rownumber',
           'linewidth':0.3, 'fill':True, 'barwidth':0.7,
		   'legend':L, 'stackfields':[]}

i=0;

for x in range(0, len(legendtext)):
    barargs['yfield'] = legends[i]
    barargs['legendtext'] = legendtext[i]
    barargs['fillcolor'] = color[i]
    barargs['fillstyle'] = filestyle[i]
    barargs['fillsize'] = '0.5'
    barargs['fillskip'] = '0.5'
    barargs['cluster'] = [i,clusterlen+1]
    p.verticalbars(**barargs)
    i=i+1;

L.draw(c, coord=[d.left()+10, d.top()-10], width=3, height=3, fontsize=3, hspace=1, skipnext=2, skipspace=25)

c.render()
exit()
