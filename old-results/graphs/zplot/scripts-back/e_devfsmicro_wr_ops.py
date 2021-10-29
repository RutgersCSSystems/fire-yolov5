#! /usr/bin/env python

import sys
from zplot import *
import sys, getopt


n1 = table(file='../data/e_devfsmicro_wr_ops4.data')
d1 = table(file='../data/e_devfsmicro_wr_ops1.data')
d2 = table(file='../data/e_devfsmicro_wr_ops2.data')
d3 = table(file='../data/e_devfsmicro_wr_ops3.data')

c = canvas('eps', title='graph', dimensions=[360, 328])
d = drawable(canvas=c, xrange=[0,16], yrange=[0,10], coord=[40,40],
             dimensions=[310,250])

L=legend()

p = plotter()
p.verticalbars(drawable=d, table=n1, xfield='c0', yfield='c1', fill=True,
               fillcolor='white', barwidth=0.9, linewidth=0.5, yloval=0,
               legend=L, legendtext='NOVA')
p.verticalbars(drawable=d, table=d1, xfield='c0', yfield='c1', fill=True,
               fillcolor='lightgrey', barwidth=0.9, linewidth=0.5, yloval=0,
               legend=L, legendtext='DevFS [standard]')
p.verticalbars(drawable=d, table=d2, xfield='c0', yfield='c1', fill=True,
               fillcolor='darkgray', barwidth=0.9, linewidth=0.5, yloval=0,
               legend=L, legendtext='DevFS [+cap]')
p.verticalbars(drawable=d, table=d3, xfield='c0', yfield='c1', fill=True,
               fillcolor='black', barwidth=0.9, linewidth=0.5, yloval=0,
               legend=L, legendtext='DevFS [+cap +direct]')

# a bit of a hack to get around that we don't support date fields (yet)
axis(drawable=d, style='xy', xmanual=[['1KB',2.5],['4KB',7.5],['16KB',12.5]],
     ymanual=[['0',0],['0.5',5],['1.0', 10]],
     linewidth=0.5, xlabelfontsize=10.0, xlabelshift=[0,0],
     xtitle='Block Size', ytitle='Million Ops / Second')

L.draw(canvas=c, coord=[240,310], skipnext=4, skipspace=50)
     
#axis(drawable=d, style='x', xmanual=[['00', 100],['01',101]], domajortics=False,
#     xaxisposition=0, linewidth=0.5, xlabelfontsize=8.0, xlabelformat='\'%s',
#     xlabelshift=[0,-30], doaxis=False, xlabelfontcolor='white')


c.render()




