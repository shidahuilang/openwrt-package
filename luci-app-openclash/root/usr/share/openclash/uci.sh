#!/bin/sh

uci_get_config() {
    local key="$1"
    uci -q get openclash.@overwrite[0]."$key" || uci -q get openclash.config."$key"
}