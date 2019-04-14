#include <stdio.h> 
#include <sys/socket.h> 
#include <stdlib.h> 
#include <sys/time.h>
#include <netinet/in.h> 
#include <string.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <pthread.h>
 
#define PORT 8081

#define TOTAL 2048
#define THREAD_NUM 16
#define SIZE 4096
#define ITER 32768

pthread_t tr[THREAD_NUM];
int	counter[THREAD_NUM];

void* send_msg(void *arg){
	int thread_num = *((int*) arg);
	int sock = 0;
	int i = 0;
	struct sockaddr_in serv_addr;
	char buffer[SIZE];
	char rec[SIZE];
	memset(buffer, 0x31, SIZE);

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
 
	/*if (inet_pton(AF_INET, "128.105.145.29", &serv_addr.sin_addr)<=0) { 
		printf("\nInvalid address/ Address not supported \n"); 
		return NULL; 
	}*/

	if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) { 
		printf("\nConnection Failed \n"); 
		return NULL; 
	}

	printf("connect success\n");

	for (i = 0; i < ITER; ++i) {
		send(sock, buffer, SIZE, 0);
	}

	printf("client thread %d finishes\n", thread_num);

	//close(sock);

	/*if (thread_num < 15)
		pthread_join(tr[thread_num+1], NULL);*/
} 

int main(int argc, char const *argv[]) { 
	int i = 0;
	struct timeval t0, t1;
	double t;
	
	sleep(5);

	gettimeofday(&t0, NULL);

	for (i = 0; i < THREAD_NUM; ++i) {
		counter[i] = i;
		pthread_create(&tr[i], NULL, send_msg, &counter[i]);
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
