#include <stdio.h>
#include <stdlib.h>

#define FILESIZE (10L * 1024L * 1024L * 1024L)

int main() {
	long i;
	FILE *fp;

	fp=fopen("bigfakefile.txt","w");

	for(i=0; i<FILESIZE; i++) {
		fprintf(fp,"C");
	}

	fclose(fp);
	return 0;
}
