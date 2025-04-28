#include "SoftEtherBridge.h"
#include <openssl/ssl.h>

void softether_send_hello(SSL *ssl) {
    // SoftEther v4 HELLO packet structure
    unsigned char hello_packet[] = {
        0x00, 0x00, 0x00, 0x01, // Protocol version
        0x48, 0x45, 0x4C, 0x4C, 0x4F // HELLO
    };
    SSL_write(ssl, hello_packet, sizeof(hello_packet));
}

int softether_handle_redirect(SSL *ssl, char **new_host, int *new_port) {
    unsigned char buffer[256];
    int bytes = SSL_read(ssl, buffer, sizeof(buffer));
    
    if (bytes > 0 && buffer[0] == 0x52) { // 'R' for redirect
        *new_host = parse_host_from_packet(buffer);
        *new_port = parse_port_from_packet(buffer);
        return 1;
    }
    return 0;
}