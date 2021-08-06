#include <stdio.h>

#include "mcu_proto.h"

void print_port_info(PORT_INFO *info) {
    printf("PORT_INFO at %p:\n"
           "  LAN1 = %hhu\n"
           "  LAN2 = %hhu\n"
           "  LAN3 = %hhu\n"
           "  WAN = %hhu\n"
           "  USB = %hhu\n",
           info, info->eth_port1_conn, info->eth_port2_conn,
           info->eth_port3_conn, info->eth_wan_conn, info->usb_conn);
}

void print_wan_info(WAN_INFO *info) {
    printf("WAN_INFO at %p:\n"
           "  Connnected = %u\n"
           "  Upload = %u B/s\n"
           "  Download = %u B/s\n",
           info, info->is_connected, info->tx_bytes_per_sec,
           info->rx_bytes_per_sec);
}

static void print_wifi_info_single(struct _wifi_radio_info *info) {
    printf("  Single WiFi Radio info at %p:\n"
           "    SSID = %s\n"
           "    PSK = %s\n"
           "    Enabled = %hhu\n"
           "    STA Count = %hhu\n",
           info, info->ssid, info->psk, info->enabled, info->sta_count);
}

void print_wifi_info(WIFI_INFO *info) {
    printf("WIFI_INFO at %p:\n"
           "  Band mix = %d\n",
           info, info->band_mix);
    print_wifi_info_single(&info->wl_24g_info);
    print_wifi_info_single(&info->wl_5g_info);
    print_wifi_info_single(&info->wl_visitor_info);
}

void print_basic_info(BASIC_INFO *info) {
    printf("BASIC_INFO at %p:\n"
           "  Product Name = %s\n"
           "  HW Version = %s\n"
           "  FW Version = %s\n"
           "  SW Version = %s\n"
           "  MAC Address = %s\n",
           info, info->product_name, info->hw_version, info->fw_version,
           info->sw_version, info->mac_addr_base);
}

void print_host_info(struct _host_info_single *info, int len) {
    for (int i = 0; i < len; i++) {
        printf("Single host info at %p:\n"
               "  Upload = %d B/s\n"
               "  Download = %d B/s\n"
               "  Name = %s\n"
               "  Logo Index = %d\n",
               &info[i], info[i].upload_Bps, info[i].download_Bps,
               info[i].hostname, info[i].logo);
    }
}

void print_weather_info(WEATHER_INFO *info) {
	printf("WEATHER_INFO at %p:\n"
	       "  city = %s\n"
           "  temp = %s\n"
           "  date = %s\n"
           "  time = %s\n"
           "  weather = %hhu\n"
           "  week = %hhu\n"
           "  error = %hhu\n",
           info, info->city, info->temp,
           info->date, info->time, info->weather, info->week, info->error);
}

static void print_buf(const unsigned char *buf, int len) {
    printf("RCVD %d bytes\n", len);

    for (int i = 0; i < len; i++) {
        printf("0x%hhx ", buf[i]);
    }
    printf("\n");
}