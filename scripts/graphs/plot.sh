#!/bin/bash
set -x

export legendlist="Vanilla,VanillaOPT,OSonly,CrossInfo,CrossInfoIOOPT"
export legendnamelist="Vanilla,VanillaOPT,OSonly,CrossInfo,CrossInfoIOOPT"
export ymax=40
export yinterval=5
python plot.py graph.DATA outputgraph
