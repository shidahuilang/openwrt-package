#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

#include "scripts.h"

char *script_get_output(const char *script) {
    char *ret = NULL;
    FILE *fp = popen(script, "r");
    if (fp == NULL) {
        syslog(LOG_ERR, "could not get output stream from \"%s\": %s\n", script,
               strerror(errno));
        goto null_exit;
    }

    ret = (char *)malloc(SCRIPT_OUTPUT_BUFFER_SIZE);
    if (ret < 0) {
        syslog(LOG_ERR, "could not allocate memory for command output: %s\n",
               strerror(errno));
        goto close_exit;
    }

    if (fread(ret, 1, SCRIPT_OUTPUT_BUFFER_SIZE, fp) == 0) {
        syslog(LOG_ERR, "could not read from stream: %s\n", strerror(errno));
        free(ret);
        ret = NULL;
    }

close_exit:
    pclose(fp);
null_exit:
    return ret;
}