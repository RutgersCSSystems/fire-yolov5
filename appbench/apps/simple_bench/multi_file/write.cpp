#define _LARGEFILE64_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <unistd.h>
#include <stdbool.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/syscall.h>

#include <iostream>
#include <vector>

#include "util.h"

using namespace std;


int main() {
        double i;
        FILE *fp;
        int fileno=0;
        vector<FILE *> filp_list;

        const char* str1 = "bigfakefile";
        char filename[FILENAMEMAX];

        for(i=0; i<NR_BG_THREADS; i++){
                file_name(str1, i, filename);
                fp=fopen(filename,"w");
                filp_list.push_back(fp);
        }

        for(i=0; i<FILESIZE; i++) {
                fileno = floor((i*NR_BG_THREADS)/FILESIZE);
                fprintf(filp_list[fileno],"C");
        }

        for(int i=0; i<NR_BG_THREADS; i++){
                fclose(filp_list[i]);
        }

        return 0;
}
