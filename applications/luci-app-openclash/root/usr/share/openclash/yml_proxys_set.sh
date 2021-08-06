#!/bin/sh
. /lib/functions.sh
. /usr/share/openclash/ruby.sh
. /usr/share/openclash/log.sh

set_lock() {
   exec 886>"/tmp/lock/openclash_proxies_set.lock" 2>/dev/null
   flock -x 886 2>/dev/null
}

del_lock() {
   flock -u 886 2>/dev/null
   rm -rf "/tmp/lock/openclash_proxies_set.lock"
}

SERVER_FILE="/tmp/yaml_servers.yaml"
PROXY_PROVIDER_FILE="/tmp/yaml_provider.yaml"
servers_if_update=$(uci get openclash.config.servers_if_update 2>/dev/null)
config_auto_update=$(uci get openclash.config.auto_update 2>/dev/null)
CONFIG_FILE=$(uci get openclash.config.config_path 2>/dev/null)
CONFIG_NAME=$(echo "$CONFIG_FILE" |awk -F '/' '{print $5}' 2>/dev/null)
UPDATE_CONFIG_FILE=$(uci get openclash.config.config_update_path 2>/dev/null)
UPDATE_CONFIG_NAME=$(echo "$UPDATE_CONFIG_FILE" |awk -F '/' '{print $5}' 2>/dev/null)
UCI_DEL_LIST="uci del_list openclash.config.new_servers_group"
UCI_ADD_LIST="uci add_list openclash.config.new_servers_group"
UCI_SET="uci set openclash.config."
MIX_PROXY=$(uci get openclash.config.mix_proxies 2>/dev/null)
servers_name="/tmp/servers_name.list"
proxy_provider_name="/tmp/provider_name.list"
set_lock

if [ ! -z "$UPDATE_CONFIG_FILE" ]; then
   CONFIG_FILE="$UPDATE_CONFIG_FILE"
   CONFIG_NAME="$UPDATE_CONFIG_NAME"
fi

if [ -z "$CONFIG_FILE" ]; then
	CONFIG_FILE="/etc/openclash/config/$(ls -lt /etc/openclash/config/ | grep -E '.yaml|.yml' | head -n 1 |awk '{print $9}')"
	CONFIG_NAME=$(echo "$CONFIG_FILE" |awk -F '/' '{print $5}' 2>/dev/null)
fi

if [ -z "$CONFIG_NAME" ]; then
   CONFIG_FILE="/etc/openclash/config/config.yaml"
   CONFIG_NAME="config.yaml"
fi

yml_other_rules_del()
{
	 local section="$1"
   local enabled config
   config_get_bool "enabled" "$section" "enabled" "1"
   config_get "config" "$section" "config" ""
   config_get "rule_name" "$section" "rule_name" ""
   
   if [ "$enabled" = "0" ] || [ "$config" != "$2" ] || [ "$rule_name" != "$3" ]; then
      return
   else
      uci set openclash."$section".enabled=0 2>/dev/null
   fi
}
#写入代理集到配置文件
yml_proxy_provider_set()
{
   local section="$1"
   config_get_bool "enabled" "$section" "enabled" "1"
   config_get "config" "$section" "config" ""
   config_get "type" "$section" "type" ""
   config_get "name" "$section" "name" ""
   config_get "path" "$section" "path" ""
   config_get "provider_url" "$section" "provider_url" ""
   config_get "provider_interval" "$section" "provider_interval" ""
   config_get "health_check" "$section" "health_check" ""
   config_get "health_check_url" "$section" "health_check_url" ""
   config_get "health_check_interval" "$section" "health_check_interval" ""
   
   if [ "$enabled" = "0" ]; then
      return
   fi

   if [ -z "$type" ]; then
      return
   fi
   
   if [ -z "$name" ]; then
      return
   fi
   
   if [ "$path" != "./proxy_provider/$name.yaml" ] && [ "$type" = "http" ]; then
      path="./proxy_provider/$name.yaml"
   elif [ -z "$path" ]; then
      return
   fi
   
   if [ -z "$health_check" ]; then
      return
   fi
   
   if [ ! -z "$if_game_proxy" ] && [ "$if_game_proxy" != "$name" ] && [ "$if_game_proxy_type" = "proxy-provider" ]; then
      return
   fi
   
   if [ "$MIX_PROXY" != "1" ] && [ ! -z "$config" ] && [ "$config" != "$CONFIG_NAME" ] && [ "$config" != "all" ]; then
      return
   fi
   
   #避免重复代理集
   if [ "$config" = "$CONFIG_NAME" ] || [ "$config" = "all" ]; then
      if [ -n "$(grep -w "path: $path" "$PROXY_PROVIDER_FILE" 2>/dev/null)" ]; then
         return
      elif [ "$(grep -w "$name$" "$proxy_provider_name" |wc -l 2>/dev/null)" -ge 2 ] && [ -z "$(grep -w "path: $path" "$PROXY_PROVIDER_FILE" 2>/dev/null)" ]; then
      	 sed -i "1,/${name}/{//d}" "$proxy_provider_name" 2>/dev/null
         return
      fi
   fi
   
   LOG_OUT "Start Writing【$CONFIG_NAME - $type - $name】Proxy-provider To Config File..."
   echo "$name" >> /tmp/Proxy_Provider
   
cat >> "$PROXY_PROVIDER_FILE" <<-EOF
  $name:
    type: $type
    path: $path
EOF
   if [ ! -z "$provider_url" ]; then
cat >> "$PROXY_PROVIDER_FILE" <<-EOF
    url: $provider_url
    interval: $provider_interval
EOF
   fi
cat >> "$PROXY_PROVIDER_FILE" <<-EOF
    health-check:
      enable: $health_check
      url: $health_check_url
      interval: $health_check_interval
EOF

}

