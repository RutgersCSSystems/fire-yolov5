#! /usr/bin/env python

from zplot import *

# populate zplot table from data file
t = table('fsmetamem.data')

# create the postscript file we'll use as our canvas
canvas = postscript('fsmetamem.eps')

# on the x-axis, we want categories, not numbers.  Thus, we
# determine the number of categories by checking the max
# "rownumber" (a field automatically added by zplot).  We want a
# half bar width (0.5) to the left and right of the bar locations
# so we don't overflow the drawable.
d = drawable(canvas, coord=[50,30], xrange=[-0.5,t.getmax('rownumber')+0.5], yrange=[0,2000])


# xmanual is a list of the form [(label1,x1), (label2,x2), ...].
# We want to use the "op" field from the data file as our labels
# and use "rownumber" as our x coordinate.
axis(d, xtitle='Operation', xmanual=t.query(select='ops,rownumber'),
     ytitle='Latency (ms)', yauto=[0,2000,500])



# we are going to create several bars with similar arguments.  One
# easy way to do this is to put all the arguments in a dict, and
# use Python's special syntax ("**") for using the dict as named
# args.  Then we can tweak the args between each call to
# verticalbars.
#
# yfield determines the bar height, and stackfields determines
# where the bottom of a bar starts.  This is useful for showing
# several bar sections to indicate a breakdown.  After the first
# bar, we append the previous yfield to stackfields to stack the bars.
p = plotter()
L = legend()
barargs = {'drawable':d, 'table':t, 'xfield':'rownumber',
           'linewidth':0, 'fill':True, 'barwidth':0.8,
           'legend':L, 'stackfields':[]}

# compute bar
barargs['yfield'] = 'ext4_inode_cache'
barargs['legendtext'] = 'ext4_inode_cache'
barargs['fillcolor'] = 'red'
p.verticalbars(**barargs)

# network bar
barargs['stackfields'].append(barargs['yfield'])
barargs['yfield'] = 'kmalloc_256'
barargs['legendtext'] = 'kmalloc_256'
barargs['fillcolor'] = 'green'
p.verticalbars(**barargs)

# storage bar
barargs['stackfields'].append(barargs['yfield'])
barargs['yfield'] = 'dentry'
barargs['legendtext'] = 'dentry'
barargs['fillcolor'] = 'blue'
p.verticalbars(**barargs)



# we want legend entries to be all on one line.  Thus, we use
# skipnext=1 to get one row.  We specify the horizontal space
# between legend symbols (not considering text) with skipspace.
L.draw(canvas, coord=[d.left()+30, d.top()-5], skipnext=1, skipspace=40)
  
canvas.render()

