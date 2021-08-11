#ifndef _FRAME_TX_H
#define _FRAME_TX_H

/*
 * Send payload to serial port.
 * Only raw data (PAYLOAD_*) needs to be given, header &
 * trailer & escaping will be added automatically.
 */
int frame_send(const unsigned char* data, int len);

/*
 * Callback when a complete frame is received.
 *
 * The prototype is:
 * void callback(const unsigned char* frame, int len);
 *
 * The `frame` does not contain FRAME_* (unescaped & stripped).
 */
void frame_set_received_callback(void (*func)(const unsigned char*, int));

/*
 * Should be set in serial_set_pollin_callback()
 */
void frame_notify_serial_recv();
#endif
