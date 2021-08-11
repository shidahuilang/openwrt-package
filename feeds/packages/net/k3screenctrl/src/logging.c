#include "logging.h"

void syslog_setup(int print_stderr) {
    int log_options = LOG_CONS | LOG_PID;
    if (print_stderr)
        log_options |= LOG_PERROR;

    openlog(LOG_IDENT, log_options, LOG_USER);
}

void syslog_stop() { closelog(); }