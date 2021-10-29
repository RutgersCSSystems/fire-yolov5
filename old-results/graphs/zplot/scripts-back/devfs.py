#! /usr/bin/env python


from zplot import *

import sys, getopt


def main(argv):

	inputfile = ''
	outputfile = ''
	ymax=2000
	yint=100	
	xfield='ops'
	xlegend="No. of threads sharing a file"
	#xlegend='#. of files'

	try:
		opts, args = getopt.getopt(argv,"hi:o:y:",["ifile=","ofile=","ymax="])
	except getopt.GetoptError:
		print 'verticalbars.py -i <inputfile> -o <outputfile>'
		#sys.exit(2)

	for opt, arg in opts:
		if opt == '-h':
			 print 'verticalbars.py -i <inputfile> -o <outputfile>'
			 sys.exit()
		elif opt in ("-i", "--ifile"):
			 inputfile = arg
		elif opt in ("-o", "--ofile"):
			 outputfile = arg
		elif opt in ("-y", "--ymax"):
			 ymax = int(arg)
			 print ymax
		elif opt in ("-r", "--intrvl"):
			 yint = int(arg)
			 print yint


	print 'Input file is', inputfile
	print 'Output file is', outputfile

	# populate zplot table from data file
	t = table(inputfile)

	# create the postscript file we'll use as our canvas
	#canvas = postscript(outputfile, dimensions=[300,180]))
	ctype = 'eps'
	canvas= make_canvas(ctype, title=outputfile, dimensions=[350,180])

	# on the x-axis, we want categories, not numbers.  Thus, we
	# determine the number of categories by checking the max
	# "rownumber" (a field automatically added by zplot).  We want a
	# half bar width (0.5) to the left and right of the bar locations
	# so we don't overflow the drawable.
	d = drawable(canvas,  coord=[50,30], xrange=[-0.5,t.getmax('rownumber')+1], yrange=[0,ymax])

	# xmanual is a list of the form [(label1,x1), (label2,x2), ...].
	# We want to use the "op" field from the data file as our labels
	# and use "rownumber" as our x coordinate.

	axis(d, xtitle=xlegend, xmanual=t.query(select='Threads,rownumber'),
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

	# randread bar
	barargs['yfield'] = 'Ext4-DAX'
	barargs['legendtext'] = 'Ext4-DAX'
	barargs['fillcolor'] = 'red'
	p.verticalbars(**barargs)

	# network bar
	barargs['stackfields'].append(barargs['yfield'])
	barargs['yfield'] = 'DevFS'
	barargs['legendtext'] = 'DevFS'
	barargs['fillcolor'] = 'green'
	p.verticalbars(**barargs)

	# storage bar
	barargs['stackfields'].append(barargs['yfield'])
	barargs['yfield'] = 'DevFS-OPT-Alloc'
	barargs['legendtext'] = 'DevFS-OPT-Alloc'
	barargs['fillcolor'] = 'blue'
	p.verticalbars(**barargs)

	# storage bar
	barargs['stackfields'].append(barargs['yfield'])
	barargs['yfield'] = 'DevFS-OPT-Alloc-NoCntxSwitch'
	barargs['legendtext'] = 'DevFS-OPT-Alloc-NoCntxSwitch'
	barargs['fillcolor'] = 'yellow'
	p.verticalbars(**barargs)

	#barargs['stackfields'].append(barargs['yfield'])
	#barargs['yfield'] = 'ext4_inode'
	#barargs['legendtext'] = 'ext4_inode'
	#barargs['fillcolor'] = 'black'
	#p.verticalbars(**barargs)



	# we want legend entries to be all on one line.  Thus, we use
	# skipnext=1 to get one row.  We specify the horizontal space
	# between legend symbols (not considering text) with skipspace.
        L.draw(canvas, coord=[d.left()+10, d.top()-5], skipspace=70, skipnext=1)
	  
	canvas.render()


if __name__ == "__main__":
   main(sys.argv[1:])

