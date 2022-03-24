#include <stdio.h>
#include <stdlib.h>


#define MEMSIZE (5 * 1024 *1024 *1024UL)


int main()
{
        int *i = (int*)malloc(MEMSIZE);

        long nr = MEMSIZE/sizeof(int);

        for(long a=0; a<nr; a++){
                i[a] = 10;
        }

        return 0;
}
