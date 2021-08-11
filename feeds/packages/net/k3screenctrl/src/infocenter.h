#ifndef _INFOCENTER_H
#define _INFOCENTER_H

#include "mcu_proto.h"

int update_page_info(PAGE page);
int update_all_info();
int print_all_info();

extern BASIC_INFO g_basic_info;
extern PORT_INFO g_port_info;
extern WAN_INFO g_wan_info;
extern WIFI_INFO g_wifi_info;
extern struct _host_info_single *g_host_info_array;
extern unsigned int g_host_info_elements;
extern WEATHER_INFO g_weather_info;
#endif