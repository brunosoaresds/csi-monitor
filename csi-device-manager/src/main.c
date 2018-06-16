#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <termios.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <errno.h>
#include <time.h>
#include <math.h>
#include <net/if.h>
#include <linux/if_packet.h>
#include <pthread.h>

#include "socket.h"
#include "sender.h"
#include "csi_collector.h"

int quit;
unsigned char data_buf[1500];

void sig_handler(int signo) {
    if (signo == SIGINT) {
        quit = 1;
	}
}

int main(int argc, char* argv[]) {
	/* check usage */
	if (argc < 2 || argc > 3) {
		printf("/*****************************************************************/\n");
		printf("/*   Usage: csi_device_manager <WLan interface> [port=3000]     */\n");
		printf("/*****************************************************************/\n");
		return 0;
	}

	/* Open socket server */
	u_int16_t   csi_buf_len;
	int port = 3000;
	int serverfd = 0, clientfd = 0;

	if(argc == 3) {
        port = atoi(argv[2]);
    }
	
	serverfd = create_server_sock(port);
	if(serverfd == -1) {
		printf("Could not start socket server, finishing application...\n");
		return 0;
	}
	printf("#Receiving data! Press Ctrl+C to quit!\n");

	quit = 0;
	char command_buffer[50];
	
	/* Send vars */
	char ifName[IFNAMSIZ];
	char input_buffer[100];
	unsigned int DstAddr[6];
	int i, quantity_of_packets, until_seconds;
	strcpy(ifName, argv[1]);

	/* Create thread what will control the packet storage into file and the packet sender */
	pthread_t tid_collector, tid_sender;
	pthread_create(&tid_collector, NULL, collect_csi_data, NULL);
	pthread_create(&tid_sender, NULL, create_packets_sender, NULL);

	/* Client connection and command processing */
	while(1) {
		printf("Waiting for client connection...\n");
		clientfd = wait_for_a_client(serverfd);
		if(clientfd == -1) {
			printf("Could not proceed with client connection, closing it...\n");
			close(clientfd);
			continue;
		}
		printf("Connection received...\n");
		
		while(1) {
			printf("Waiting for client command...\n");
			memset(&command_buffer[0], 0, sizeof(command_buffer));
			recv(clientfd, command_buffer, 45, 0);
			printf("Command received: %s\n", command_buffer);

			if(strcmp("GET_FILES", command_buffer) == 0) {
                int files_count = get_files_count();
                char **tmp_files = create_files_matrix();
                get_files(tmp_files);
                int i = 0;
                for(i = 0; i < files_count; i++) {
                  printf("[%d]- %s\n", i, tmp_files[i]);
                  write(clientfd, tmp_files[i], sizeof(char)*strlen(tmp_files[i]));
                }
			} else if(strcmp("SEND_PACKET", command_buffer) == 0) {
				// Receive destination mac address
				memset(&input_buffer[0], 0, sizeof(input_buffer));
				recv(clientfd, input_buffer, 17, 0);
				sscanf(input_buffer, "%x:%x:%x:%x:%x:%x", &DstAddr[0], &DstAddr[1], &DstAddr[2], &DstAddr[3],
				        &DstAddr[4], &DstAddr[5]);
				
				// Receive how much packets will be sent and loop size
				memset(&input_buffer[0], 0, sizeof(input_buffer));
				recv(clientfd, input_buffer, 95, 0);
				quantity_of_packets = atoi(strtok(input_buffer, "/"));
				until_seconds = atoi(strtok(NULL, "/"));
				
				// send packets...
				send_packets(DstAddr, quantity_of_packets, until_seconds, ifName);
			} else if(strcmp("STOP_SENDING", command_buffer) == 0) {
			    // Stopping...
			    stop_sending();
			} else {
				printf("Unknown command received, closing connection...\n");
				break;
			}
		}

		printf("Connection with client closed...\n");
		close(clientfd);

		if(quit == 1) {
			printf("Shutdown command received, finishing application...\n");
			break;
		}
	}

	return 0;
}

