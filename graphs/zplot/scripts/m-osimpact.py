#!/usr/bin/env python
# a bar plot with errorbars
import numpy as np
import matplotlib.pyplot as plt
import sys, getopt
import matplotlib as mpl
print(mpl.__version__) # should be 2.x.y
import os
import re
import matplotlib

import matplotlib as mpl
#mpl.rcParams['hatch.linewidth'] = 0.1  # previous pdf hatch linewidth
#mpl.rcParams['hatch.linewidth'] = 1.0  # previous svg hatch linewidth



N = 3
ind = np.arange(N)  # the x locations for the groups
width = 0.05       # the width of the bars

def setHatchThickness(value):
	libpath = matplotlib.__path__[0]
	backend_pdf = libpath + "/backends/backend_pdf.py"
	with open(backend_pdf, "r") as r:
	    code = r.read()
	    code = re.sub(r'self\.output\((\d+\.\d+|\d+)\,\ Op\.setlinewidth\)',
			   "self.output(%s, Op.setlinewidth)" % str(value), code)
	    #with open('/tmp/hatch.tmp', "w") as w:
	    #        w.write(code)
	    #print backend_pdf
	    #os.system('sudo mv /tmp/hatch.tmp %s' % backend_pdf)



def main(argv):

	inputfile = ''
	outputfile = ''
	ymax=3000
	yint=400
	xfield='ops'
	xlegend='DevFS techniques'
	barwidth = 0.9
	xfontsize=10.0
	xlabelsize=10.0
	xydim=[250, 210]
	xystart=[190,170]
	xylegend=[60,200]
	xfont = xfontsize
	yfont = xfontsize
	xycord = [50,20]
	#barwidth = 0.3

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
                         inputfile = arg
                elif opt in ("-o", "--ofile"):
                         outputfile = arg
                elif opt in ("-y", "--ymax"):
                         ymax = float(arg)
                         print ymax
                elif opt in ("-r", "--intrvl"):
                         yint = float(arg)
                         print yint

        print 'Input file is', inputfile
        print 'Output file is', outputfile

	data = np.genfromtxt(inputfile, delimiter=',', dtype = float)

	Cache = [row[1] for row in data]
	Migrated = [row[2] for row in data]
	Apppages = [row[3] for row in data]
	FS = ['Cache', 'Migrated', 'App-pages']

	fig, ax = plt.subplots()

	index = np.arange(N)
	bar_width = 0.1
	opacity = 0.4
	error_config = {'ecolor': '0.3'}

	rects0 = plt.bar(index, Cache, bar_width,
			 color='darkgray',                 
			 edgecolor = 'black',  
                         fill=True,
			 label=FS[0])

	rects1 = plt.bar(index+ bar_width, Migrated, bar_width,
			 color='lightgrey',                 
			 edgecolor = 'black',  
                         fill=True,
			 label=FS[1])

	rects2 = plt.bar(index+ 2*bar_width, Apppages, bar_width,
			 color='black',
			 edgecolor = 'black',  
			 hatch='/',
			 fill=True,
			 label=FS[2])

	ax.set_ylabel('Througput OPS/sec')
	#ax.set_title('Instructions Executed')
	plt.xticks(index + bar_width, ('RocksDB', 'filebench', 'Redis'))
	legend =plt.legend( (rects0[0], rects1[0], rects2[0]), ('AppSlow_OSSlow', 'AppSlow_OSFast', 'AppFast_OSSlow'))

	#setHatchThickness(0.4)

	# The frame is matplotlib.patches.Rectangle instance surrounding the legend.
	#frame = legend.get_frame()
	#frame.set_facecolor('0.90')
	plt.tight_layout()
	plt.plot()
	plt.savefig(outputfile +'.pdf',dpi=300)
	plt.show



if __name__ == "__main__":
   main(sys.argv[1:])
	