set_alpn()
{
   if [ -z "$1" ]; then
      return
   fi
cat >> "$SERVER_FILE" <<-EOF
      - $1
EOF
}

set_http_path()
{
   if [ -z "$1" ]; then
      return
   fi
cat >> "$SERVER_FILE" <<-EOF
        - '$1'
EOF
}

set_h2_host()
{
   if [ -z "$1" ]; then
      return
   fi
cat >> "$SERVER_FILE" <<-EOF
        - '$1'
EOF
}

#写入服务器节点到配置文件
yml_servers_set()
{

   local section="$1"
   config_get_bool "enabled" "$section" "enabled" "1"
   config_get "config" "$section" "config" ""
   config_get "type" "$section" "type" ""
   config_get "name" "$section" "name" ""
   config_get "server" "$section" "server" ""
   config_get "port" "$section" "port" ""
   config_get "cipher" "$section" "cipher" ""
   config_get "cipher_ssr" "$section" "cipher_ssr" ""
   config_get "password" "$section" "password" ""
   config_get "securitys" "$section" "securitys" ""
   config_get "udp" "$section" "udp" ""
   config_get "obfs" "$section" "obfs" ""
   config_get "obfs_ssr" "$section" "obfs_ssr" ""
   config_get "obfs_param" "$section" "obfs_param" ""
   config_get "obfs_vmess" "$section" "obfs_vmess" ""
   config_get "protocol" "$section" "protocol" ""
   config_get "protocol_param" "$section" "protocol_param" ""
   config_get "host" "$section" "host" ""
   config_get "mux" "$section" "mux" ""
   config_get "custom" "$section" "custom" ""
   config_get "tls" "$section" "tls" ""
   config_get "skip_cert_verify" "$section" "skip_cert_verify" ""
   config_get "path" "$section" "path" ""
   config_get "alterId" "$section" "alterId" ""
   config_get "uuid" "$section" "uuid" ""
   config_get "auth_name" "$section" "auth_name" ""
   config_get "auth_pass" "$section" "auth_pass" ""
   config_get "psk" "$section" "psk" ""
   config_get "obfs_snell" "$section" "obfs_snell" ""
   config_get "sni" "$section" "sni" ""
   config_get "alpn" "$section" "alpn" ""
   config_get "http_path" "$section" "http_path" ""
   config_get "keep_alive" "$section" "keep_alive" ""
   config_get "servername" "$section" "servername" ""
   config_get "h2_path" "$section" "h2_path" ""
   config_get "h2_host" "$section" "h2_host" ""
   config_get "grpc_service_name" "$section" "grpc_service_name" ""

   if [ "$enabled" = "0" ]; then
      return
   fi

   if [ -z "$type" ]; then
      return
   fi
   
   if [ -z "$name" ]; then
      return
   fi
   
   if [ -z "$server" ]; then
      return
   fi
   
   if [ -z "$port" ]; then
      return
   fi
   
   if [ -z "$password" ]; then
   	 if [ "$type" = "ss" ] || [ "$type" = "trojan" ] || [ "$type" = "ssr" ]; then
        return
     fi
   fi
   
   if [ ! -z "$if_game_proxy" ] && [ "$if_game_proxy" != "$name" ] && [ "$if_game_proxy_type" = "proxy" ]; then
      return
   fi
   
   if [ "$MIX_PROXY" != "1" ] && [ ! -z "$config" ] && [ "$config" != "$CONFIG_NAME" ] && [ "$config" != "all" ]; then
      return
   fi
   
   #避免重复节点
   if [ "$config" = "$CONFIG_NAME" ] || [ "$config" = "all" ]; then
      if [ "$(grep -w "$name$" "$servers_name" |wc -l 2>/dev/null)" -ge 2 ] && [ -n "$(grep -w "name: \"$name\"" "$SERVER_FILE" 2>/dev/null)" ]; then
         return
      fi
   fi
   
   if [ "$config" = "$CONFIG_NAME" ] || [ "$config" = "all" ]; then
      if [ -n "$(grep -w "name: \"$name\"" "$SERVER_FILE" 2>/dev/null)" ]; then
         return
      elif [ "$(grep -w "$name$" "$servers_name" |wc -l 2>/dev/null)" -ge 2 ] && [ -z "$(grep -w "name: \"$name\"" "$SERVER_FILE" 2>/dev/null)" ]; then
      	 sed -i "1,/${name}/{//d}" "$servers_name" 2>/dev/null
         return
      fi
   fi
   LOG_OUT "Start Writing【$CONFIG_NAME - $type - $name】Proxy To Config File..."
   
   if [ "$obfs" != "none" ] && [ -n "$obfs" ]; then
      if [ "$obfs" = "websocket" ]; then
         obfss="plugin: v2ray-plugin"
      else
         obfss="plugin: obfs"
      fi
   else
      obfss=""
   fi
   
   if [ "$obfs_vmess" = "websocket" ]; then
      obfs_vmess="network: ws"
   fi
   
   if [ "$obfs_vmess" = "http" ]; then
      obfs_vmess="network: http"
   fi
   
   if [ "$obfs_vmess" = "h2" ]; then
      obfs_vmess="network: h2"
   fi
   
   if [ "$obfs_vmess" = "grpc" ]; then
      obfs_vmess="network: grpc"
   fi
   
   if [ ! -z "$custom" ] && [ "$type" = "vmess" ]; then
      custom="Host: $custom"
   fi
   
   if [ ! -z "$path" ]; then
      if [ "$type" != "vmess" ]; then
         path="path: '$path'"
      elif [ "$obfs_vmess" = "network: ws" ]; then
         path="ws-path: $path"
      fi
   fi

#ss
   if [ "$type" = "ss" ]; then
cat >> "$SERVER_FILE" <<-EOF
  - name: "$name"
    type: $type
    server: $server
    port: $port
    cipher: $cipher
    password: "$password"
EOF
      if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
    udp: $udp
EOF
     fi
     if [ ! -z "$obfss" ]; then
cat >> "$SERVER_FILE" <<-EOF
    $obfss
    plugin-opts:
      mode: $obfs
EOF
        if [ ! -z "$host" ]; then
cat >> "$SERVER_FILE" <<-EOF
      host: $host
EOF
        fi
        if [  "$obfss" = "plugin: v2ray-plugin" ]; then
           if [ ! -z "$tls" ]; then
cat >> "$SERVER_FILE" <<-EOF
      tls: $tls
EOF
           fi
           if [ ! -z "$skip_cert_verify" ]; then
cat >> "$SERVER_FILE" <<-EOF
      skip-cert-verify: $skip_cert_verify
EOF
           fi
           if [ ! -z "$path" ]; then
cat >> "$SERVER_FILE" <<-EOF
      $path
EOF
           fi
           if [ ! -z "$mux" ]; then
cat >> "$SERVER_FILE" <<-EOF
      mux: $mux
EOF
           fi
           if [ ! -z "$custom" ]; then
cat >> "$SERVER_FILE" <<-EOF
      headers:
        custom: $custom
EOF
           fi
        fi
     fi
   fi
   
#ssr
if [ "$type" = "ssr" ]; then
cat >> "$SERVER_FILE" <<-EOF
  - name: "$name"
    type: $type
    server: $server
    port: $port
    cipher: $cipher_ssr
    password: "$password"
    obfs: "$obfs_ssr"
    protocol: "$protocol"
EOF
   if [ ! -z "$obfs_param" ]; then
cat >> "$SERVER_FILE" <<-EOF
    obfs-param: $obfs_param
EOF
   fi
   if [ ! -z "$protocol_param" ]; then
cat >> "$SERVER_FILE" <<-EOF
    protocol-param: $protocol_param
EOF
   fi
   if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
    udp: $udp
EOF
   fi
fi

#vmess
   if [ "$type" = "vmess" ]; then
cat >> "$SERVER_FILE" <<-EOF
  - name: "$name"
    type: $type
    server: $server
    port: $port
    uuid: $uuid
    alterId: $alterId
    cipher: $securitys
EOF
      if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
    udp: $udp
EOF
      fi
      if [ ! -z "$skip_cert_verify" ]; then
cat >> "$SERVER_FILE" <<-EOF
    skip-cert-verify: $skip_cert_verify
EOF
      fi
      if [ ! -z "$tls" ]; then
cat >> "$SERVER_FILE" <<-EOF
    tls: $tls
EOF
      fi
      if [ ! -z "$servername" ] && [ "$tls" = "true" ]; then
cat >> "$SERVER_FILE" <<-EOF
    servername: $servername
EOF
      fi
      if [ "$obfs_vmess" != "none" ]; then
cat >> "$SERVER_FILE" <<-EOF
    $obfs_vmess
EOF
         if [ ! -z "$path" ] && [ "$obfs_vmess" = "network: ws" ]; then
cat >> "$SERVER_FILE" <<-EOF
    $path
EOF
         fi
         if [ ! -z "$custom" ] && [ "$obfs_vmess" = "network: ws" ]; then
cat >> "$SERVER_FILE" <<-EOF
    ws-headers:
      $custom
EOF
         fi
         if [ ! -z "$http_path" ] && [ "$obfs_vmess" = "network: http" ]; then
cat >> "$SERVER_FILE" <<-EOF
    http-opts:
      method: "GET"
      path:
EOF
            config_list_foreach "$section" "http_path" set_http_path
         fi
         if [ "$keep_alive" = "true" ] && [ "$obfs_vmess" = "network: http" ]; then
cat >> "$SERVER_FILE" <<-EOF
      headers:
        Connection:
          - keep-alive
EOF
         fi
         
         #h2
         if [ ! -z "$h2_host" ] && [ "$obfs_vmess" = "network: h2" ]; then
cat >> "$SERVER_FILE" <<-EOF
    h2-opts:
      host:
EOF
            config_list_foreach "$section" "h2_host" set_h2_host
         fi
         if [ ! -z "$h2_path" ] && [ "$obfs_vmess" = "network: h2" ]; then
cat >> "$SERVER_FILE" <<-EOF
      path: $h2_path
EOF
         fi
         if [ ! -z "$grpc_service_name" ] && [ "$obfs_vmess" = "network: grpc" ]; then
cat >> "$SERVER_FILE" <<-EOF
    grpc-opts:
      grpc-service-name: "$grpc_service_name"
EOF
         fi
      fi
   fi

#socks5
   if [ "$type" = "socks5" ]; then
cat >> "$SERVER_FILE" <<-EOF
  - name: "$name"
    type: $type
    server: $server
    port: $port
EOF
      if [ ! -z "$auth_name" ]; then
cat >> "$SERVER_FILE" <<-EOF
    username: $auth_name
EOF
      fi
      if [ ! -z "$auth_pass" ]; then
cat >> "$SERVER_FILE" <<-EOF
    password: $auth_pass
EOF
      fi
      if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
    udp: $udp
EOF
      fi
      if [ ! -z "$skip_cert_verify" ]; then
cat >> "$SERVER_FILE" <<-EOF
    skip-cert-verify: $skip_cert_verify
EOF
      fi
      if [ ! -z "$tls" ]; then
cat >> "$SERVER_FILE" <<-EOF
    tls: $tls
EOF
      fi
   fi

#http
   if [ "$type" = "http" ]; then
cat >> "$SERVER_FILE" <<-EOF
  - name: "$name"
    type: $type
    server: $server
    port: $port
EOF
      if [ ! -z "$auth_name" ]; then
cat >> "$SERVER_FILE" <<-EOF
    username: $auth_name
EOF
      fi
      if [ ! -z "$auth_pass" ]; then
cat >> "$SERVER_FILE" <<-EOF
    password: $auth_pass
EOF
      fi
      if [ ! -z "$skip_cert_verify" ]; then
cat >> "$SERVER_FILE" <<-EOF
    skip-cert-verify: $skip_cert_verify
EOF
      fi
      if [ ! -z "$tls" ]; then
cat >> "$SERVER_FILE" <<-EOF
    tls: $tls
EOF
      fi
      if [ ! -z "$sni" ]; then
cat >> "$SERVER_FILE" <<-EOF
    sni: $sni
EOF
      fi
   fi

#trojan
   if [ "$type" = "trojan" ]; then
cat >> "$SERVER_FILE" <<-EOF
  - name: "$name"
    type: $type
    server: $server
    port: $port
    password: "$password"
EOF
   if [ ! -z "$udp" ]; then
cat >> "$SERVER_FILE" <<-EOF
    udp: $udp
EOF
   fi
   if [ ! -z "$sni" ]; then
cat >> "$SERVER_FILE" <<-EOF
    sni: $sni
EOF
   fi
   if [ ! -z "$alpn" ]; then
cat >> "$SERVER_FILE" <<-EOF
    alpn:
EOF
      config_list_foreach "$section" "alpn" set_alpn
   fi
   if [ ! -z "$skip_cert_verify" ]; then
cat >> "$SERVER_FILE" <<-EOF
    skip-cert-verify: $skip_cert_verify
EOF
   fi
   if [ ! -z "$grpc_service_name" ]; then
cat >> "$SERVER_FILE" <<-EOF
    grpc-opts:
      grpc-service-name: "$grpc_service_name"
EOF
   fi
   fi

#snell
   if [ "$type" = "snell" ]; then
cat >> "$SERVER_FILE" <<-EOF
  - name: "$name"
    type: $type
    server: $server
    port: $port
    psk: $psk
EOF
   if [ "$obfs_snell" != "none" ] && [ ! -z "$host" ]; then
cat >> "$SERVER_FILE" <<-EOF
    obfs-opts:
      mode: $obfs_snell
      host: $host
EOF
   fi
   fi

}

