#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>

#include "common.h"
#include "config.h"
#include "debug.h"
#include "mcu_proto.h"
#include "scripts.h"

enum _token_type {
    TOKEN_STRING_NEW,       /* Duplicate a new string and write its pointer to
                               *storage */
    TOKEN_STRING_OVERWRITE, /* Write the result directly to *storage, taking
                               storage_len into consideration */
    TOKEN_UINT,             /* Write the result to *storage */
    TOKEN_BYTE,             /* Write the result to *storage */
};

struct _token_store {
    union {
        char **str_new_storage;
        char *str_overwrite_storage;
        unsigned int *uint_storage;
        unsigned char *byte_storage;
    };
    enum _token_type type;
    int storage_len;
};

/* Use the value rather than its address for x */
#define TOKEN_STRING_OVERWRITE_STORE(x)                                        \
    {                                                                          \
        .str_overwrite_storage = (x), .type = TOKEN_STRING_OVERWRITE,          \
        .storage_len = sizeof((x)),                                            \
    }
#define TOKEN_STRING_NEW_STORE(x)                                              \
    {                                                                          \
        .str_new_storage = &(x), .type = TOKEN_STRING_NEW,                     \
        .storage_len = sizeof((x)),                                            \
    }
#define TOKEN_UINT_STORE(x)                                                    \
    { .uint_storage = &(x), .type = TOKEN_UINT, .storage_len = sizeof((x)), }
#define TOKEN_BYTE_STORE(x)                                                    \
    { .byte_storage = &(x), .type = TOKEN_BYTE, .storage_len = sizeof((x)), }

/* Will free(token) if needed */
static void token_store(const struct _token_store *store_info, char *token) {
    switch (store_info->type) {
    case TOKEN_STRING_NEW:
        *store_info->str_new_storage = token;
        break;
    case TOKEN_STRING_OVERWRITE:
        strncpy(store_info->str_overwrite_storage, token,
                store_info->storage_len - 1);
        store_info->str_overwrite_storage[store_info->storage_len - 1] = 0;
        free(token);
        break;
    case TOKEN_UINT:
        *store_info->uint_storage = atoi(token);
        free(token);
        break;
    case TOKEN_BYTE:
        *store_info->byte_storage = atoi(token);
        free(token);
        break;
    }
}

/* Returns pointer to where it left */
static const char *tokenize_and_store(const char *str, const char delim,
                                      const struct _token_store *stores,
                                      int store_len) {
    const char *last_start = str;
    const char *next_token;
    int token_pos = 0;

    while (token_pos < store_len && (next_token = strchr(last_start, delim))) {
        char *curr_token = strndup(last_start, next_token - last_start);
        token_store(&stores[token_pos], curr_token);
        last_start = next_token + 1;
        token_pos++;
    }

    if (token_pos < store_len && *last_start != 0) {
        /* We want more tokens, and there is the case where we might
         * miss a token:
         * The input is not delimiter-terminated, the last token was not
         * processed. */
        char *curr_token = strdup(last_start);
        last_start += strlen(curr_token);
        token_store(&stores[token_pos], curr_token);
        token_pos++;
    }

    if (token_pos < store_len) {
        /* Still want more tokens */
        syslog(LOG_WARNING, "tokenizer: found %d tokens but expected %d (%s)\n",
               token_pos, store_len, str);
    }
    return last_start;
}

static int update_storage_from_script(const char *script,
                                      const struct _token_store stores[],
                                      int store_len) {
    const char *out = script_get_output(script);
    if (out == NULL) {
        return FAILURE;
    }

    /* If the tokenizer stopped at \0, the entire output should have been
     * procesed successfully.
     * If it did not (there is something left in the output), the output may
     * be malformatted and the results are not reliable.
     */
    const char *stopped_at = tokenize_and_store(out, '\n', stores, store_len);
    free((void *)out);

    return *stopped_at == 0 ? SUCCESS : FAILURE;
}

