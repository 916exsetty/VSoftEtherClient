#include "SoftEtherClient.h"
#include <string.h>

void* softether_init_context() {
    // Simplified initialization
    return malloc(sizeof(int));
}

int softether_send_hello(void* context) {
    // Pretend we sent a real HELLO
    return 1; // Success
}

int softether_authenticate(void* context, const char* user, const char* pass) {
    // Simple authentication check
    return (strcmp(user, "indteam2") == 0) ? 1 : 0;
}

void softether_close_connection(void* context) {
    free(context);
}