/*
 * =====================================================================================
 *       Filename:  socket.h
 *
 *    Description:  Creates the server socket and handle clients connection.
 *        Version:  1.0
 *
 *         Author:  Bruno Soares da Silva
 *         Email :  <brunodasilva@inf.ufg.br>
 *   Organization:  LABORA - Universidade Federal de Goiás (UFG) - Brazil
 *
 *   Copyright (c)  LABORA - Universidade Federal de Goiás (UFG) - Brazil
 * =====================================================================================
 */
#define TRUE 1
#define FALSE 0

#define KEEP_ALIVE_IDLE 1
#define KEEP_ALIVE_INTERVAL 1
#define KEEP_ALIVE_COUNT 10

int create_server_sock(int port);
int wait_for_a_client(int server_sock);
