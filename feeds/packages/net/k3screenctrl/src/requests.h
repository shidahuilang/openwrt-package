#ifndef _REQUESTS_H
#define _REQUESTS_H

#include "mcu_proto.h"

int request_mcu_version();
int request_switch_page(PAGE page);
int request_notify_event(EVENT event);
int request_update_wan(int is_connected, int tx_bps, int rx_bps);
int request_update_basic_info(const char *prod_name, const char *hw_ver,
                              const char *fw_ver, const char *sw_ver, const char *mac_addr);

/**
 * Fill in the structures yourself.
 */
int request_update_wifi(WIFI_INFO *wifi_info);
int request_update_ports(PORT_INFO *port_info);

/**
 * This function sends `min(maxlen, HOSTS_PER_PAGE)` items in hosts[].
 * You need to call this multiple times if you have more than
 * HOSTS_PER_PAGE hosts.
 *
 * len: number of elements in hosts[]
 * start: send elements beginning from this position in hosts[]
 *
 * The page number will be calculated on the basis of `start`.
 *
 * E.g. if you have 13 hosts, you need to call functions in this sequence:
 *
 * request_update_hosts_paged(hosts, 13, 0);
 * request_switch_page(5);
 * request_update_hosts_paged(hosts, 13, 5);
 * request_switch_page(5);
 * request_update_hosts_paged(hosts, 13, 10);
 * request_switch_page(5);
 */
int request_update_hosts_paged(struct _host_info_single hosts[], int len,
                               int start);
int request_update_weather(WEATHER_INFO *weather_info);
#endif