new_servers_group_set()
{
   local section="$1"
   config_get_bool "enabled" "$section" "enabled" "1"
   config_get "name" "$section" "name" ""
   
   if [ "$enabled" = "0" ]; then
      return
   fi
   
   if [ -z "$name" ] || [ "$(echo $name.yaml)" != "$CONFIG_NAME" ]; then
      return
   fi
   
   new_servers_group_set=1
   
}

yml_servers_name_get()
{
	 local section="$1"
   config_get "name" "$section" "name" ""
   [ ! -z "$name" ] && {
      echo "$name" >>"$servers_name"
   }
}

yml_proxy_provider_name_get()
{
	 local section="$1"
   config_get "name" "$section" "name" ""
   [ ! -z "$name" ] && {
      echo "$name" >>"$proxy_provider_name"
   }
}

#创建配置文件
if_game_proxy="$1"
if_game_proxy_type="$2"
#创建对比文件防止重复
config_load "openclash"
config_foreach yml_servers_name_get "servers"
config_foreach yml_proxy_provider_name_get "proxy-provider"
#判断是否启用保留配置
config_foreach new_servers_group_set "config_subscribe"
#proxy-provider
LOG_OUT "Start Writing【$CONFIG_NAME】Proxy-providers Setting..."
echo "proxy-providers:" >$PROXY_PROVIDER_FILE
rm -rf /tmp/Proxy_Provider
config_foreach yml_proxy_provider_set "proxy-provider"
sed -i "s/^ \{0,\}/      - /" /tmp/Proxy_Provider 2>/dev/null #添加参数
if [ "$(grep "-" /tmp/Proxy_Provider 2>/dev/null |wc -l)" -eq 0 ]; then
   rm -rf $PROXY_PROVIDER_FILE
   rm -rf /tmp/Proxy_Provider
