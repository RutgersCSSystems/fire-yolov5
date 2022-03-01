#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/syscall.h>


#include "util.h"

int main() {
	long i;
	FILE *fp;


        const char* str1 = BASE_FILENAME;
        char filename[FILENAMEMAX];

        file_name(str1, FILESZ, filename);

	fp=fopen(filename,"w");

	for(i=0; i<FILESIZE; i++) {
		fprintf(fp,"C");
	}

	fclose(fp);
	return 0;
}
