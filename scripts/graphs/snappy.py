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
graphxdim=120
graphydim=80

#graph plotting x and y dimension
plotxdim=100
plotydim=60

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


# We can override the global variables with environment variables set somewhere lese
def get_legends():
    global legends 
    global legendtext
    temp-legends=os.getenv('techarrlist').split(',')
    temp-legendtext=os.getenv('techarrnamelist').split(',')

    if len(temp-legends) > 0
        legends = temp-legends;

    if len(temp-legendtext) > 0    
        legendtext = temp-legendtext;

    print legends
    print legendtext



def get_yrange():

    global ymax
    global yinterval

    ymax-temp = int(os.getenv('ymax'))
    yinterval-temp = int(os.getenv('yinterval'))

    if(ymax-temp < 1) or if(yinterval-temp < 1)
        return 
    else {
            ymax = ymax-temp
            yinterval = yinterval-temp
    }

    print ymax
    print yinterval
    ymax=int((math.ceil(ymax/yinterval) +2) * yinterval)

def get_ytile():
    global ytitledef
    ytitledef = str(os.getenv('ytitledef'))
    global xtitledef
    xtitledef = str(os.getenv('xtitledef'))

    #print ytitledef



get_legends()

get_yrange()

get_ytile()


ctype = 'eps' if len(sys.argv) < 5 else sys.argv[6]
c = canvas('pdf', title=graptitle, dimensions=[graphxdim, graphydim])
t = table(file=output)


d = drawable(canvas=c, coord=[22,10], xrange=[-0.5,t.getmax('rownumber')+0.5], yrange=[0, ymax], dimensions=[plotxdim, plotydim])


# because tics and axes are different, call axis() twice, once to
# specify x-axis, the other to specify y-axis
axis(d, linewidth=0.5, xtitle=xtitledef,
        xtitlesize=XTSIZE, xmanual=t.query(select='reader,rownumber'), xlabelfontsize=5, ytitle=ytitledef,
        ytitlesize=YTSIZE, ylabelfontsize=5, yauto=[0,ymax,yinterval], ticmajorsize=2, xlabelshift=[0,1], ylabelshift=[1,0], xtitleshift=[0,6])


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

L.draw(c, coord=[d.left()+10, d.top()-1], width=4, height=4, fontsize=4, hspace=1, skipnext=1, skipspace=20)

c.render()
exit()