BASIC_INFO g_basic_info;
static int update_basic_info() {
    static const struct _token_store stores[] = {
        TOKEN_STRING_OVERWRITE_STORE(g_basic_info.product_name),
        TOKEN_STRING_OVERWRITE_STORE(g_basic_info.hw_version),
        TOKEN_STRING_OVERWRITE_STORE(g_basic_info.fw_version),
        TOKEN_STRING_OVERWRITE_STORE(g_basic_info.sw_version),
		TOKEN_STRING_OVERWRITE_STORE(g_basic_info.mac_addr_base),
    };
    return update_storage_from_script(CFG->basic_info_script, stores,
                                      sizeof(stores) / sizeof(stores[0]));
}

PORT_INFO g_port_info;
static int update_port_info() {
    static const struct _token_store stores[] = {
        TOKEN_BYTE_STORE(g_port_info.eth_port1_conn),
        TOKEN_BYTE_STORE(g_port_info.eth_port2_conn),
        TOKEN_BYTE_STORE(g_port_info.eth_port3_conn),
        TOKEN_BYTE_STORE(g_port_info.eth_wan_conn),
        TOKEN_BYTE_STORE(g_port_info.usb_conn),
    };
    return update_storage_from_script(CFG->port_script, stores,
                                      sizeof(stores) / sizeof(stores[0]));
}

WAN_INFO g_wan_info;
static int update_wan_info() {
    static const struct _token_store stores[] = {
        TOKEN_UINT_STORE(g_wan_info.is_connected),
        TOKEN_UINT_STORE(g_wan_info.tx_bytes_per_sec),
        TOKEN_UINT_STORE(g_wan_info.rx_bytes_per_sec),
    };
    return update_storage_from_script(CFG->wan_script, stores,
                                      sizeof(stores) / sizeof(stores[0]));
}

WIFI_INFO g_wifi_info;
static int update_wifi_info() {
    static const struct _token_store stores[] = {
        TOKEN_UINT_STORE(g_wifi_info.band_mix),

        TOKEN_STRING_OVERWRITE_STORE(g_wifi_info.wl_24g_info.ssid),
        TOKEN_STRING_OVERWRITE_STORE(g_wifi_info.wl_24g_info.psk),
        TOKEN_BYTE_STORE(g_wifi_info.wl_24g_info.enabled),
        TOKEN_BYTE_STORE(g_wifi_info.wl_24g_info.sta_count),

        TOKEN_STRING_OVERWRITE_STORE(g_wifi_info.wl_5g_info.ssid),
        TOKEN_STRING_OVERWRITE_STORE(g_wifi_info.wl_5g_info.psk),
        TOKEN_BYTE_STORE(g_wifi_info.wl_5g_info.enabled),
        TOKEN_BYTE_STORE(g_wifi_info.wl_5g_info.sta_count),

        TOKEN_STRING_OVERWRITE_STORE(g_wifi_info.wl_visitor_info.ssid),
        TOKEN_STRING_OVERWRITE_STORE(g_wifi_info.wl_visitor_info.psk),
        TOKEN_BYTE_STORE(g_wifi_info.wl_visitor_info.enabled),
        TOKEN_BYTE_STORE(g_wifi_info.wl_visitor_info.sta_count),
    };
    return update_storage_from_script(CFG->wifi_script, stores,
                                      sizeof(stores) / sizeof(stores[0]));
}

