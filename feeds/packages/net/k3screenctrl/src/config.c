#include <getopt.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "config.h"

static CONFIG g_config;

static void config_show_help() {
    fprintf(
        stderr,
        "USAGE: k3screenctrl [OPTIONS]\n\n"
        "\t-h, --help\t\t\tShow this help\n"
        "\t-r, --skip-reset\t\tDo not reset screen on startup (will reset "
        "by default)\n"
        "\t-f, --foreground\t\tRun in foreground and print logs to stderr "
        "as well\n"
        "\t-t, --test\t\t\tTest the scripts: collect info and print them, then "
        "exit\n"
        "\t-d, --update-interval <SECS>\tCall data collection scripts "
        "corresponding to current page and update content every SECS seconds\n"
        "\t-m, --screen-timeout <SECS>\tTurn off screen after this period of "
        "time if there isn't any user interaction\n"
        "\t-s, --host-script <PATH>\tUse this script to gather hosts "
        "info\n"
        "\t-w, --wifi-script <PATH>\tUse this script to gather WiFi "
        "info\n"
        "\t-p, --port-script <PATH>\tUse this script to gather port "
        "info\n"
        "\t-n, --wan-script <PATH>\t\tUse this script to gather WAN speed "
        "and internet connection info\n"
        "\t-i, --basic-info-script <PATH>\tUse this script to gather "
        "basic info\n"
        "\t-e, --weather-script <PATH>\tUse this script to gather "
        "weather info\n"
        "\nThe defaults are /lib/k3screenctrl/{weather,host,wifi,port,wan,basic}.sh "
        "with an interval of 2 seconds\n");
    exit(1);
}

void config_parse_cmdline(int argc, char *argv[]) {
    static const struct option long_options[] = {
        {"help", no_argument, NULL, 'h'},
        {"foreground", no_argument, NULL, 'f'},
        {"skip-reset", no_argument, NULL, 'r'},
        {"test", no_argument, NULL, 't'},
        {"update-interval", required_argument, NULL, 'd'},
        {"screen-timeout", required_argument, NULL, 'm'},
        {"weather-script", required_argument, NULL, 'e'},
        {"host-script", required_argument, NULL, 's'},
        {"wifi-script", required_argument, NULL, 'w'},
        {"port-script", required_argument, NULL, 'p'},
        {"wan-script", required_argument, NULL, 'n'},
        {"basic-info-script", required_argument, NULL, 'i'},
        {0, 0, 0, 0}};
    static const char *short_opts = "hfrtd:m:e:s:w:p:n:i:";

    int opt_index;
    signed char result;
    while ((result = getopt_long(argc, argv, short_opts, long_options,
                                 &opt_index)) != -1) {
        switch (result) {
        case 'h':
            config_show_help();
            break;
        case 'f':
            g_config.foreground = 1;
            break;
        case 'r':
            g_config.skip_reset = 1;
            break;
        case 't':
            g_config.test_mode = 1;
            break;
        case 'd':
            g_config.update_interval = atoi(optarg);
            break;
        case 'm':
            g_config.screen_timeout = atoi(optarg);
            break;
        case 'e':
            free(g_config.weather_script);
            g_config.weather_script = strdup(optarg);
            break;
        case 's':
            free(g_config.host_script);
            g_config.host_script = strdup(optarg);
            break;
        case 'w':
            free(g_config.wifi_script);
            g_config.wifi_script = strdup(optarg);
            break;
        case 'p':
            free(g_config.port_script);
            g_config.port_script = strdup(optarg);
            break;
        case 'n':
            free(g_config.wan_script);
            g_config.wan_script = strdup(optarg);
            break;
        case 'i':
            free(g_config.basic_info_script);
            g_config.basic_info_script = strdup(optarg);
            break;
        }
    }
}

void config_load_defaults() {
    g_config.skip_reset = DEFAULT_SKIP_RESET;
    g_config.foreground = DEFAULT_FOREGROUND;
    g_config.test_mode = DEFAULT_TEST_MODE;
    g_config.update_interval = DEFAULT_UPDATE_INTERVAL;
    g_config.screen_timeout = DEFAULT_SCREEN_TIMEOUT;
    g_config.weather_script = strdup(DEFAULT_WEATHER_SCRIPT);
    g_config.host_script = strdup(DEFAULT_HOST_SCRIPT);
    g_config.wifi_script = strdup(DEFAULT_WIFI_SCRIPT);
    g_config.port_script = strdup(DEFAULT_PORT_SCRIPT);
    g_config.wan_script = strdup(DEFAULT_WAN_SCRIPT);
    g_config.basic_info_script = strdup(DEFAULT_BASIC_INFO_SCRIPT);
}

void config_free() {
    free(g_config.host_script);
    free(g_config.weather_script);
    free(g_config.wifi_script);
    free(g_config.port_script);
    free(g_config.wan_script);
    free(g_config.basic_info_script);
}

CONFIG *config_get() { return &g_config; }