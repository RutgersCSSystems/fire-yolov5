set terminal postscript eps color enhanced lw 2 20 "Helvetica,18"
set yrange [0:300]
set y2range [0:4000]
set xlabel "PC Anon Ratio"
set ylabel "Time Taken in Seconds"
set y2label "%CPU Utilization"
set y2tics nomirror
#set autoscale y 
set ytics nomirror
set key left top box linetype 0 spacing 0.8 width 0.1
#set key left top box width 0.1
set key vertical maxrows 4
set key font ",20"
set style line 1 lt 1 pt 8 lw 3 ps 1.8 lc rgb "#DE4B48"
set boxwidth 1 relative
set style data histograms
set datafile commentschars "#"
set datafile missing '#'
set xtic rotate font ",18"
set datafile commentschars "#"
set datafile missing '#'
#set xtics offset 4
set style fill solid 1.0 border 0
set datafile separator "," 
plot "Vanilla_btio_C.csv" using 4:xticlabels(1) axes x1y1 fs pattern 6 t "Elapsed time (Vanilla)" lc rgb "#00006F",  \
     "IntelliOS_btio_C.csv" using 4:xticlabels(1) axes x1y1 fs pattern 2 t "Elapsed time (IntelliOS)" lc rgb "#6F0000", \
     "Vanilla_btio_C.csv" using 7:xticlabels(1) axes x1y2 with linespoints  lc rgb "#FF0000" lw 1 ps 1 t "% CPU Util (Vanilla)", \
     "IntelliOS_btio_C.csv" using 7:xticlabels(1) axes x1y2 with linespoints  lc rgb "#0000F0" lw 1 ps 1 t "% CPU Util (IntelliOS)"
set output 'Both-reclaim-btioC.eps'
replot

