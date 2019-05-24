#! /usr/bin/env python


import sys
from zplot import *
import sys, getopt

bartypes = [('hline', 1, 1),
            ('vline', 1, 1),
            ('hvline', 1, 1),
            ('dline1', 1, 2),
            ('dline2', 1, 2),
            ('dline12', 0.5, 2),
            ('circle', 1, 2),
            ('square', 1, 1),
            ('triangle', 2, 2),
            ('utriangle', 2, 2)]


def main(argv):

	outputfile = ''
	ymax=2000
	yint=100	
	xfield='ops'

	xfont = 18
	yfont = 18

	barwidth = 0.3

	ngraph = 3

	xdim = 500
	ydim = 230
	xsize = 100
	ysize = 160
	ystart = 30
	xstart = 70

	ngraphs = 3

	t = [None]*ngraphs
	d = [None]*ngraphs
	inputfile = [None]*ngraphs
	x = [None]*ngraphs
	y = [None]*ngraphs
	xlegend=['1K','4K', '16K']
	pattern = ['solid', 'hline', 'hvline', 'triangle']
	inidx = 0

	try:
		opts, args = getopt.getopt(argv,"hi:o:y:r:",["ifile=","ofile=","ymax=","yint="])
	except getopt.GetoptError:
		print 'verticalbars.py -i <inputfile> -o <outputfile>'
		sys.exit(2)

	for opt, arg in opts:
		if opt == '-h':
			 print 'verticalbars.py -i <inputfile> -o <outputfile>'
			 sys.exit()
		elif opt in ("-i", "--ifile"):
			 #inputfile.append(arg)
			 inputfile[inidx] = arg
			 inidx = inidx+1;
			 print inidx
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

	# create the postscript file we'll use as our canvas
	ctype = 'eps'
	canvas= make_canvas(ctype, title=outputfile, dimensions=[xdim,ydim])

	L = len(bartypes)

	for tidx in range(len(inputfile)):

		# populate zplot table from data file
		t[tidx] = table(inputfile[tidx])
		#row = t[tidx].getrowvalues(0)
	 	#tab = table()	
		#print "t[tidx] ", t[tidx].getvalues('c0')
		#t[tidx].update(set='c1 = 10000')
		

		# Set X to previous dimensions
		if tidx == 0:
			y[tidx] = ystart
			x[tidx] = xstart
			d[tidx] = drawable(canvas, xrange=[0,10], yrange=[0,ymax], coord=[x[tidx],y[tidx]], dimensions=[xsize,ysize])
			axis(d[tidx], xtitle=xlegend[tidx], xtitleshift=[-20,-10], xlabelshift=[-10,-10],
			     ytitle='Ops per sec(x100K)', yauto=[0,ymax,yint], ylabelfontsize=yfont, xlabelfontsize=xfont,
			     ytitlesize = yfont, xtitlesize = xfont, doxlabels = False, doxmajortics=False, xaxisposition=0)
		else:
			y[tidx] = ystart
	
			x[tidx] = x[tidx-1] + xsize - 40
			d[tidx] = drawable(canvas, xrange=[0,10], yrange=[0,ymax], coord=[x[tidx],y[tidx]], dimensions=[xsize,ysize])

			axis(d[tidx], xtitle=xlegend[tidx], xtitleshift=[-20,-10], 
			     ytitle='', yauto=[0,ymax,yint], ylabelfontsize=yfont, xlabelfontsize=xfont,
			     ytitlesize = yfont, xtitlesize = xfont, doxlabels = False, doxmajortics=False,  
				doylabels=False, style='x')

		L = legend()
		#legends = ['NOVA','DevFS-J','DevFS-C','DevFS-C-K']
		legends = ['','','','']
		i = 0
		j = 1
		p = plotter()

		for btype in pattern:
		    colstr = 'c' + str(j)
		    p.verticalbars(drawable=d[tidx], table=t[tidx], xfield='c0', yfield=colstr, fill=True,
				   fillcolor='darkgray', fillstyle=btype, barwidth=1,
				   fillsize=1, fillskip=1, legend=L, legendtext=legends[i])
		    t[tidx].update(set='c0=c0+1')
		    i = i+1
		    j = j+1

	# we want legend entries to be all on one line.  Thus, we use
	# skipnext=1 to get one row.  We specify the horizontal space
	# between legend symbols (not considering text) with skipspace.
        #L.draw(canvas, coord=[d[0].left()+5, d[0].top()+20], skipspace=100, skipnext=1, fontsize=20.0)
	  
	canvas.render()


if __name__ == "__main__":
   main(sys.argv[1:])

