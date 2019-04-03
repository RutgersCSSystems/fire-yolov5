#include <unistd.h> 
#include <stdio.h> 
#include <sys/time.h>
#include <sys/socket.h> 
#include <stdlib.h> 
#include <netinet/in.h> 
#include <string.h> 
#include <pthread.h>

#define PORT 8080

#define THREAD_NUM 16
#define SIZE 4096
#define ITER 32768

//the thread function
void *connection_handler(void *);
 
int main(int argc , char *argv[])
{
    int socket_desc , client_sock[THREAD_NUM] , c;
    struct sockaddr_in server , client;
	int i = 0;

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
        return 1;
    }
    puts("bind done");
     
    //Listen
    listen(socket_desc , 3);

    //Accept and incoming connection
    puts("Waiting for incoming connections...");
    c = sizeof(struct sockaddr_in);
	pthread_t thread_id;
	
    //while ( (client_sock = accept(socket_desc, (struct sockaddr *)&client, (socklen_t*)&c)) ) {
	for (i = 0; i < THREAD_NUM; ++i) {
		client_sock[i] = accept(socket_desc, (struct sockaddr *)&client, (socklen_t*)&c);

        puts("Connection accepted");
         
        if (pthread_create(&thread_id, NULL, connection_handler, (void*) &client_sock[i]) < 0) {
            perror("could not create thread");
            return 1;
        }
         
        //Now join the thread , so that we dont terminate before the thread
        //pthread_join(thread_id , NULL);
    }
     
	for (i = 0; i < THREAD_NUM; ++i) {
		pthread_join(thread_id , NULL);
		close(client_sock[i]);
	}

    if (client_sock < 0) {
        perror("accept failed");
        return 1;
    }
     
    return 0;
}
 
/*
 * This will handle connection for each client
 * */
void *connection_handler(void *socket_desc) {
    //Get the socket descriptor
    int sock = *(int*)socket_desc;
    int read_size;
    char client_message[SIZE];
	int i = 0;
     
    //Receive a message from client
    while((read_size = recv(sock, client_message, SIZE, 0)) > 0);
     
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
