CC=gcc
FLAGS=-g -o
LINK=-L../../shared_libs/construct/ -lmigration

Target: socket_server socket_client socket_server_multi socket_client_multi

socket_server:
	$(CC) $(FLAGS) socket_server socket_server.c $(LINK)

socket_client:
	$(CC) $(FLAGS) socket_client socket_client.c $(LINK)

socket_server_multi:
	$(CC) $(FLAGS) socket_server_multi socket_server_multi.c $(LINK) -lpthread

socket_client_multi:
	$(CC) $(FLAGS) socket_client_multi socket_client_multi.c $(LINK) -lpthread

clean:
	rm socket_server socket_client socket_server_multi socket_client_multi
