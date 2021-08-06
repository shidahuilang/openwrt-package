#!/bin/sh
. /usr/share/openclash/ruby.sh

CFG_FILE=$(uci get openclash.config.config_path 2>/dev/null)
UPDATE_CONFIG_FILE=$(uci get openclash.config.config_update_path 2>/dev/null)

if [ ! -z "$UPDATE_CONFIG_FILE" ]; then
   CFG_FILE="$UPDATE_CONFIG_FILE"
fi

if [ -z "$CFG_FILE" ]; then
	CFG_FILE="/etc/openclash/config/$(ls -lt /etc/openclash/config/ | grep -E '.yaml|.yml' | head -n 1 |awk '{print $9}')"
fi

if [ -f "$CFG_FILE" ]; then
   rm -rf "/tmp/Proxy_Group" 2>/dev/null
   ruby_read_hash_arr "$CFG_FILE" "['proxy-groups']" "['name']" >/tmp/Proxy_Group 2>&1

   if [ -f "/tmp/Proxy_Group" ]; then
      echo 'DIRECT' >>/tmp/Proxy_Group
      echo 'REJECT' >>/tmp/Proxy_Group
   else
      return 1
   fi
else
   return 1
fi