fi
rm -rf $proxy_provider_name

#proxy
rule_sources=$(uci get openclash.config.rule_sources 2>/dev/null)
create_config=$(uci get openclash.config.create_config 2>/dev/null)
LOG_OUT "Start Writing【$CONFIG_NAME】Proxies Setting..."
echo "proxies:" >$SERVER_FILE
config_foreach yml_servers_set "servers"
egrep '^ {0,}-' $SERVER_FILE |grep name: |awk -F 'name: ' '{print $2}' |sed 's/,.*//' 2>/dev/null >/tmp/Proxy_Server 2>&1
if [ -s "/tmp/Proxy_Server" ]; then
   sed -i "s/^ \{0,\}/      - /" /tmp/Proxy_Server 2>/dev/null #添加参数
else
   rm -rf $SERVER_FILE
   rm -rf /tmp/Proxy_Server
fi
rm -rf $servers_name

#一键创建配置文件
if [ "$rule_sources" = "ConnersHua" ] && [ "$servers_if_update" != "1" ] && [ -z "$if_game_proxy" ]; then
LOG_OUT "Creating By Using Connershua (rule set) Rules..."
echo "proxy-groups:" >>$SERVER_FILE
cat >> "$SERVER_FILE" <<-EOF
  - name: Auto - UrlTest
    type: url-test