struct _host_info_single *g_host_info_array;
unsigned int g_host_info_elements;
static int update_host_info() {
    int ret = FAILURE;
    char *out = script_get_output(CFG->host_script);
    const char *curr_pos = out;
    if (out == NULL) {
        goto final_exit;
    }

    static const struct _token_store number_token[] = {
        TOKEN_UINT_STORE(g_host_info_elements),
    };
    curr_pos = tokenize_and_store(out, '\n', number_token, 1);

    /* If there is no hosts, we won't bother to consider what's next */
    if (g_host_info_elements == 0) {
        ret = SUCCESS;
        goto free_exit;
    }

    if (g_host_info_array != NULL) {
        free(g_host_info_array);
    }

    g_host_info_array = (struct _host_info_single *)malloc(
        g_host_info_elements * sizeof(struct _host_info_single));
    if (g_host_info_array == NULL) {
        syslog(LOG_ERR, "could not allocate memory for host info: %s\n",
               strerror(errno));
        goto free_exit;
    }

    /* The storage pointer is just placeholders. We will change later */
    struct _token_store host_info_tokens[] = {
        TOKEN_STRING_OVERWRITE_STORE(g_host_info_array[0].hostname),
        TOKEN_UINT_STORE(g_host_info_array[0].download_Bps),
        TOKEN_UINT_STORE(g_host_info_array[0].upload_Bps),
        TOKEN_UINT_STORE(g_host_info_array[0].logo),
    };
    for (unsigned int i = 0; i < g_host_info_elements; i++) {
        host_info_tokens[0].str_overwrite_storage =
            g_host_info_array[i].hostname;
        host_info_tokens[1].uint_storage = &g_host_info_array[i].download_Bps;
        host_info_tokens[2].uint_storage = &g_host_info_array[i].upload_Bps;
        host_info_tokens[3].uint_storage = &g_host_info_array[i].logo;

        curr_pos = tokenize_and_store(curr_pos, '\n', host_info_tokens,
                                      sizeof(host_info_tokens) /
                                          sizeof(host_info_tokens[0]));

        if (*curr_pos == 0) {
            syslog(LOG_ERR, "output from host info script was incomplete. "
                            "Informed with %d hosts but only read %d hosts."
                            "Showing read hosts only\n",
                   g_host_info_elements, i);
            g_host_info_elements = i;
            goto free_exit;
        }
    }

    ret = SUCCESS;
free_exit:
    free(out);
final_exit:
    return ret;
}

WEATHER_INFO g_weather_info;
static int update_weather_info() {
	    static const struct _token_store stores[] = {
	            TOKEN_STRING_OVERWRITE_STORE(g_weather_info.city),
	            TOKEN_STRING_OVERWRITE_STORE(g_weather_info.temp),
	            TOKEN_STRING_OVERWRITE_STORE(g_weather_info.date),
	            TOKEN_STRING_OVERWRITE_STORE(g_weather_info.time),
	            TOKEN_BYTE_STORE(g_weather_info.weather),
	            TOKEN_BYTE_STORE(g_weather_info.week),
	            TOKEN_BYTE_STORE(g_weather_info.error),
	        };
	       return update_storage_from_script(CFG->weather_script, stores, sizeof(stores) / sizeof(stores[0]));
}

int update_page_info(PAGE page) {
    int (*updater)() = NULL;

    switch (page) {
    case PAGE_BASIC_INFO:
        updater = update_basic_info;
        break;
    case PAGE_PORTS:
        updater = update_port_info;
        break;
    case PAGE_WAN:
        updater = update_wan_info;
        break;
    case PAGE_WEATHER:
        updater = update_weather_info;
        break;
    case PAGE_WIFI:
        updater = update_wifi_info;
        break;
    case PAGE_HOSTS:
        updater = update_host_info;
        break;
    }

    if (updater != NULL) {
        return updater();
    } else {
        return FAILURE;
    }
}

int update_all_info() {
    int ret = 0;
    ret |= update_basic_info();
    ret |= update_port_info();
    ret |= update_wan_info();
    ret |= update_wifi_info();
    ret |= update_host_info();
    ret |= update_weather_info();
    return ret;
}

void print_all_info() {
    print_basic_info(&g_basic_info);
    print_wifi_info(&g_wifi_info);
    print_wan_info(&g_wan_info);
    print_port_info(&g_port_info);
    print_weather_info(&g_weather_info);
    print_host_info(g_host_info_array, g_host_info_elements);
}