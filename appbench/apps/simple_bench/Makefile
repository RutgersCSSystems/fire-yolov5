all:
	gcc read.c -DONLYOS -o read_onlyos
	gcc read.c -DAPP_NATIVE_RA -o read_nativera
	gcc read.c -DREADRA -o read_readra
	gcc read.c -DAPP_NATIVE_RA -DONLYAPP -o read_onlyapp_nativera
	gcc read.c -DREADRA -DONLYAPP -o read_onlyapp_readra
	gcc write.c -o write
