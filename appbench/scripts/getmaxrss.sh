cut -d"," -f2 $1 | sort -n | sed -n '1s/^/min=/p; $s/^/max=/p'
cat $1 | awk -F',' '{ sum += $2; n++ } END { if (n > 0) print "avg="sum / n; }'