EOF
if [ -f "/tmp/Proxy_Server" ]; then
cat >> "$SERVER_FILE" <<-EOF
    proxies:
EOF
fi
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
    url: https://cp.cloudflare.com/generate_204
    interval: "600"
    tolerance: "150"
  - name: Proxy
    type: select
    proxies:
      - Auto - UrlTest
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Domestic
    type: select
    proxies:
      - DIRECT
      - Proxy
  - name: Others
    type: select
    proxies:
      - Proxy
      - DIRECT
      - Domestic
  - name: AsianTV
    type: select
    proxies:
      - DIRECT
      - Proxy
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: GlobalTV
    type: select
    proxies:
      - Proxy
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
config_load "openclash"
config_foreach yml_other_rules_del "other_rules" "$CONFIG_NAME" "ConnersHua"
uci_name_tmp=$(uci add openclash other_rules)
uci_set="uci -q set openclash.$uci_name_tmp."
${UCI_SET}rule_source="1"
${uci_set}enable="1"
${uci_set}rule_name="ConnersHua"
${uci_set}config="$CONFIG_NAME"
${uci_set}GlobalTV="GlobalTV"
${uci_set}AsianTV="AsianTV"
${uci_set}Proxy="Proxy"
${uci_set}AdBlock="AdBlock"
${uci_set}Domestic="Domestic"
${uci_set}Others="Others"

