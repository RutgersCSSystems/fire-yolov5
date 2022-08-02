#! /usr/bin/env python

from zplot import *

ctype = 'eps' if len(sys.argv) < 2 else sys.argv[1]
#c = pdf('figure1.pdf')
c = canvas('pdf', title='rocksdb', dimensions=[130, 80])
t = table(file='rocksdb.data')

d = drawable(canvas=c, coord=[22,15], xrange=[-0.5,t.getmax('rownumber')+0.5], yrange=[0, 2000000], dimensions=[110, 70])

# because tics and axes are different, call axis() twice, once to
# specify x-axis, the other to specify y-axis
axis(d, linewidth=0.5, xtitle='Workloads',
	xtitlesize=4, xmanual=t.query(select='reader,rownumber'), xlabelfontsize=3, ytitle='Throughput (GB/s)',
	ytitlesize=5, ylabelfontsize=5, yauto=[0,2000000,300000], ticmajorsize=2, xlabelshift=[0,2], ylabelshift=[2,0], xtitleshift=[0,3])

p = plotter()
L = legend()

barargs = {'drawable':d, 'table':t, 'xfield':'rownumber',
           'linewidth':0.3, 'fill':True, 'barwidth':0.7,
		   'legend':L, 'stackfields':[]}

barargs['yfield'] = 'Vanilla'
barargs['legendtext'] = 'Vanilla'
barargs['fillcolor'] = 'dimgray'
barargs['fillstyle'] = 'hline'
barargs['fillsize'] = '0.5'
barargs['fillskip'] = '0.5'
barargs['cluster'] = [0,6]
p.verticalbars(**barargs)

barargs['yfield'] = 'Cross_Naive'
barargs['legendtext'] = 'CNaive'
barargs['fillcolor'] = 'darkorange'
barargs['fillstyle'] = 'solid'
barargs['fillsize'] = '0.5'
barargs['fillskip'] = '0.5'
barargs['cluster'] = [1,6]
p.verticalbars(**barargs)

barargs['yfield'] = 'CNI'
barargs['legendtext'] = 'CNI'
barargs['fillcolor'] = 'dimgray'
barargs['fillstyle'] = 'dline2'
barargs['fillsize'] = '0.5'
barargs['fillskip'] = '0.5'
barargs['cluster'] = [2,6]
p.verticalbars(**barargs)

barargs['yfield'] = 'CPNI'
barargs['legendtext'] = 'CPNI'
barargs['fillcolor'] = 'black'
barargs['fillstyle'] = 'dline1'
barargs['fillsize'] = '0.5'
barargs['fillskip'] = '0.5'
barargs['cluster'] = [3,6]
p.verticalbars(**barargs)

barargs['yfield'] = 'CPBI'
barargs['legendtext'] = 'CPBI'
barargs['fillcolor'] = 'bisque'
barargs['fillstyle'] = 'solid'
barargs['fillsize'] = '0.5'
barargs['fillskip'] = '1'
barargs['cluster'] = [4,6]
p.verticalbars(**barargs)

barargs['yfield'] = 'CPBV'
barargs['legendtext'] = 'CPBV'
barargs['fillcolor'] = 'black'
barargs['fillstyle'] = 'solid'
barargs['fillsize'] = '0.5'
barargs['fillskip'] = '1'
barargs['cluster'] = [5,6]
p.verticalbars(**barargs)



L.draw(c, coord=[d.left()+20, d.top()-10], width=10, height=4, fontsize=4, hspace=1, skipnext=2, skipspace=32)

c.render()
