set terminal postscript eps color noenhanced lw 2 "Helvetica,18" 
# Output file name
# Type of graph
set style data histogram
# Visual details -- solid fill, 0.5 transparency
set style histogram cluster gap 1
set style fill pattern 1 border lt 2
set style increment default
set boxwidth 0.9 absolute
# No xtics, but we do want labels, and do not mirror tics (ie show at top)
set xtics format "" nomirror
#set xtic rotate
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
set title "RocksDB-readrandom Prefetching Characterization: Mem = 0.2*CacheUsage"
#The legend ('key') -- single data set does not need one
# But if we want a legend, uncomment this
# set key on outside center bottom 
set key fixed left top vertical Right noreverse noenhanced autotitle nobox
# y axis label and range -- no details needed for x axis
set ylabel "Throughput (MB/sec)"
set xlabel "App Threads"
set yrange [0:6000]
# Actually do the plot; use cols 2-4 from the file; linecolor gives the color, 
# linewidth 0 removes the outline of the column

plot 'VANILLA_readrandom.csv' u "VANILLA-avg":"VANILLA-min":"VANILLA-max":xtic(1) title "APP only", \
     'CBNMB_readrandom.csv' u "CBNMB-avg":"CBNMB-min":"CBNMB-max" title "Cross_BlockRA_NoPred_MaxMem_BG", \
     'CBPMB_readrandom.csv' u "CBPMB-avg":"CBPMB-min":"CBPMB-max" title "Cross_BlockRA_Pred_MaxMem_BG", \
     'CBNBB_readrandom.csv' u "CBNBB-avg":"CBNBB-min":"CBNBB-max" title "Cross_BlockRA_NoPred_Budget_BG", \
     'CBPBB_readrandom.csv' u "CBPBB-avg":"CBPBB-min":"CBPBB-max" title "Cross_BlockRA_Pred_Budget_BG"

# if we want to output in more formats, we can add more set term lines and more output names
# and replot; but graphs will not be identical since the drivers and file types have
# different limitations and defaults (eg what is a line thickness of '1'?)
set output 'bandwidthvthreads.eps'
replot
