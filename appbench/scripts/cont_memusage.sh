

while :
do
	##./a.out >> RUNTIME_MEMUSAGE.txt
	size0=$(numactl --hard | grep "node 0 size:" | awk '{print $4}')
	size1=$(numactl --hard | grep "node 1 size:" | awk '{print $4}')

	free0=$(numactl --hard | grep "node 0 free:" | awk '{print $4}')
	free1=$(numactl --hard | grep "node 1 free:" | awk '{print $4}')

	usedmem=$(echo "($size0-$free0) + ($size1-$free1)" | bc)
	echo $usedmem

	sleep 1
done
