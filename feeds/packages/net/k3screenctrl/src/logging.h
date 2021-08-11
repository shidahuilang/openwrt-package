#ifndef _LOGGING_H
#define _LOGGING_H

#include <syslog.h>

#define LOG_IDENT "K3Screen"

void syslog_setup();
void syslog_stop();
#endif
