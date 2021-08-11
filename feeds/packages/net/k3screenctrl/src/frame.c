#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

#include "checksum.h"
#include "common.h"
#include "mcu_proto.h"
#include "serial_port.h"

void (*g_frame_received_callback)(const unsigned char *frame, int len);

int frame_send(const unsigned char *data, int len) {
    /* Allocate max possible space (escape every byte, with header/trailer) */
    unsigned char *buf = (unsigned char *)malloc(len * 2 + 4);
    if (buf <= 0) {
        syslog(LOG_ERR, "unable to allocate memory for TX buffer: %s",
               strerror(errno));
        return FAILURE;
    }
    bzero(buf, len * 2 + 4);

    /* Stage 1. Add header */
    int buf_pos = 0;
    buf[buf_pos++] = FRAME_HEADER; /* Header */

/* Stage 2. Copy data, escaping FRAME_HEADER/TRAILER/ESCAPE */
#define ESCAPE_AND_APPEND_BYTE(byte)                                           \
    do {                                                                       \
        if ((byte) == FRAME_HEADER || (byte) == FRAME_TRAILER ||               \
            (byte) == FRAME_ESCAPE) {                                          \
            buf[buf_pos++] = FRAME_ESCAPE;                                     \
        }                                                                      \
        buf[buf_pos++] = (byte);                                               \
    } while (0);

    for (int data_pos = 0; data_pos < len; data_pos++) {
        ESCAPE_AND_APPEND_BYTE(data[data_pos]);
    }

    /* Stage 3. Checksum with the same escaping procedure */
    unsigned short checksum = crc_xmodem(data, len);
    ESCAPE_AND_APPEND_BYTE(checksum & 0xff);
    ESCAPE_AND_APPEND_BYTE((checksum & 0xff00) >> 8);

    /* Stage 4. Add trailer */
    buf[buf_pos++] = FRAME_TRAILER;

    int ret = serial_write(buf, buf_pos);
    free(buf);
    return ret;
}

void frame_set_received_callback(void (*func)(const unsigned char *, int)) {
    g_frame_received_callback = func;
}

static void frame_notify_received(const unsigned char *frame_buf, int len) {
    unsigned char frame[2048];
    unsigned char frame_pos = 0;

    /* Unescape */
    int is_escaped = 0;
    int is_in_frame = 0;
    for (int input_pos = 0; input_pos < len; input_pos++) {
        if (is_escaped) {
            if (is_in_frame) {
                frame[frame_pos++] = frame_buf[input_pos];
            }
            is_escaped = 0;
            continue;
        }

        switch (frame_buf[input_pos]) {
        case FRAME_ESCAPE:
            is_escaped = 1;
            break;
        case FRAME_HEADER:
            is_in_frame = 1;
            break;
        case FRAME_TRAILER:
            is_in_frame = 0; /* Loop should end after this */
            break;
        default:
            if (is_in_frame) {
                frame[frame_pos++] = frame_buf[input_pos];
            }
        }
    }

    /* frame[] should contain clean data with checksum but without header and
     * trailer */
    unsigned short my_cksum = crc_xmodem(frame, frame_pos - 2);
    unsigned short msg_cksum =
        *(unsigned short *)(frame + frame_pos - 2); // Same, little endian
    if (my_cksum == msg_cksum) {
        if (g_frame_received_callback) {
            g_frame_received_callback(frame, frame_pos - 2);
        }
    } else {
        syslog(LOG_WARNING, "Checksum error! Got %04hx but expected %04hx\n",
               msg_cksum, my_cksum);
    }
}

void frame_notify_serial_recv() {
    static unsigned char g_serial_recv_buf[2048];
    static int g_recv_buf_pos = 0;

    /* Read into this buffer */
    int recv_len = serial_read(g_serial_recv_buf + g_recv_buf_pos,
                               sizeof(g_serial_recv_buf) - g_recv_buf_pos);
    g_recv_buf_pos += recv_len;

    /* Search for end mark and notify if the frame has ended */
    unsigned char *search_pos = g_serial_recv_buf;
    unsigned char *last_trailer;
    int remaining_search_range = g_recv_buf_pos;

    /* Search for FRAME_TRAILER within received data */
    while (remaining_search_range > 0 &&
           (last_trailer = memchr(search_pos, FRAME_TRAILER,
                                  remaining_search_range)) != NULL) {
        if (*(last_trailer - 1) != FRAME_ESCAPE) {
            /* Not escaped. This is the end of the frame */
            frame_notify_received(g_serial_recv_buf,
                                  last_trailer - g_serial_recv_buf + 1);
            g_recv_buf_pos = 0;
            break; /* Do not support continous frames */
        } else {
            /* Escaped. Continue search from this place */
            search_pos = last_trailer + 1;
            remaining_search_range =
                g_recv_buf_pos - (search_pos - g_serial_recv_buf);
        }
    }
}
