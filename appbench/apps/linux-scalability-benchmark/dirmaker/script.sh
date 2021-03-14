#!/bin/sh

dir=/sys/kernel/debug/tracing

echo __rb_insert > set_graph_function
echo function_graph > ${dir}/current_tracer
echo 1 > ${dir}/tracing_on
#./dirmaker 1
#echo 0 > ${dir}/tracing_on
#less ${dir}/trace