[ "$config_auto_update" -eq 1 ] && [ "$new_servers_group_set" -eq 1 ] && {
	${UCI_SET}servers_update="1"
	${UCI_DEL_LIST}="Auto - UrlTest" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Auto - UrlTest" >/dev/null 2>&1
	${UCI_DEL_LIST}="Proxy" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Proxy" >/dev/null 2>&1
	${UCI_DEL_LIST}="AsianTV" >/dev/null 2>&1 && ${UCI_ADD_LIST}="AsianTV" >/dev/null 2>&1
	${UCI_DEL_LIST}="GlobalTV" >/dev/null 2>&1 && ${UCI_ADD_LIST}="GlobalTV" >/dev/null 2>&1
}
elif [ "$rule_sources" = "lhie1" ] && [ "$servers_if_update" != "1" ] && [ -z "$if_game_proxy" ]; then
LOG_OUT "Creating By Using lhie1 Rules..."
echo "proxy-groups:" >>$SERVER_FILE
cat >> "$SERVER_FILE" <<-EOF
  - name: Auto - UrlTest
    type: url-test
EOF
if [ -f "/tmp/Proxy_Server" ]; then
cat >> "$SERVER_FILE" <<-EOF
    proxies:
EOF
fi
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
    url: https://cp.cloudflare.com/generate_204
    interval: "600"
    tolerance: "150"
  - name: Proxy
    type: select
    proxies:
      - Auto - UrlTest
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Domestic
    type: select
    proxies:
      - DIRECT
      - Proxy
  - name: Others
    type: select
    proxies:
      - Proxy
      - DIRECT
      - Domestic
  - name: Microsoft
    type: select
    proxies:
      - DIRECT
      - Proxy
