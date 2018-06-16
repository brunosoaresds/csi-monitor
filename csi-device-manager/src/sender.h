/*
 * =====================================================================================
 *       Filename:  sender.h
 *
 *    Description:  Packets sender manager
 *        Version:  1.0
 *
 *         Author:  Bruno Soares da Silva
 *         Email :  <brunodasilva@inf.ufg.br>
 *   Organization:  LABORA - Universidade Federal de Goiás (UFG) - Brazil
 *
 *   Copyright (c)  LABORA - Universidade Federal de Goiás (UFG) - Brazil
 * =====================================================================================
 */
#define BUF_SIZE 2048
#define TRUE 1
#define FALSE 0

typedef struct {
	char send_buffer[BUF_SIZE];
	struct ether_header *eh;
	struct iphdr *iph;
	struct sockaddr_ll socket_address;
	int len;
} PACKET;

void *create_packets_sender(void *vargp);
struct ifreq get_interface_index(int rawsock, char *if_name);
struct ifreq get_interface_mac_address(int rawsock, char *if_name);
int create_raw_socket();
PACKET create_packet(struct ifreq if_idx, struct ifreq if_mac, unsigned int dst_addr[6]);
void send_packets(unsigned int DstAddr[6], unsigned int quantity_of_packets, unsigned int until_seconds,
                  char ifName[IFNAMSIZ]);
void stop_sending();