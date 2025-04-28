// bridging header for swift to see the softether c client api
#include "libsoftether.h"
// declare the c wrapper functions we need
int se_initialize_client(void);
int se_connect_to_server(const char* host, int port);
int se_send_hello(void);
int se_receive_hello(void);
int se_authenticate_client(const char* username, const char* password);
int se_get_redirect_server(char* host_buf, int buf_len, int* out_port);
int se_establish_tunnel(int tunnel_index);
int se_dhcp_discover(void);
int se_dhcp_receive_offer(void);