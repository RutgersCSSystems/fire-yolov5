#! /usr/bin/env python

from zplot import *

#We define a set of global variables. change the parameters here
legends=['Vanilla', 'Cross_Naive', 'CNI', 'CPNI', "CPNV", 'CPBI', 'CPBV']
legendtext=['Vanilla', 'CNaive', 'CNI', 'CPNI', "CPNV", 'CPBI', 'CPBV']


color=['dimgray', 'dimgray', 'darkorange', 'black', 'bisque', 'red', 'green']
filestyle=['hline', 'solid', 'dline1', 'dline2', 'dline1', 'solid', 'solid']



legends=['Vanilla', 'OSonly', 'Cross_Naive', 'CNI']
legendtext=['Vanilla', 'OSonly', 'CNaive', 'CNI']


clusterlen=len(legendtext)

#Graph x and y-axis dimension
graphxdim=140
graphydim=75

#graph plotting x and y dimension
plotxdim=120
plotydim=55

#Y-axis max and interval
ymax=700
yinterval=100

# Font Sizes
XTSIZE=4
YTSIZE=4

#default y-axis titley
ytitledef='Throughput (OPS/sec) in 100x'
xtitledef="Workload"

#we get the result file and result data using argument if not already NULL
output='filebench.DATA' if len(sys.argv) < 2 else sys.argv[1]
graptitle='filebench' if len(sys.argv) < 2 else sys.argv[2]

print output
t = table(file=output)



# We can override the global variables with environment variables set somewhere lese
def get_legends():
    global legends 
    global legendtext
    global clusterlen

    print str(os.getenv('legendlist'))

    if(str(os.getenv('legendlist')) != 'None'):
        legends=os.getenv('legendlist').split(',')
        clusterlen=len(legends)

    if(str(os.getenv('legendnamelist')) != 'None'):
        legendtext=os.getenv('legendnamelist').split(',')

    print legends
    print legendtext



def get_yrange():

    global ymax
    global yinterval

    if(str(os.getenv('ymax')) != 'None'):
        ymax = int(os.getenv('ymax'))
    else:
        return

    if(str(os.getenv('yinterval')) != 'None'):     
        yinterval = int(os.getenv('yinterval'))

    print "YMAX : " + str(ymax)
    print "YINTERVAL: " +  str(yinterval)
    ymax=int((math.ceil(ymax/yinterval) +2) * yinterval + yinterval)

def get_ytile():
    global ytitledef
    ytitledef = str(os.getenv('ytitledef'))
    global xtitledef
    xtitledef = str(os.getenv('xtitledef'))
    print ytitledef



get_legends()
get_yrange()
get_ytile()


ctype = 'eps'
c = canvas('pdf', title=graptitle, dimensions=[graphxdim, graphydim])

d = drawable(canvas=c, coord=[22,16], xrange=[-0.5,t.getmax('rownumber')+0.5], yrange=[0, ymax], dimensions=[plotxdim, plotydim])


# because tics and axes are different, call axis() twice, once to
# specify x-axis, the other to specify y-axis
axis(d, linewidth=0.5, xtitle=xtitledef,
        xtitlesize=XTSIZE, xmanual=t.query(select='reader,rownumber'), xlabelfontsize=XTSIZE, ytitle=ytitledef,
        ytitlesize=YTSIZE, ylabelfontsize=5, yauto=[0,ymax,yinterval], ticmajorsize=2, xlabelshift=[0,1], ylabelshift=[-1, 0], xtitleshift=[0,1])


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

L.draw(c, coord=[d.left()+4, d.top()-2], width=4, height=4, fontsize=XTSIZE, hspace=1, skipnext=3, skipspace=30)

c.render()
exit()
