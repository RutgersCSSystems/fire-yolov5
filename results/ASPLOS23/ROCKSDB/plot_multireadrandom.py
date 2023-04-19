#! /usr/bin/env python

import sys
#sys.path.append('..')
from zplot import *

ctype = 'eps' if len(sys.argv) < 2 else sys.argv[1]
#c = pdf('figure1.pdf')
c = canvas('pdf', title='multireadrandom-throughput', dimensions=[120, 60])
t = table(file='multireadrandom-THREADS-TRIAL2.DATA')

d = drawable(canvas=c, coord=[20,12], xrange=[-0.5,t.getmax('rownumber')+0.5],
        yrange=[0,2800], dimensions=[95, 45])

# because tics and axes are different, call axis() twice, once to
# specify x-axis, the other to specify y-axis
axis(d, linewidth=0.5, xtitle='Access Pattern',
	xtitlesize=5, xmanual=t.query(select='reader,rownumber'), xlabelfontsize=5,
    ytitle='Throughput (kop/s)',
	ytitlesize=5, ylabelfontsize=5, yauto=[0,2800,500], ticstyle='out', ticmajorsize=2, xlabelshift=[0,2], ylabelshift=[2,0], xtitleshift=[0,3],
    ytitleshift=[2,0])

#grid(drawable=d, x=False, yrange=[2000,8000], ystep=2000, linecolor='lightgrey', linedash=[1,1], linewidth=0.2)

p = plotter()
L = legend()

barargs = {'drawable':d, 'table':t, 'xfield':'rownumber',
           'linewidth':0.3, 'fill':True, 'barwidth':0.7,
		   'legend':L, 'stackfields':[], 'labelrotate': 90, 'labelshift': [-6, 1], 'labelsize': 3}

barargs['yfield'] = 'Vanilla'
barargs['legendtext'] = 'APPonly'
barargs['fillcolor'] = 'dimgray'
barargs['fillstyle'] = 'hline'
barargs['fillsize'] = '0.5'
barargs['fillskip'] = '0.5'
barargs['cluster'] = [0,5]
p.verticalbars(**barargs)

barargs['yfield'] = 'OSonly'
barargs['legendtext'] = 'OSonly'
barargs['fillcolor'] = 'gray'
barargs['fillstyle'] = 'solid'
barargs['fillsize'] = '1'
barargs['fillskip'] = '1'
barargs['cluster'] = [1,5]
p.verticalbars(**barargs)

barargs['yfield'] = 'CIP'
barargs['legendtext'] = 'Cross[+predict]'
barargs['fillcolor'] = 'red'
barargs['fillstyle'] = 'dline1'
barargs['fillsize'] = '0.5'
barargs['fillskip'] = '0.5'
barargs['cluster'] = [2,5]
p.verticalbars(**barargs)

barargs['yfield'] = 'CIPI'
barargs['legendtext'] = 'Cross[+predict+opt]'
barargs['fillcolor'] = 'orange'
barargs['fillstyle'] = 'dline2'
barargs['fillsize'] = '0.5'
barargs['fillskip'] = '0.5'
barargs['cluster'] = [3,5]
p.verticalbars(**barargs)

barargs['yfield'] = 'CII'
barargs['legendtext'] = 'Cross[+fetchall+opt]'
barargs['fillcolor'] = 'purple'
barargs['fillstyle'] = 'dline2'
barargs['fillsize'] = '0.5'
barargs['fillskip'] = '1'
barargs['cluster'] = [4,5]
p.verticalbars(**barargs)


#barargs['yfield'] = 'crossfs'
#barargs['legendtext'] = 'CrossFS'
#barargs['fillcolor'] = 'limegreen'
#barargs['fillstyle'] = 'solid'
#barargs['fillsize'] = '0.5'
#barargs['fillskip'] = '1'
#barargs['cluster'] = [3,7]
#p.verticalbars(**barargs)

#barargs['yfield'] = 'compoundfs_rr'
#barargs['legendtext'] = 'FusionFS-RR'
#barargs['fillcolor'] = 'darkorange'
#barargs['fillstyle'] = 'solid'
#barargs['fillsize'] = '0.5'
#barargs['fillskip'] = '1'
#barargs['cluster'] = [2,4]
#p.verticalbars(**barargs)


#barargs['yfield'] = 'compoundfs_automerge'
#barargs['legendtext'] = 'FusionFS-automerge'
#barargs['fillcolor'] = 'darkred'
#barargs['fillstyle'] = 'solid'
#barargs['fillsize'] = '0.5'
#barargs['fillskip'] = '1'
#barargs['cluster'] = [4,7]
#p.verticalbars(**barargs)

#barargs['yfield'] = 'compoundfs_cfs'
#barargs['legendtext'] = 'FusionFS'
#barargs['fillcolor'] = 'dimgray'
#barargs['fillstyle'] = 'dline2'
#barargs['fillsize'] = '0.5'
#barargs['fillskip'] = '1'
#barargs['cluster'] = [4,7]
#barargs['labelfield'] = 'compoundfs_cfs'
#p.verticalbars(**barargs)
#barargs['labelfield'] = ''
#
#barargs['yfield'] = 'crossfs_slow'
#barargs['legendtext'] = 'CrossFS-slow-device-cpu'
#barargs['fillcolor'] = 'mediumpurple'
#barargs['fillstyle'] = 'solid'
#barargs['fillsize'] = '0.5'
#barargs['fillskip'] = '1'
#barargs['cluster'] = [5,7]
#p.verticalbars(**barargs)
#
#
#barargs['yfield'] = 'compoundfs_slow'
#barargs['legendtext'] = 'FusionFS-slow-device-cpu'
#barargs['fillcolor'] = 'dimgray'
#barargs['fillstyle'] = 'hline'
#barargs['fillsize'] = '0.5'
#barargs['fillskip'] = '1'
#barargs['cluster'] = [6,7]
#barargs['labelfield'] = 'compoundfs_slow'
#p.verticalbars(**barargs)
#barargs['labelfield'] = ''

L.draw(c, coord=[d.left()+4, d.top()-3], width=4, height=4, fontsize=4,
        hspace=1, skipnext=5, skipspace=22)

c.render()
