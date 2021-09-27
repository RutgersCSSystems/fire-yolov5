# This file does bar plots with variability
set terminal postscript eps color noenhanced lw 2 "Helvetica,18" 
# Output file name
# Type of graph

set title "Rocksdb 1M 16th Locking Wait vs Prefetch Type NVMe-SSD"

set style data histogram
# Visual details -- solid fill, 0.5 transparency
set style histogram cluster gap 1
set style fill pattern 1 border lt 2
set style increment default
set boxwidth 0.9 absolute
# No xtics, but we do want labels, and do not mirror tics (ie show at top)
set xtics format "" nomirror
#set xtic rotate
set xtics rotate by 45 offset -0.8,-1.8

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
set key fixed right top vertical Right noreverse noenhanced autotitle nobox
# y axis label and range -- no details needed for x axis
set ylabel "Total Wait MicroSec"
set xlabel "Thread Count"
set yrange [0:80]
# Actually do the plot; use cols 2-4 from the file; linecolor gives the color, 
# linewidth 0 removes the outline of the column

plot 'totalwait_16th.dat' u (column("onlyapp_pred")/1000000):"-":"-":xtic(1) title "Only App Pred", \
     '' u (column("onlylib_pred")/1000000):"-":"-" title "Only Lib Pred", \
     '' u (column("onlyos_pred")/1000000):"-":"-" title "Only OS Pred", \
     '' u (column("lib-os_pred")/1000000):"-":"-" title "Lib+OS Pred", \
     '' u (column("app-os_pred")/1000000):"-":"-" title "App+OS Pred"

set output 'rocksdb_totalwait_locks_diff_prefetching.eps'
replot
