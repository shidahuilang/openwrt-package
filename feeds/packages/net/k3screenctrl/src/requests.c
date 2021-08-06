#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

#include "common.h"
#include "frame.h"
#include "mcu_proto.h"
#include "serial_port.h"

static int request_send_raw(REQUEST_TYPE type, const void *data, int len) {
    unsigned char *cmdbuf = (unsigned char *)malloc(len + 2);
    if (cmdbuf < 0) {
        syslog(LOG_WARNING,
               "Could not allocate buffer for new request, drop it: %s\n",
               strerror(errno));
        return FAILURE;
    }

    bzero(cmdbuf, len + 2);
    cmdbuf[0] = PAYLOAD_HEADER;
    cmdbuf[1] = type;
    memmove(cmdbuf + 2, data, len);

    int ret = frame_send(cmdbuf, len + 2);
    free(cmdbuf);
    return ret;
}

int request_mcu_version() {
    return request_send_raw(REQUEST_GET_MCU_VERSION, NULL, 0);
}

int request_switch_page(PAGE page) {
    return request_send_raw(REQUEST_SWITCH_PAGE, &page, 4);
}

int request_notify_event(EVENT event) {
    return request_send_raw(REQUEST_NOTIFY_EVENT, &event, 4);
}

int request_update_wan(int is_connected, int tx_Bps, int rx_Bps) {
    WAN_INFO waninfo;
    bzero(&waninfo, sizeof(waninfo));
    waninfo.is_connected = is_connected;
    waninfo.tx_bytes_per_sec = tx_Bps;
    waninfo.rx_bytes_per_sec = rx_Bps;

    return request_send_raw(REQUEST_UPDATE_WAN, &waninfo, sizeof(waninfo));
}

int request_update_basic_info(const char *prod_name, const char *hw_ver,
                              const char *fw_ver, const char *sw_ver, const char *mac_addr) {
    BASIC_INFO basic_info;
    bzero(&basic_info, sizeof(basic_info));

#define ARRAY_SIZED_STRCPY(dst, src) strncpy((dst), (src), sizeof((dst)));
    ARRAY_SIZED_STRCPY(basic_info.product_name, prod_name);
    ARRAY_SIZED_STRCPY(basic_info.hw_version, hw_ver);
    ARRAY_SIZED_STRCPY(basic_info.fw_version, fw_ver);
	ARRAY_SIZED_STRCPY(basic_info.sw_version, sw_ver);
    ARRAY_SIZED_STRCPY(basic_info.mac_addr_base, mac_addr);

    return request_send_raw(REQUEST_UPDATE_BASIC_INFO, &basic_info,
                            sizeof(basic_info));
}

/* Too many parameters. Fill the struct yourself */
int request_update_wifi(WIFI_INFO *wifi_info) {
    return request_send_raw(REQUEST_UPDATE_WIFI, wifi_info, sizeof(WIFI_INFO));
}

int request_update_ports(PORT_INFO *port_info) {
    return request_send_raw(REQUEST_UPDATE_PORTS, port_info, sizeof(PORT_INFO));
}

int request_update_hosts_paged(struct _host_info_single hosts[], int len,
                               int start) {
    int ret = 0, copylen;
    HOST_INFO info;
    bzero(&info, sizeof(HOST_INFO));

    copylen = len - start;
    copylen = copylen > HOSTS_PER_PAGE ? HOSTS_PER_PAGE : copylen;

    info.total_hosts = len;
    info.current_page_index = start / HOSTS_PER_PAGE;
    for (int i = 0; i < copylen; i++) {
        memmove(&info.host_info[i], &hosts[start + i],
                sizeof(struct _host_info_single));
    }

    ret |=
        request_send_raw(REQUEST_UPDATE_HOSTS_PAGED, &info, sizeof(HOST_INFO));
    return ret;
}
int request_update_weather(WEATHER_INFO *weather_info) {
	    return request_send_raw(REQUEST_UPDATE_WEATHER, weather_info, sizeof(WEATHER_INFO));
}
