#!/bin/bash
. /lib/functions.sh

set_lock() {
   exec 882>"/tmp/lock/openclash_name_ch.lock" 2>/dev/null
   flock -x 882 2>/dev/null
}

del_lock() {
   flock -u 882 2>/dev/null
   rm -rf "/tmp/lock/openclash_name_ch.lock"
}

cfg_groups_set()
{

   CFG_FILE="/etc/config/openclash"
   local section="$1"
   config_get "name" "$section" "name" ""
   config_get "old_name_cfg" "$section" "old_name_cfg" ""
   config_get "old_name" "$section" "old_name" ""

   if [ -z "$name" ]; then
      return
   fi
   
   if [ -z "$old_name_cfg" ]; then
      uci set openclash."$section".old_name_cfg="$name"
      uci commit openclash
   fi
   
   if [ -z "$old_name" ]; then
      uci set openclash."$section".old_name="$name"
      uci commit openclash
   fi
   
   #名字变化时处理配置文件
   if [ "$name" != "$old_name_cfg" ] && [ ! -z "$old_name_cfg" ]; then
      sed -i "s/old_name_cfg \'${old_name_cfg}\'/old_name_cfg \'${name}\'/g" $CFG_FILE 2>/dev/null
      sed -i "s/groups \'${old_name_cfg}/groups \'${name}/g" $CFG_FILE 2>/dev/null
      sed -i "s/other_group \'${old_name_cfg}/other_group \'${name}/g" $CFG_FILE 2>/dev/null
      sed -i "s/new_servers_group \'${old_name_cfg}/new_servers_group \'${name}/g" $CFG_FILE 2>/dev/null
      sed -i "s/relay_groups \'${old_name_cfg}/relay_groups \'${name}/g" $CFG_FILE 2>/dev/null
   #第三方规则处理
      OTHER_RULE_NAMES=("GlobalTV" "AsianTV" "Proxy" "Youtube" "Bilibili" "Bahamut" "HBO" "Pornhub" "Apple" "Scholar" "Microsoft" "Netflix" "Disney" "Spotify" "Steam" "Speedtest" "Telegram" "PayPal" "Netease_Music" "AdBlock" "Domestic" "Others")
      for i in ${OTHER_RULE_NAMES[@]}; do
      	if [ "$(uci get openclash.config."$i" 2>/dev/null)" = "$old_name_cfg" ]; then
      	   uci set openclash.config."$i"=$name 2>/dev/null
      	   uci commit openclash
        fi
      done 2>/dev/null
      config_load "openclash"
   fi

}

set_lock
config_load "openclash"
config_foreach cfg_groups_set "groups"
del_lock