SIZE=50

all:
	gcc read.c -DFILESZ=$(SIZE) -DONLYOS -o read_onlyos
	gcc read.c -DFILESZ=$(SIZE) -DAPP_NATIVE_RA -o read_nativera
	gcc read.c -DFILESZ=$(SIZE) -DREADRA -o read_readra
	gcc read.c -DFILESZ=$(SIZE) -DAPP_NATIVE_RA -DONLYAPP -o read_onlyapp_nativera
	gcc read.c -DFILESZ=$(SIZE) -DREADRA -DONLYAPP -o read_onlyapp_readra
	gcc write.c -DFILESZ=$(SIZE) -o write
	gcc pread_ra_v_pread.c -DPREAD -o pread
	gcc pread_ra_v_pread.c -o pread_ra
