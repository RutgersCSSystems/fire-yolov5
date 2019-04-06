#include <stdio.h> 
#include <sys/socket.h> 
#include <stdlib.h> 
#include <sys/time.h>
#include <netinet/in.h> 
#include <string.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <pthread.h>
 
#define PORT 8080

#define TOTAL 32768
#define THREAD_NUM 4
#define SIZE 4096
#define ITER 32768*64

void* send_msg(void *arg){
	uint16_t thread_num = (uint16_t)atoi(arg);
	int sock = 0;
	int i = 0;
	struct sockaddr_in serv_addr;
	char buffer[SIZE];
	char rec[SIZE];
	memset(buffer, 0x31, SIZE);

	//printf("client checkpoint 1\n");

	if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) { 
        printf("\n Socket creation error \n"); 
        return NULL; 
    } 
   
    memset(&serv_addr, '0', sizeof(serv_addr)); 
   
    serv_addr.sin_family = AF_INET;

	serv_addr.sin_port = htons( PORT );

    // Convert IPv4 and IPv6 addresses from text to binary form 
    if(inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr)<=0) { 
        printf("\nInvalid address/ Address not supported \n"); 
        return NULL; 
    } 

	//printf("client checkpoint 2\n");

	if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) { 
		printf("\nConnection Failed \n"); 
		return NULL; 
	}
	
	//printf("client checkpoint 3\n");

	for (i = 0; i < ITER; ++i) {
		send(sock, buffer, SIZE, 0);
		//printf("sending %c\n", buffer[0]);
		//sleep(1);
		//recv(sock, rec, SIZE, 0);
		//printf("receiving %c\n", rec[0]);
	}

	//printf("client thread %d finishes\n", thread_num);

	//shutdown(sock, 2);
} 

int main(int argc, char const *argv[]) 
{ 
	int i = 0;
	char tmp[5] = "";
	pthread_t tr[THREAD_NUM];
	struct timeval t0, t1;
	double t;
	
	sleep(2);

	gettimeofday(&t0, NULL);

	for (i = 0; i < THREAD_NUM; ++i) {
		sprintf(tmp, "%d", i);
		pthread_create(&tr[i], NULL, send_msg, tmp);
	}

	for (i = 0; i < THREAD_NUM; ++i) {
		pthread_join(tr[i], NULL);
	}

	gettimeofday(&t1, NULL);

	t = (t1.tv_sec*1000 + t1.tv_usec/1000) - (t0.tv_sec*1000 + t0.tv_usec/1000);
	
	printf("Total time for Client is %3.3lf ms\n", t);
	printf("Aggregated Client Throughput is %3.3lf MB/s\n", (TOTAL * 1000) / t );

    return 0; 
} 
