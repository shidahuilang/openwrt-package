#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <syslog.h>

#include "common.h"

int write_file_int(const char *file, int number) {
    int fd = open(file, O_WRONLY);
    if (fd == -1) {
        syslog(LOG_ERR, "Could not open %s: %s\n", file, strerror(errno));
        return FAILURE;
    }

    if (dprintf(fd, "%d\n", number) < 0) {
        syslog(LOG_ERR, "Could not write to %d to %s: %s\n", number, file,
               strerror(errno));
        return FAILURE;
    }
    return SUCCESS;
}

int write_file_str(const char *file, const char *str) {
    int fd = open(file, O_WRONLY);
    if (fd == -1) {
        syslog(LOG_ERR, "Could not open %s: %s\n", file, strerror(errno));
        return FAILURE;
    }

    if (dprintf(fd, "%s\n", str) < 0) {
        syslog(LOG_ERR, "Could not write to %s to %s: %s\n", str, file,
               strerror(errno));
        return FAILURE;
    }
    return SUCCESS;
}

int path_exists(const char *path) {
    struct stat statbuf;

    if (stat(path, &statbuf) < 0) {
        return FAILURE;
    }

    return SUCCESS;
}
