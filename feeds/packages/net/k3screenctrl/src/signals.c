#include <errno.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <sys/signalfd.h>
#include <syslog.h>
#include <time.h>
#include <unistd.h>

#include "config.h"
#include "mcu_proto.h"
#include "pages.h"
#include "requests.h"

static int g_signal_fd;

int signal_setup() {
    sigset_t mask;

    sigemptyset(&mask);
    sigaddset(&mask, SIGALRM); // Timed update
    sigaddset(&mask, SIGTERM); // Router reboot
    sigaddset(&mask, SIGUSR1); // Factory reset
    sigaddset(&mask, SIGUSR2); // Firmware update

    /* Block in order to prevent default disposition */
    if (sigprocmask(SIG_BLOCK, &mask, NULL) == -1) {
        syslog(LOG_WARNING, "could not block signals: %s\n", strerror(errno));
    }

    g_signal_fd = signalfd(-1, &mask, 0);
    if (g_signal_fd < 0) {
        syslog(LOG_WARNING, "could not set up signal fd: %s\n",
               strerror(errno));
    }

    return g_signal_fd;
}

static time_t g_last_check_time;
void refresh_screen_timeout() { g_last_check_time = time(NULL); }

static void check_screen_timeout() {
    if (CFG->screen_timeout != 0 &&
        time(NULL) - g_last_check_time >= CFG->screen_timeout) {
        extern int g_is_screen_on;
        g_is_screen_on = 0; /* Do not process key messages - just wake up if there are any */
        request_notify_event(EVENT_SLEEP);
    }
}

void signal_notify() {
    struct signalfd_siginfo siginfo;
    if (read(g_signal_fd, &siginfo, sizeof(siginfo)) <= 0) {
        syslog(LOG_WARNING,
               "could not read from signalfd, signal ignored: %s\n",
               strerror(errno));
        return;
    }

    switch (siginfo.ssi_signo) {
    case SIGALRM:
        page_update();
        page_refresh();
        check_screen_timeout();
        alarm(CFG->update_interval);
        break;
    case SIGTERM:
        request_notify_event(EVENT_REBOOT);
        exit(0);
        break;
    case SIGUSR1:
        request_notify_event(EVENT_RESET);
        break;
    case SIGUSR2:
        request_notify_event(EVENT_UPGRADE);
        break;
    default:
        syslog(LOG_INFO, "someone forgot to add his signal (%d) handler here\n",
               siginfo.ssi_signo);
        break;
    }
}