#include <string>
#include <fstream>
#include <stdlib.h>
#include <time.h>
#include "util.hpp"

// returns the pressure on memory
// values [0, 1]: 0->No pressure, 1->High pressure on mem
// High pressure means that there is lesser free mem for programs
float get_mem_pressure(){
	std::string token;
	std::ifstream file(MEMINFO);
	unsigned long totmem, freemem;
	int gotvals = 0;
	while(file >> token) {
		if(token == "MemTotal:") 
		{
			file >> totmem;
			gotvals += 1;
		}
		else if(token == "MemAvailable:")
		{
			file >> freemem;
			gotvals += 1;
		}
		if(gotvals == 2)
			break;
	}
	return (float)(totmem-freemem) /totmem;
}

bool toss_biased_coin()
{
    float mem_pressure = get_mem_pressure();
    srand(time(0));
    int ran = rand() % 1000;
    if(ran <= (int)mem_pressure*1000)
        return true;
    return false;
}