EOF
cat >> "$SERVER_FILE" <<-EOF
  - name: Apple
    type: select
    proxies:
      - DIRECT
      - Proxy
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Scholar
    type: select
    proxies:
      - Proxy
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Bilibili
    type: select
    proxies:
      - AsianTV
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Bahamut
    type: select
    proxies:
      - GlobalTV
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: HBO
    type: select
    proxies:
      - GlobalTV
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Pornhub
    type: select
    proxies:
      - GlobalTV
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Netflix
    type: select
    proxies:
      - GlobalTV
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Disney
    type: select
    proxies:
      - GlobalTV
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Youtube
    type: select
    disable-udp: true
    proxies:
      - GlobalTV
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Spotify
    type: select
    proxies:
      - GlobalTV
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Steam
    type: select
    proxies:
      - DIRECT
      - Proxy
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: AdBlock
    type: select
    proxies:
      - REJECT
      - DIRECT
      - Proxy
  - name: AsianTV
    type: select
    proxies:
      - DIRECT
      - Proxy
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: GlobalTV
    type: select
    proxies:
      - Proxy
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Speedtest
    type: select
    proxies:
      - Proxy
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Telegram
    type: select
    proxies:
      - Proxy
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: PayPal
    type: select
    proxies:
      - DIRECT
      - Proxy
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
config_load "openclash"
config_foreach yml_other_rules_del "other_rules" "$CONFIG_NAME" "lhie1"
uci_name_tmp=$(uci add openclash other_rules)
uci_set="uci -q set openclash.$uci_name_tmp."
${UCI_SET}rule_source="1"
${uci_set}enable="1"
${uci_set}rule_name="lhie1"
${uci_set}config="$CONFIG_NAME"
${uci_set}GlobalTV="GlobalTV"
${uci_set}AsianTV="AsianTV"
${uci_set}Proxy="Proxy"
${uci_set}Youtube="Youtube"
${uci_set}Bilibili="Bilibili"
${uci_set}Bahamut="Bahamut"
${uci_set}HBO="HBO"
${uci_set}Pornhub="Pornhub"
${uci_set}Apple="Apple"
${uci_set}Scholar="Scholar"
${uci_set}Microsoft="Microsoft"
${uci_set}Netflix="Netflix"
${uci_set}Disney="Disney"
${uci_set}Spotify="Spotify"
${uci_set}Steam="Steam"
${uci_set}AdBlock="AdBlock"
${uci_set}Speedtest="Speedtest"
${uci_set}Telegram="Telegram"
${uci_set}PayPal="PayPal"
${uci_set}Domestic="Domestic"
${uci_set}Others="Others"

[ "$config_auto_update" -eq 1 ] && [ "$new_servers_group_set" -eq 1 ] && {
	${UCI_SET}servers_update="1"
	${UCI_DEL_LIST}="Auto - UrlTest" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Auto - UrlTest" >/dev/null 2>&1
	${UCI_DEL_LIST}="Proxy" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Proxy" >/dev/null 2>&1
	${UCI_DEL_LIST}="Youtube" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Youtube" >/dev/null 2>&1
	${UCI_DEL_LIST}="Bilibili" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Bilibili" >/dev/null 2>&1
	${UCI_DEL_LIST}="Bahamut" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Bahamut" >/dev/null 2>&1
	${UCI_DEL_LIST}="HBO" >/dev/null 2>&1 && ${UCI_ADD_LIST}="HBO" >/dev/null 2>&1
	${UCI_DEL_LIST}="Pornhub" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Pornhub" >/dev/null 2>&1
	${UCI_DEL_LIST}="AsianTV" >/dev/null 2>&1 && ${UCI_ADD_LIST}="AsianTV" >/dev/null 2>&1
	${UCI_DEL_LIST}="GlobalTV" >/dev/null 2>&1 && ${UCI_ADD_LIST}="GlobalTV" >/dev/null 2>&1
	${UCI_DEL_LIST}="Netflix" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Netflix" >/dev/null 2>&1
	${UCI_DEL_LIST}="Apple" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Apple" >/dev/null 2>&1
	${UCI_DEL_LIST}="Scholar" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Scholar" >/dev/null 2>&1
	${UCI_DEL_LIST}="Disney" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Disney" >/dev/null 2>&1
	${UCI_DEL_LIST}="Spotify" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Spotify" >/dev/null 2>&1
	${UCI_DEL_LIST}="Steam" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Steam" >/dev/null 2>&1
	${UCI_DEL_LIST}="Telegram" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Telegram" >/dev/null 2>&1
	${UCI_DEL_LIST}="PayPal" >/dev/null 2>&1 && ${UCI_ADD_LIST}="PayPal" >/dev/null 2>&1
	${UCI_DEL_LIST}="Speedtest" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Speedtest" >/dev/null 2>&1
}
elif [ "$rule_sources" = "ConnersHua_return" ] && [ "$servers_if_update" != "1" ] && [ -z "$if_game_proxy" ]; then
LOG_OUT "Creating By Using ConnersHua Return Rules..."
echo "proxy-groups:" >>$SERVER_FILE
cat >> "$SERVER_FILE" <<-EOF
  - name: Auto - UrlTest
    type: url-test
