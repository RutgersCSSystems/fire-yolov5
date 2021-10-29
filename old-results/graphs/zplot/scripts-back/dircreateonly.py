#! /usr/bin/env python


from zplot import *

import sys, getopt


def main(argv):

	inputfile = ''
	outputfile = ''
	ymax=2000
	yint=1000	

	try:
		opts, args = getopt.getopt(argv,"hi:o:",["ifile=","ofile="])
	except getopt.GetoptError:
		print 'verticalbars.py -i <inputfile> -o <outputfile>'
		sys.exit(2)

	for opt, arg in opts:
		if opt == '-h':
			 print 'verticalbars.py -i <inputfile> -o <outputfile>'
			 sys.exit()
		elif opt in ("-i", "--ifile"):
			 inputfile = arg
		elif opt in ("-o", "--ofile"):
			 outputfile = arg

	print 'Input file is', inputfile
	print 'Output file is', outputfile

	# populate zplot table from data file
	t = table(inputfile)

	# create the postscript file we'll use as our canvas
	canvas = postscript(outputfile)

	# on the x-axis, we want categories, not numbers.  Thus, we
	# determine the number of categories by checking the max
	# "rownumber" (a field automatically added by zplot).  We want a
	# half bar width (0.5) to the left and right of the bar locations
	# so we don't overflow the drawable.
	d = drawable(canvas,  coord=[50,30], xrange=[-0.5,t.getmax('rownumber')+0.5], yrange=[0,ymax])

	# xmanual is a list of the form [(label1,x1), (label2,x2), ...].
	# We want to use the "op" field from the data file as our labels
	# and use "rownumber" as our x coordinate.

        axis(d, xtitle='#. of directories (2-level)', xmanual=t.query(select='ops,rownumber'),
	     ytitle='Memory (MB)', yauto=[0,ymax,yint])



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

	barargs['yfield'] = 'inode_cache'
	barargs['legendtext'] = 'inode_cache'
	barargs['fillcolor'] = 'red'
	p.verticalbars(**barargs)

	# storage bar
	barargs['stackfields'].append(barargs['yfield'])
	barargs['yfield'] = 'dentry'
	barargs['legendtext'] = 'dentry'
	barargs['fillcolor'] = 'blue'
	p.verticalbars(**barargs)

	# storage bar
	barargs['stackfields'].append(barargs['yfield'])
	barargs['yfield'] = 'ext4_extent_status'
	barargs['legendtext'] = 'ext4_extent_status'
	barargs['fillcolor'] = 'yellow'
	p.verticalbars(**barargs)

	barargs['stackfields'].append(barargs['yfield'])
	barargs['yfield'] = 'other_bufs'
	barargs['legendtext'] = 'other_bufs'
	barargs['fillcolor'] = 'black'
	p.verticalbars(**barargs)

	# we want legend entries to be all on one line.  Thus, we use
	# skipnext=1 to get one row.  We specify the horizontal space
	# between legend symbols (not considering text) with skipspace.
        L.draw(canvas, coord=[d.left()+30, d.top()-5], skipspace=40)
	  
	canvas.render()

if __name__ == "__main__":
   main(sys.argv[1:])

