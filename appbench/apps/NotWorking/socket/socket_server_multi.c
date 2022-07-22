#include <unistd.h> 
#include <stdio.h> 
#include <sys/time.h>
#include <sys/socket.h> 
#include <stdlib.h> 
#include <netinet/in.h> 
#include <string.h> 
#include <pthread.h>

#define PORT 8081

#define TOTAL 2048
#define THREAD_NUM 16
#define SIZE 4096
#define ITER 32768

pthread_t tr[THREAD_NUM];
int	counter[THREAD_NUM];
int client_sock[THREAD_NUM];

// the thread function
void *connection_handler(void *);
 
int main(int argc , char *argv[]) {
	int socket_desc, c;
	struct sockaddr_in server , client;
	int i = 0;

	struct timeval t0, t1;
	double t;

	//Create socket
	socket_desc = socket(AF_INET , SOCK_STREAM , 0);
	if (socket_desc == -1) {
		printf("Could not create socket");
	}
	puts("Socket created");
     
	//Prepare the sockaddr_in structure
	server.sin_family = AF_INET;
	server.sin_addr.s_addr = INADDR_ANY;
	server.sin_port = htons( PORT );
     
	//Bind
	if ( bind(socket_desc,(struct sockaddr *)&server , sizeof(server)) < 0) {
		//print the error message
		perror("bind failed. Error");
		return -1;
	}
	puts("bind done");
     
    //Listen
	listen(socket_desc, THREAD_NUM);

	//Accept and incoming connection
	puts("Waiting for incoming connections...");
	c = sizeof(struct sockaddr_in);
	pthread_t thread_id;
	
	gettimeofday(&t0, NULL);

	//while ((client_sock[i] = accept(socket_desc, (struct sockaddr *)&client, (socklen_t*)&c)) ) {
	for (i = 0; i < THREAD_NUM; ++i) {
		client_sock[i] = accept(socket_desc, (struct sockaddr *)&client, (socklen_t*)&c);

		puts("Connection accepted");
         
		counter[i] = i;
		if (pthread_create(&tr[i], NULL, connection_handler, &counter[i]) < 0) {
			perror("could not create thread");
			return -1;
		}     
    }
 
	for (i = 0; i < THREAD_NUM; ++i) {
		pthread_join(tr[i] , NULL);
	}

	gettimeofday(&t1, NULL);

	t = (t1.tv_sec*1000 + t1.tv_usec/1000) - (t0.tv_sec*1000 + t0.tv_usec/1000) - 5000;
	
	printf("Total time for Server is %3.3lf ms\n", t);
	printf("Aggregated Server Throughput is %3.3lf MB/s\n", (TOTAL * 1000) / t );

	/*for (i = 0; i < THREAD_NUM; ++i) {
		close(client_sock[i]);
	}*/
     
    return 0;
}
 
/*
 * This will handle connection for each client
 * */
void *connection_handler(void *arg) {
	//Get the socket descriptor
	int thread_num = *((int*) arg);
	int read_size;
	char client_message[SIZE];
	int i = 0;
     
	//Receive a message from client
	while((read_size = recv(client_sock[thread_num], client_message, SIZE, 0)) > 0);
     
	/*for (i = 0; i < ITER; ++i) {
		recv(sock, client_message, SIZE, 0);
		//read(new_socket , buffer, SIZE);
		//printf("receiving %c\n", buffer[0]);
		//sleep(1);
		//send(new_socket, hello, strlen(hello), 0);
		//printf("sending %c\n", hello[0]);
	}*/

	printf("finishes\n");    

	return 0;
} 
