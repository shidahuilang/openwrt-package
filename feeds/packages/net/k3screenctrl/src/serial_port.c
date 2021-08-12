#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>

#include "common.h"
#include "logging.h"
#include "serial_port.h"

static int g_serial_fd = -1;

int serial_setup(const char *dev_path) {
    struct termios serial_termios;

    g_serial_fd = open(dev_path, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (g_serial_fd == -1) {
        syslog(LOG_CRIT, "could not open %s\n", dev_path);
        return -1;
    }

    if (tcgetattr(g_serial_fd, &serial_termios)) {
        syslog(LOG_ERR, "could not get attrs from serial fd: %s\n",
               strerror(errno));
        serial_close();
        return -1;
    }

    /* 115200 */
    cfsetspeed(&serial_termios, B115200);

    /* Noncanonical mode, no echo */
    serial_termios.c_lflag &= ~(ISIG | ICANON | ECHO | ECHOE);

    /* No XON/XOFF flow control */
    serial_termios.c_iflag &= ~(INPCK | INLCR | ICRNL | IXON | IXANY | IXOFF);

    /* 8-N-1 */
    serial_termios.c_cflag &= ~(CSIZE | CSTOPB | PARENB);
    serial_termios.c_cflag |= CS8 | CREAD | CLOCAL;

    /* No output processing */
    serial_termios.c_oflag &= ~(OPOST | ONLCR | OCRNL);

    /* Use select() to determine if there is data */
    serial_termios.c_cc[VTIME] = 0;
    serial_termios.c_cc[VMIN] = 0;

    tcflush(g_serial_fd, TCIFLUSH);
    if (tcsetattr(g_serial_fd, TCSANOW, &serial_termios)) {
        syslog(LOG_ERR, "could not set attrs for serial fd: %s\n",
               strerror(errno));
        serial_close();
        return -1;
    }

    return g_serial_fd;
}

void serial_close() { close(g_serial_fd); }

int serial_write(const unsigned char *data, int len) {
    return write(g_serial_fd, data, len);
}

int serial_read(unsigned char *buf, int maxlen) {
    return read(g_serial_fd, buf, maxlen);
}
