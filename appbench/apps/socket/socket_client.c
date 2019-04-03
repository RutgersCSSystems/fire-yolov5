#include <stdio.h> 
#include <sys/socket.h> 
#include <stdlib.h> 
#include <netinet/in.h> 
#include <string.h>
#include <arpa/inet.h>
#include <unistd.h>
 
#define PORT 8080 
   
int main(int argc, char const *argv[]) 
{ 
    struct sockaddr_in address; 
    int sock = 0, valread; 
    struct sockaddr_in serv_addr; 
    char *hello = "Hello from client";
    //char *hello = argv[1];
    char buffer[1024] = {0}; 
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) { 
        printf("\n Socket creation error \n"); 
        return -1; 
    } 
   
    memset(&serv_addr, '0', sizeof(serv_addr)); 
   
    serv_addr.sin_family = AF_INET; 
    serv_addr.sin_port = htons(PORT); 
       
    // Convert IPv4 and IPv6 addresses from text to binary form 
    if(inet_pton(AF_INET, "127.0.0.1", &serv_addr.sin_addr)<=0) { 
        printf("\nInvalid address/ Address not supported \n"); 
        return -1; 
    } 
   
	if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) { 
		printf("\nConnection Failed \n"); 
		return -1; 
	}
	
	for (int i = 0; i < 100; ++i) {
		char num[5] = "";
		char msg[24] = "Hello from client ";
		sprintf(num, "%d", i);
		strcat(msg, num);

		//send(sock, hello, strlen(hello), 0);
		send(sock, msg, strlen(msg), 0);
		
		printf("Client send: %s\n", hello);
		sleep(1);
 
		/*valread = recv(sock , buffer, 1024, 0); 
		printf("Client receive: %s\n", buffer);*/
	}    

    //sleep(1);

    return 0; 
} 
