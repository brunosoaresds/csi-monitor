#define TRUE 1
#define FALSE 0

#define KEEP_ALIVE_IDLE 1
#define KEEP_ALIVE_INTERVAL 1
#define KEEP_ALIVE_COUNT 10

int create_server_sock(int port);
int wai_for_client(int server_sock);
