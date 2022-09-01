#!/bin/bash
set -x

export legendlist="Vanilla,VanillaOPT,OSonly,CrossInfo,CrossInfoIOOPT"
export legendnamelist="Vanilla,VanillaOPT,OSonly,CrossInfo,CrossInfoIOOPT"
export ymax=40
export yinterval=5

#default y-axis and x-axis title
export ytitledef='Throughput (MB/sec)'
export xtitledef="#.of threads"


python plot.py graph.DATA outputgraph
