#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <arpa/inet.h>

#include "socket.h"

int enable_keepalive(int sock) {
	setsockopt(sock, SOL_SOCKET, SO_KEEPALIVE, &(int){ TRUE }, sizeof(int));
	setsockopt(sock, IPPROTO_TCP, TCP_KEEPIDLE, &(int){ KEEP_ALIVE_IDLE }, sizeof(int));
	setsockopt(sock, IPPROTO_TCP, TCP_KEEPINTVL, &(int){ KEEP_ALIVE_INTERVAL }, sizeof(int));
	setsockopt(sock, IPPROTO_TCP, TCP_KEEPCNT, &(int){ KEEP_ALIVE_COUNT }, sizeof(int));
}

int create_server_sock(int port) {
	int serverfd = 0;
	struct sockaddr_in serv_addr;
	memset(&serv_addr, '0', sizeof(serv_addr));

	serv_addr.sin_family = AF_INET;
	serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	serv_addr.sin_port = htons(port);

	serverfd = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if(serverfd == -1) {
		printf("Could not create socket\n");
		return -1;
	}

	if(setsockopt(serverfd, SOL_SOCKET, SO_REUSEADDR, &(int){ 1 }, sizeof(int)) == -1) {
		printf("Could not set socket reusable\n");
		return -1;
	}

	if(bind(serverfd, (struct sockaddr*)&serv_addr, sizeof(serv_addr)) == -1) {
		printf("Could not bind socket\n");
		return -1;
	}
	
	if(listen(serverfd, 1) == -1) {
		printf("Could not listen socket\n");
		return -1;
	}
	
	return serverfd;
}

int wai_for_client(int server_sock) {
	int clientfd = 0;
	clientfd = accept(server_sock, (struct sockaddr*)NULL, NULL);
	
	if(enable_keepalive(clientfd) == -1) {
		printf("Could not enable keep alive on client connection\n");
		return -1;
	}
	
	return clientfd;
}
