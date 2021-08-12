#ifndef _CONFIG_H
#define _CONFIG_H

typedef struct _config {
    /**
     * This script will be called in order to get basic info
     * such as HW/SW version, MAC address, model etc.
     *
     * Expected output format (one line for each field):
     * MODEL
     * HW version
     * FW version
     * MAC address
     *
     * Example:
     * K3
     * A1
     * r3921
	 * r3921
     * 02:00:00:00:00:00
     */
    char *basic_info_script;
#define DEFAULT_BASIC_INFO_SCRIPT "/lib/k3screenctrl/basic.sh"

    /**
     * This script will be called in order to get ports info.
     *
     * Expected output format (one line for each field):
     * LAN1 connected? (0 or 1, applies to other fields as well)
     * LAN2 connected?
     * LAN3 connected?
     * WAN connected?
     * USB connected / mounted? (up to you)
     *
     * Example:
     * 1
     * 1
     * 0
     * 1
     * 1
     */
    char *port_script;
#define DEFAULT_PORT_SCRIPT "/lib/k3screenctrl/port.sh"

    /**
     * This script will be called in order to get WAN speed info.
     *
     * Expected output format (one line for each field):
     * Internet connected? (0 or 1)
     * Upload speed (integer, in Bytes per sec)
     * Download speed (integer, in Bytes per sec)
     *
     * Example:
     * 1
     * 10240000
     * 2048000
     */
    char *wan_script;
#define DEFAULT_WAN_SCRIPT "/lib/k3screenctrl/wan.sh"

    /**
     * This script will be called in order to get WiFi info.
     *
     * Expected output format (one line for each field):
     * Does 2.4GHz and 5GHz have same SSID? (Band steering?) (0 or 1)
     * 2.4GHz SSID
     * 2.4GHz password (or ******* if you like, applies to other fields)
     * 2.4GHz enabled (0 or 1)
     * Number of clients connected to 2.4GHz
     * 5GHz SSID
     * 5GHz password
     * 5GHz enabled
     * Number of clients connected to 5GHz
     * Visitor network SSID
     * Visitor network password
     * Visitor network enabled
     * Number of clients connected to visitor network
     *
     * Example:
     * 0
     * LEDE-24G
     * password24
     * 1
     * 0
     * LEDE-5G
     * password5
     * 1
     * 4
     * <empty line>
     * <empty line>
     * 0
     * 0
     */
    char *wifi_script;
#define DEFAULT_WIFI_SCRIPT "/lib/k3screenctrl/wifi.sh"

    /**
     * This script will be called in order to get host info.
     *
     * Expected output format (one line for each field):
     * Number of hosts
     * Host1 name
     * Host1 upload speed
     * Host1 download speed
     * Host1 brand (0~29)
     * <repetition of Host1 fields>
     *
     * Example:
     * 2
     * MyHost1
     * 248193
     * 1024000
     * 25
     * MyHost2
     * 902831
     * 10485760
     * 0
     */
    char *host_script;
#define DEFAULT_HOST_SCRIPT "/lib/k3screenctrl/host.sh"

    /**
     * This script will be called in order to get weather info.
     *
     * Expected output format (one line for each field):
     * city
     * temp
     * date
     * time
     * weather
     * week
     * error
     *
     * Example:
     * 成都
     * 11
     * 2019-02-20
     * 14:29
     * 25
     * 0
     * 0
     */
    char *weather_script;
#define DEFAULT_WEATHER_SCRIPT "/lib/k3screenctrl/weather.sh"

    /**
     * Shall we skip GPIO setup (do not reset the microcontroller)?
     * Useful when debugging.
     */
    int skip_reset;
#define DEFAULT_SKIP_RESET 0

    /**
     * Keep in foreground. And log to stderr as well.
     */
    int foreground;
#define DEFAULT_FOREGROUND 0

    /**
     * Script test mode. Collect data from scripts and print them, then exit
     */
    int test_mode;
#define DEFAULT_TEST_MODE 0

    /**
     * Update interval. Scripts corresponding to current page will be called
     * with this interval (seconds). Should not be shorter than the time
     * scripts take.
     * Note: PAGE_WAN requires 2 scripts to gather enough data, while other
     * pages require only 1 each.
     */
    int update_interval;
#define DEFAULT_UPDATE_INTERVAL 2

    /**
     * Turn off screen after this time (seconds). 0 to disable.
     */
    int screen_timeout;
#define DEFAULT_SCREEN_TIMEOUT 10
} CONFIG;

void config_parse_cmdline(int argc, char *argv[]);
void config_load_defaults();
CONFIG *config_get();
void config_free();

#define CFG (config_get())
#endif
