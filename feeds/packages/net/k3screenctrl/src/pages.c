#include <stdio.h>
#include <string.h>
#include <syslog.h>

#include "common.h"
#include "infocenter.h"
#include "mcu_proto.h"
#include "requests.h"

static int g_host_page = 0;
static PAGE g_current_page = PAGE_WAN;

struct _host_info_single *get_hosts() {
    return g_host_info_array;
}

static int get_hosts_count() { return g_host_info_elements; }

static void send_page_data(PAGE page) {
    switch (page) {
    case PAGE_UPGRADE_INFO:
    case PAGE_BASIC_INFO:
        request_update_basic_info(
            g_basic_info.product_name, g_basic_info.hw_version, g_basic_info.fw_version,
            g_basic_info.sw_version,g_basic_info.mac_addr_base);
        break;
    case PAGE_PORTS:
        request_update_ports(&g_port_info);
        break;
    case PAGE_WAN:
        request_update_wan(g_wan_info.is_connected, g_wan_info.tx_bytes_per_sec,
                           g_wan_info.rx_bytes_per_sec);
        break;
    case PAGE_WIFI:
        request_update_wifi(&g_wifi_info);
        break;
    case PAGE_HOSTS:
        request_update_hosts_paged(get_hosts(), get_hosts_count(),
                                   g_host_page * HOSTS_PER_PAGE);
        break;
    case PAGE_WEATHER:
	    request_update_weather(&g_weather_info);
		break;
    default:
        syslog(LOG_WARNING, "unknown page requested: %d\n", page);
        break;
    }
}

void page_send_initial_data() {
    send_page_data(PAGE_BASIC_INFO);
    send_page_data(PAGE_PORTS);
    send_page_data(PAGE_WAN);
    send_page_data(PAGE_WIFI);
    send_page_data(PAGE_HOSTS);
	send_page_data(PAGE_WEATHER);
    request_switch_page(PAGE_WAN);
}

/* Collect info by running scripts */
void page_update() {
    switch (g_current_page) {
    case PAGE_WAN:
        update_page_info(PAGE_WAN);
        update_page_info(PAGE_WIFI); // Shows STA count on WAN page
        break;
    default:
        update_page_info(g_current_page);
        break;
    }
}

/* Sends collected info to screen but do not switch to the page */
void page_refresh() {
    switch (g_current_page) {
    case PAGE_WAN:
        send_page_data(PAGE_WAN);
        send_page_data(PAGE_WIFI); // Shows STA count on WAN page
        break;
    default:
        send_page_data(g_current_page);
        break;
    }
}

void page_switch_to(PAGE page) {
    if (page >= PAGE_MIN && page <= PAGE_MAX) {
        g_current_page = page;
        g_host_page = 0;
        page_refresh();
        request_switch_page(g_current_page);
    }
}

void page_switch_next() {
    if (g_current_page != PAGE_HOSTS) {
        if (g_current_page < PAGE_MAX) {
            g_current_page++;
            page_refresh();
            request_switch_page(g_current_page);
        }
    } else {
        /* In PAGE_HOSTS */
        if (get_hosts_count() - (g_host_page + 1) * HOSTS_PER_PAGE > 0) {
            g_host_page++;
            page_refresh();
            request_switch_page(g_current_page);
        }
    }
}

void page_switch_prev() {
    if (g_current_page != PAGE_HOSTS) {
        if (g_current_page > PAGE_MIN) {
            g_current_page--;
            page_refresh();
            request_switch_page(g_current_page);
        }
    } else {
        /* In PAGE_HOSTS */
        if (g_host_page > 0) {
            g_host_page--;
        } else {
            g_current_page--;
        }
        page_refresh();
        request_switch_page(g_current_page);
    }
}
