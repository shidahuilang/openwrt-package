#ifndef _MCU_PROTO_H
#define _MCU_PROTO_H

/*
 * Frame structure:
 *
 * FRAME_HEADER | PAYLOAD_HEADER | PAYLOAD_TYPE | PAYLOAD | FRAME_TRAILER
 *
 * PAYLOAD_TYPE can be one of the item in REQUEST_TYPE (Tx) or RESPONSE_TYPE
(Rx)
 * 0x01, 0x04 and 0x10 in PAYLOAD_* needs to be escaped by FRAME_ESCAPE.
 *
 * Actually there are frames with 0x01 and 0x02 as PAYLOAD_HEADER. Maybe this
kind of
 * frames is only used when communicating with bootloader. We do not need them
here
 * since we are not upgrading the bootloader.
 */

#define FRAME_HEADER 0x01
#define FRAME_TRAILER 0x04
#define FRAME_ESCAPE 0x10
#define PAYLOAD_HEADER 0x30

typedef enum _request_type {
    REQUEST_GET_MCU_VERSION = 1,
    REQUEST_SWITCH_PAGE = 4,
    REQUEST_UPDATE_PORTS,
    REQUEST_UPDATE_WAN,
    REQUEST_UPDATE_WIFI,
    REQUEST_UPDATE_HOSTS_PAGED,
    REQUEST_UPDATE_BASIC_INFO,
    REQUEST_NOTIFY_EVENT,
    REQUEST_UPDATE_WEATHER
} REQUEST_TYPE;

/* REQUEST_NOTIFY_EVENT */
typedef enum _event {
    EVENT_WIFI_ON = 0,
    EVENT_WIFI_OFF,
    EVENT_24G_ON,
    EVENT_24G_OFF,
    EVENT_5G_ON,
    EVENT_5G_OFF,
    EVENT_WISP_ON,
    EVENT_WISP_OFF,
    EVENT_WAKEUP = 9,
    EVENT_SLEEP,
    EVENT_RESTORE_BACKUP,
    EVENT_UPGRADE,
    EVENT_REBOOT,
    EVENT_RESET,
    EVENT_WIFI_ON_2, /* Not known */
} EVENT;

typedef enum _response_type {
    RESPONSE_MCU_VERSION = 1,
    RESPONSE_KEY_PRESS = 3
} RESPONSE_TYPE;

/* RESPONSE_MCU_VERSION */
typedef struct _mcu_version {
    unsigned short patch_ver;
    unsigned char minor_ver;
    unsigned char major_ver;
} MCU_VERSION;

/* RESPONSE_KEY_PRESS */
typedef enum _key_code {
    KEY_LEFT_SHORT = 1,
    KEY_LEFT_LONG = 3,
    KEY_RIGHT_SHORT = 4,
    KEY_RIGHT_LONG = 6,
    KEY_MIDDLE_SHORT = 7,
    KEY_MIDDLE_LONG = 9
} KEY_CODE;

/* REQUEST_SWITCH_PAGE */
typedef enum _page {
    PAGE_UPGRADE_INFO = 1,
    PAGE_BASIC_INFO,
    PAGE_PORTS,
    PAGE_WAN,
    PAGE_WEATHER,
    PAGE_WIFI,
    PAGE_HOSTS
} PAGE;

#define PAGE_MIN PAGE_UPGRADE_INFO
#define PAGE_MAX PAGE_HOSTS

/* REQUEST_UPDATE_PORTS */
typedef struct _port_info {
    unsigned char eth_port1_conn; // Switch port 1
    unsigned char eth_port2_conn; // Switch port 0
    unsigned char eth_port3_conn; // Switch port 2
    unsigned char PAD1;
    unsigned char eth_wan_conn; // Switch port 3
    unsigned char usb_conn;
    unsigned char PAD2[2];
} PORT_INFO;

/* REQUEST_UPDATE_WAN */
typedef struct _wan_info {
    unsigned int is_connected;
    unsigned int tx_bytes_per_sec;
    unsigned int rx_bytes_per_sec;
} WAN_INFO;

struct _wifi_radio_info {
    char ssid[64]; /* GBK */
    char psk[64];
    unsigned char enabled;
    unsigned char sta_count;
    unsigned char PAD[2];
};

/* REQUEST_UPDATE_WIFI */
typedef struct _wifi_info {
    unsigned int band_mix; /* This affects page 3 and page 4 */
    struct _wifi_radio_info wl_24g_info;
    struct _wifi_radio_info wl_5g_info;
    struct _wifi_radio_info wl_visitor_info;
} WIFI_INFO;

/* REQUEST_UPDATE_HOSTS_PAGED */
struct _host_info_single {
    unsigned int upload_Bps;
    unsigned int download_Bps;
    char hostname[36];
    unsigned int logo;
};

#define HOSTS_PER_PAGE 5

typedef struct _host_info {
    unsigned char total_hosts;
    unsigned char current_page_index;
    unsigned char PAD[2];
    struct _host_info_single host_info[HOSTS_PER_PAGE];
} HOST_INFO;

/* REQUEST_UPDATE_BASIC_INFO */
typedef struct _basic_info {
    char product_name[8];
    char hw_version[8];
    char fw_version[24];
    char sw_version[24];
    char mac_addr_base[18];
} BASIC_INFO;
/* REQUEST_UPDATE_WEATHER */
typedef struct _weather_info {
	char city[32]; // city
	char temp[4]; // temp
	char date[11]; // date
	char time[6]; // time
	unsigned char weather; // weather_code
	unsigned char week; //0 1 2 3 4 5 6
	unsigned char error; //0
} WEATHER_INFO;

#endif
