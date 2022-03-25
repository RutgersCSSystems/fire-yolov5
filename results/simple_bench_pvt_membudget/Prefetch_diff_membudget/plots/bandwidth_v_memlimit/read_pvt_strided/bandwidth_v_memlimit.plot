set terminal postscript eps color enhanced lw 2 "Helvetica,18" 
set boxwidth 0.9 absolute
set style fill pattern 1 border lt -1
set style increment default
set style histogram clustered gap 1 title textcolor lt -1

set datafile missing '-'
set datafile commentschars "#"
set datafile separator ","

set style data histograms
set xtics border in scale 0,0 nomirror autojustify
set xtics  norangelimit 

set key font "Helvetica, 14"
set key fixed left top vertical Right noreverse noenhanced autotitle nobox

set title "SimpleBench-pvt_strided MemBudget Prefetching Characterization np=16"

set ylabel "Throughput (MB/sec)"
set xlabel "Memory Budget (% of Total Cache Usage)"

set yrange [0:2000]

plot 'all.csv' u "VANILLA":xtic(1) title "VANILLA",\
 '' u "CBNMB" title "Cross_BlockRA_NoPred_MaxMem_BG",\
 '' u "CBNBB" title "Cross_BlockRA_NoPred_Budget_BG",\
 '' u "CBPBB" title "Cross_BlockRA_Pred_Budget_BG",\
 '' u "CBPMB" title "Cross_BlockRA_Pred_MaxMem_BG",\
 '' u "CFPMB" title "Cross_FileRA_Pred_MaxMem_BG"

set output 'bandwidthvmembudget.eps'
replot
