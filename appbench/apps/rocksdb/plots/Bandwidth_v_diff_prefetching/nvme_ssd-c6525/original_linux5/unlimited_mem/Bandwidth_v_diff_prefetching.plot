# This file does bar plots with variability
set terminal postscript eps color noenhanced lw 2 "Helvetica,18" 
# Output file name
# Type of graph

set title "Rocksdb 4M keys Threads vs Prefetch Type NVMe-SSD"

set style data histogram
# Visual details -- solid fill, 0.5 transparency
set style histogram cluster gap 1
set style fill pattern 1 border lt 2
set style increment default
set boxwidth 0.9 absolute
# No xtics, but we do want labels, and do not mirror tics (ie show at top)
set xtics format "" nomirror
#set xtic rotate
set xtics

# y tic marks plus grid lines
set grid ytics
# Control the look of the error bars
set style histogram errorbars linewidth 1 
set errorbars linecolor black
set bars front
set datafile commentschars "#"
set datafile separator ","
# Define some custom colours using RGB; can also use standard names ("blue")
red = "#FF0000"; green = "#00FF00"; blue = "#0000FF"; skyblue = "#87CEEB";
# We don't set a title -- but we could by uncommenting this next line
#The legend ('key') -- single data set does not need one
# But if we want a legend, uncomment this
# set key on outside center bottom 
set key fixed left top vertical Right noreverse noenhanced autotitle nobox
# y axis label and range -- no details needed for x axis
set ylabel "Bandwidth(MB/sec)"
set xlabel "Thread Count"
set yrange [0:11000]
# Actually do the plot; use cols 2-4 from the file; linecolor gives the color, 
# linewidth 0 removes the outline of the column

plot 'bandwidth_diff_pfetch.dat' u "onlyapp_pred":"-":"-":xtic(1) title "Only App Pred", \
     '' u "onlylib_pred":"-":"-" title "Only Lib Pred", \
     '' u "onlyos_pred":"-":"-" title "Only OS Pred", \
     '' u "lib-os_pred":"-":"-" title "Lib+OS Pred", \
     '' u "app-os_pred":"-":"-" title "App+OS Pred"

set output 'rocksdb_bandwidth_diff_prefetching.eps'
replot
