#include <stdio.h>
#include <stdlib.h>

int main() {
	long i;
	FILE *fp;

	fp=fopen("bigfakefile.txt","w");

	for(i=0; i<(10UL*1024*1024*1024); i++) {
		fprintf(fp,"C");
	}

	fclose(fp);
	return 0;
}
