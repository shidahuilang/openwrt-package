#ifndef _HANDLERS_H
#define _HANDLERS_H

#include "mcu_proto.h"

typedef struct _response_handler {
    RESPONSE_TYPE type;
    void (*handler)(const unsigned char *payload, int len);
} RESPONSE_HANDLER;

#endif
