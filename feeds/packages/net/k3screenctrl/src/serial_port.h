#ifndef _SERIAL_PORT_H
#define _SERIAL_PORT_H

#define SERIAL_POLL_INTERVAL_MS 500

/*
 * Setup serial port at given path
 *
 * Returns: serial fd, or -1 for failure
 */
int serial_setup(const char *dev_path);

/*
 * Close the port
 */
void serial_close();

/*
 * Self-explanatory
 *
 * Returns: how many bytes are actually written / read
 */
int serial_write(const unsigned char *data, int len);
int serial_read(unsigned char *buf, int maxlen);

#endif