EOF
if [ -f "/tmp/Proxy_Server" ]; then
cat >> "$SERVER_FILE" <<-EOF
    proxies:
EOF
fi
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
    url: https://cp.cloudflare.com/generate_204
    interval: "600"
    tolerance: "150"
  - name: Proxy
    type: select
    proxies:
      - Auto - UrlTest
      - DIRECT
EOF
cat /tmp/Proxy_Server >> $SERVER_FILE 2>/dev/null
if [ -f "/tmp/Proxy_Provider" ]; then
cat >> "$SERVER_FILE" <<-EOF
    use:
EOF
fi
cat /tmp/Proxy_Provider >> $SERVER_FILE 2>/dev/null
cat >> "$SERVER_FILE" <<-EOF
  - name: Others
    type: select
    proxies:
      - Proxy
      - DIRECT
EOF
config_load "openclash"
config_foreach yml_other_rules_del "other_rules" "$CONFIG_NAME" "ConnersHua_return"
uci_name_tmp=$(uci add openclash other_rules)
uci_set="uci -q set openclash.$uci_name_tmp."
${UCI_SET}rule_source="1"
${uci_set}enable="1"
${uci_set}rule_name="ConnersHua_return"
${uci_set}config="$CONFIG_NAME"
${uci_set}Proxy="Proxy"
${uci_set}Others="Others"
[ "$config_auto_update" -eq 1 ] && [ "$new_servers_group_set" -eq 1 ] && {
	${UCI_SET}servers_update="1"
	${UCI_DEL_LIST}="Auto - UrlTest" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Auto - UrlTest" >/dev/null 2>&1
	${UCI_DEL_LIST}="Proxy" >/dev/null 2>&1 && ${UCI_ADD_LIST}="Proxy" >/dev/null 2>&1
}
fi

if [ "$create_config" != "0" ] && [ "$servers_if_update" != "1" ] && [ -z "$if_game_proxy" ]; then
   echo "rules:" >>$SERVER_FILE
   LOG_OUT "Config File【$CONFIG_NAME】Created Successful, Updating Proxies, Proxy-providers, Groups..."
   cat "$PROXY_PROVIDER_FILE" > "$CONFIG_FILE" 2>/dev/null
   cat "$SERVER_FILE" >> "$CONFIG_FILE" 2>/dev/null
   /usr/share/openclash/yml_groups_get.sh >/dev/null 2>&1
elif [ -z "$if_game_proxy" ]; then
   LOG_OUT "Proxies, Proxy-providers, Groups Edited Successful, Updating Config File【$CONFIG_NAME】..."
   config_hash=$(ruby -ryaml -E UTF-8 -e "Value = YAML.load_file('$CONFIG_FILE'); puts Value" 2>/dev/null)
   if [ "$config_hash" != "false" ] && [ -n "$config_hash" ]; then
      ruby_cover "$CONFIG_FILE" "['proxies']" "$SERVER_FILE" "['proxies']"
      ruby_cover "$CONFIG_FILE" "['proxy-providers']" "$PROXY_PROVIDER_FILE" "['proxy-providers']"
      ruby_cover "$CONFIG_FILE" "['proxy-groups']" "/tmp/yaml_groups.yaml" "['proxy-groups']"
   else
      cat "$SERVER_FILE" "$PROXY_PROVIDER_FILE" "/tmp/yaml_groups.yaml" > "$CONFIG_FILE" 2>/dev/null
   fi
fi

if [ -z "$if_game_proxy" ]; then
   rm -rf $SERVER_FILE 2>/dev/null
   rm -rf $PROXY_PROVIDER_FILE 2>/dev/null
   rm -rf /tmp/yaml_groups.yaml 2>/dev/null
   LOG_OUT "Config File【$CONFIG_NAME】Write Successful!"
   sleep 3
   SLOG_CLEAN
fi
rm -rf /tmp/Proxy_Server 2>/dev/null
rm -rf /tmp/Proxy_Provider 2>/dev/null
del_lock
${UCI_SET}enable=1 2>/dev/null
[ "$(uci get openclash.config.servers_if_update)" == "0" ] && [ -z "$if_game_proxy" ] && /etc/init.d/openclash restart >/dev/null 2>&1
${UCI_SET}servers_if_update=0
uci commit openclash
