#ifndef _DEBUG_H
#define _DEBUG_H

#include "mcu_proto.h"

void print_port_info(PORT_INFO *info);
void print_wan_info(WAN_INFO *info);
void print_wifi_info(WIFI_INFO *info);
void print_basic_info(BASIC_INFO *info);
void print_host_info(struct _host_info_single *info, int len);
void print_weather_info(WEATHER_INFO *info);
#endif