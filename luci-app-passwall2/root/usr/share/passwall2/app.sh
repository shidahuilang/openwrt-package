#!/bin/sh
# Copyright (C) 2022-2023 xiaorouji

. $IPKG_INSTROOT/lib/functions.sh
. $IPKG_INSTROOT/lib/functions/service.sh

CONFIG=passwall2
TMP_PATH=/tmp/etc/$CONFIG
TMP_BIN_PATH=$TMP_PATH/bin
TMP_SCRIPT_FUNC_PATH=$TMP_PATH/script_func
TMP_ID_PATH=$TMP_PATH/id
TMP_PORT_PATH=$TMP_PATH/port
TMP_ROUTE_PATH=$TMP_PATH/route
TMP_ACL_PATH=$TMP_PATH/acl
TMP_PATH2=/tmp/etc/${CONFIG}_tmp
DNSMASQ_PATH=/etc/dnsmasq.d
TMP_DNSMASQ_PATH=/tmp/dnsmasq.d/passwall2
LOG_FILE=/tmp/log/$CONFIG.log
APP_PATH=/usr/share/$CONFIG
RULES_PATH=/usr/share/${CONFIG}/rules
TUN_DNS_PORT=15353
TUN_DNS="127.0.0.1#${TUN_DNS_PORT}"
DEFAULT_DNS=
IFACES=
ENABLED_DEFAULT_ACL=0
ENABLED_ACLS=0
PROXY_IPV6=0
PROXY_IPV6_UDP=0
LUA_UTIL_PATH=/usr/lib/lua/luci/passwall2
UTIL_SS=$LUA_UTIL_PATH/util_shadowsocks.lua
UTIL_XRAY=$LUA_UTIL_PATH/util_xray.lua
UTIL_NAIVE=$LUA_UTIL_PATH/util_naiveproxy.lua
UTIL_HYSTERIA=$LUA_UTIL_PATH/util_hysteria.lua
V2RAY_ARGS=""
V2RAY_CONFIG=""

echolog() {
	local d="$(date "+%Y-%m-%d %H:%M:%S")"
	echo -e "$d: $*" >>$LOG_FILE
}

config_get_type() {
	local ret=$(uci -q get "${CONFIG}.${1}" 2>/dev/null)
	echo "${ret:=$2}"
}

config_n_get() {
	local ret=$(uci -q get "${CONFIG}.${1}.${2}" 2>/dev/null)
	echo "${ret:=$3}"
}

config_t_get() {
	local index=${4:-0}
	local ret=$(uci -q get "${CONFIG}.@${1}[${index}].${2}" 2>/dev/null)
	echo "${ret:=${3}}"
}

get_enabled_anonymous_secs() {
	uci -q show "${CONFIG}" | grep "${1}\[.*\.enabled='1'" | cut -d '.' -sf2
}

get_host_ip() {
	local host=$2
	local count=$3
	[ -z "$count" ] && count=3
	local isip=""
	local ip=$host
	if [ "$1" == "ipv6" ]; then
		isip=$(echo $host | grep -E "([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4}")
		if [ -n "$isip" ]; then
			isip=$(echo $host | cut -d '[' -f2 | cut -d ']' -f1)
		else
			isip=$(echo $host | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
		fi
	else
		isip=$(echo $host | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
	fi
	[ -z "$isip" ] && {
		local t=4
		[ "$1" == "ipv6" ] && t=6
		local vpsrip=$(resolveip -$t -t $count $host | awk 'NR==1{print}')
		ip=$vpsrip
	}
	echo $ip
}

get_node_host_ip() {
	local ip
	local address=$(config_n_get $1 address)
	[ -n "$address" ] && {
		local use_ipv6=$(config_n_get $1 use_ipv6)
		local network_type="ipv4"
		[ "$use_ipv6" == "1" ] && network_type="ipv6"
		ip=$(get_host_ip $network_type $address)
	}
	echo $ip
}

get_ip_port_from() {
	local __host=${1}; shift 1
	local __ipv=${1}; shift 1
	local __portv=${1}; shift 1
	local __ucipriority=${1}; shift 1

	local val1 val2
	if [ -n "${__ucipriority}" ]; then
		val2=$(config_n_get ${__host} port $(echo $__host | sed -n 's/^.*[:#]\([0-9]*\)$/\1/p'))
		val1=$(config_n_get ${__host} address "${__host%%${val2:+[:#]${val2}*}}")
	else
		val2=$(echo $__host | sed -n 's/^.*[:#]\([0-9]*\)$/\1/p')
		val1="${__host%%${val2:+[:#]${val2}*}}"
	fi
	eval "${__ipv}=\"$val1\"; ${__portv}=\"$val2\""
}

host_from_url(){
	local f=${1}

	## Remove protocol part of url  ##
	f="${f##http://}"
	f="${f##https://}"
	f="${f##ftp://}"
	f="${f##sftp://}"

	## Remove username and/or username:password part of URL  ##
	f="${f##*:*@}"
	f="${f##*@}"

	## Remove rest of urls ##
	f="${f%%/*}"
	echo "${f%%:*}"
}

hosts_foreach() {
	local __hosts
	eval "__hosts=\$${1}"; shift 1
	local __func=${1}; shift 1
	local __default_port=${1}; shift 1
	local __ret=1

	[ -z "${__hosts}" ] && return 0
	local __ip __port
	for __host in $(echo $__hosts | sed 's/[ ,]/\n/g'); do
		get_ip_port_from "$__host" "__ip" "__port"
		eval "$__func \"${__host}\" \"\${__ip}\" \"\${__port:-${__default_port}}\" \"$@\""
		__ret=$?
		[ ${__ret} -ge ${ERROR_NO_CATCH:-1} ] && return ${__ret}
	done
}

check_host() {
	local f=${1}
	a=$(echo $f | grep "\/")
	[ -n "$a" ] && return 1
	# 判断是否包含汉字~
	local tmp=$(echo -n $f | awk '{print gensub(/[!-~]/,"","g",$0)}')
	[ -n "$tmp" ] && return 1
	return 0
}

get_first_dns() {
	local __hosts_val=${1}; shift 1
	__first() {
		[ -z "${2}" ] && return 0
		echo "${2}#${3}"
		return 1
	}
	eval "hosts_foreach \"${__hosts_val}\" __first \"$@\""
}

get_last_dns() {
	local __hosts_val=${1}; shift 1
	local __first __last
	__every() {
		[ -z "${2}" ] && return 0
		__last="${2}#${3}"
		__first=${__first:-${__last}}
	}
	eval "hosts_foreach \"${__hosts_val}\" __every \"$@\""
	[ "${__first}" ==  "${__last}" ] || echo "${__last}"
}

check_port_exists() {
	port=$1
	protocol=$2
	[ -n "$protocol" ] || protocol="tcp,udp"
	result=
	if [ "$protocol" = "tcp" ]; then
		result=$(netstat -tln | grep -c ":$port ")
	elif [ "$protocol" = "udp" ]; then
		result=$(netstat -uln | grep -c ":$port ")
	elif [ "$protocol" = "tcp,udp" ]; then
		result=$(netstat -tuln | grep -c ":$port ")
	fi
	echo "${result}"
}

get_new_port() {
	port=$1
	[ "$port" == "auto" ] && port=2082
	protocol=$(echo $2 | tr 'A-Z' 'a-z')
	result=$(check_port_exists $port $protocol)
	if [ "$result" != 0 ]; then
		temp=
		if [ "$port" -lt 65535 ]; then
			temp=$(expr $port + 1)
		elif [ "$port" -gt 1 ]; then
			temp=$(expr $port - 1)
		fi
		get_new_port $temp $protocol
	else
		echo $port
	fi
}

first_type() {
	local path_name=${1}
	type -t -p "/bin/${path_name}" -p "${TMP_BIN_PATH}/${path_name}" -p "${path_name}" "$@" | head -n1
}

eval_set_val() {
	for i in $@; do
		for j in $i; do
			eval $j
		done
	done
}

eval_unset_val() {
	for i in $@; do
		for j in $i; do
			eval unset j
		done
	done
}

ln_run() {
	local file_func=${1}
	local ln_name=${2}
	local output=${3}

	shift 3;
	if [  "${file_func%%/*}" != "${file_func}" ]; then
		[ ! -L "${file_func}" ] && {
			ln -s "${file_func}" "${TMP_BIN_PATH}/${ln_name}" >/dev/null 2>&1
			file_func="${TMP_BIN_PATH}/${ln_name}"
		}
		[ -x "${file_func}" ] || echolog "  - $(readlink ${file_func}) 没有执行权限，无法启动：${file_func} $*"
	fi
	#echo "${file_func} $*" >&2
	[ -n "${file_func}" ] || echolog "  - 找不到 ${ln_name}，无法启动..."
	${file_func:-echolog "  - ${ln_name}"} "$@" >${output} 2>&1 &
	process_count=$(ls $TMP_SCRIPT_FUNC_PATH | grep -v "^_" | wc -l)
	process_count=$((process_count + 1))
	echo "${file_func:-echolog "  - ${ln_name}"} $@ >${output}" > $TMP_SCRIPT_FUNC_PATH/$process_count
}

lua_api() {
	local func=${1}
	[ -z "${func}" ] && {
		echo "nil"
		return
	}
	echo $(lua -e "local api = require 'luci.passwall2.api' print(api.${func})")
}

run_v2ray() {
	local flag node redir_port socks_address socks_port socks_username socks_password http_address http_port http_username http_password
	local dns_listen_port direct_dns_protocol direct_dns_udp_server direct_dns_tcp_server direct_dns_doh direct_dns_client_ip direct_dns_query_strategy remote_dns_protocol remote_dns_udp_server remote_dns_tcp_server remote_dns_doh remote_dns_client_ip remote_dns_query_strategy dns_cache
	local loglevel log_file config_file
	local _extra_param=""
	eval_set_val $@
	local type=$(echo $(config_n_get $node type) | tr 'A-Z' 'a-z')
	if [ "$type" != "v2ray" ] && [ "$type" != "xray" ]; then
		local bin=$(first_type $(config_t_get global_app xray_file) xray)
		if [ -n "$bin" ]; then
			type="xray"
		else
			bin=$(first_type $(config_t_get global_app v2ray_file) v2ray)
			[ -n "$bin" ] && type="v2ray"
		fi
	fi
	[ -z "$type" ] && return 1
	[ -n "$log_file" ] || local log_file="/dev/null"
	[ -z "$loglevel" ] && local loglevel=$(config_t_get global loglevel "warning")
	[ -n "$flag" ] && pgrep -af "$TMP_BIN_PATH" | awk -v P1="${flag}" 'BEGIN{IGNORECASE=1}$0~P1{print $1}' | xargs kill -9 >/dev/null 2>&1
	[ -n "$flag" ] && _extra_param="${_extra_param} -flag $flag"
	[ -n "$socks_address" ] && _extra_param="${_extra_param} -local_socks_address $socks_address"
	[ -n "$socks_port" ] && _extra_param="${_extra_param} -local_socks_port $socks_port"
	[ -n "$socks_username" ] && [ -n "$socks_password" ] && _extra_param="${_extra_param} -local_socks_username $socks_username -local_socks_password $socks_password"
	[ -n "$http_address" ] && _extra_param="${_extra_param} -local_http_address $http_address"
	[ -n "$http_port" ] && _extra_param="${_extra_param} -local_http_port $http_port"
	[ -n "$http_username" ] && [ -n "$http_password" ] && _extra_param="${_extra_param} -local_http_username $http_username -local_http_password $http_password"
	local sniffing=$(config_t_get global_forwarding sniffing 1)
	[ "${sniffing}" = "1" ] && {
		_extra_param="${_extra_param} -sniffing 1"
		local route_only=$(config_t_get global_forwarding route_only 0)
		[ "${route_only}" = "1" ] && _extra_param="${_extra_param} -route_only 1"
	}
	local buffer_size=$(config_t_get global_forwarding buffer_size)
	[ -n "${buffer_size}" ] && _extra_param="${_extra_param} -buffer_size ${buffer_size}"
	
	local protocol=$(config_n_get $node protocol)
	[ "$protocol" == "_iface" ] && {
		IFACES="$IFACES $(config_n_get $node iface)"
	}
	
	[ -n "$dns_listen_port" ] && {
		V2RAY_DNS_DIRECT_CONFIG="${TMP_PATH}/${flag}_dns_direct.json"
		V2RAY_DNS_DIRECT_LOG="${TMP_PATH}/${flag}_dns_direct.log"
		V2RAY_DNS_DIRECT_LOG="/dev/null"
		V2RAY_DNS_DIRECT_ARGS="-dns_out_tag direct"
		dns_direct_listen_port=$(get_new_port $(expr $dns_listen_port + 1) udp)
		V2RAY_DNS_DIRECT_ARGS="${V2RAY_DNS_DIRECT_ARGS} -dns_listen_port ${dns_direct_listen_port}"
		[ "$direct_dns_protocol" = "auto" ] && {
			direct_dns_protocol="udp"
			direct_dns_udp_server=${AUTO_DNS}
		}
		case "$direct_dns_protocol" in
			udp)
				local _dns=$(get_first_dns direct_dns_udp_server 53 | sed 's/#/:/g')
				local _dns_address=$(echo ${_dns} | awk -F ':' '{print $1}')
				local _dns_port=$(echo ${_dns} | awk -F ':' '{print $2}')
				V2RAY_DNS_DIRECT_ARGS="${V2RAY_DNS_DIRECT_ARGS} -direct_dns_server ${_dns_address} -direct_dns_port ${_dns_port} -direct_dns_udp_server ${_dns_address}"
			;;
			tcp)
				local _dns=$(get_first_dns direct_dns_tcp_server 53 | sed 's/#/:/g')
				local _dns_address=$(echo ${_dns} | awk -F ':' '{print $1}')
				local _dns_port=$(echo ${_dns} | awk -F ':' '{print $2}')
				V2RAY_DNS_DIRECT_ARGS="${V2RAY_DNS_DIRECT_ARGS} -direct_dns_server ${_dns_address} -direct_dns_port ${_dns_port} -direct_dns_tcp_server tcp://${_dns}"
			;;
			doh)
				local _doh_url=$(echo $direct_dns_doh | awk -F ',' '{print $1}')
				local _doh_host_port=$(lua_api "get_domain_from_url(\"${_doh_url}\")")
				#local _doh_host_port=$(echo $_doh_url | sed "s/https:\/\///g" | awk -F '/' '{print $1}')
				local _doh_host=$(echo $_doh_host_port | awk -F ':' '{print $1}')
				local is_ip=$(lua_api "is_ip(\"${_doh_host}\")")
				local _doh_port=$(echo $_doh_host_port | awk -F ':' '{print $2}')
				[ -z "${_doh_port}" ] && _doh_port=443
				local _doh_bootstrap=$(echo $direct_dns_doh | cut -d ',' -sf 2-)
				[ "${is_ip}" = "true" ] && _doh_bootstrap=${_doh_host}
				[ -n "$_doh_bootstrap" ] && V2RAY_DNS_DIRECT_ARGS="${V2RAY_DNS_DIRECT_ARGS} -direct_dns_server ${_doh_bootstrap}"
				V2RAY_DNS_DIRECT_ARGS="${V2RAY_DNS_DIRECT_ARGS} -direct_dns_port ${_doh_port} -direct_dns_doh_url ${_doh_url} -direct_dns_doh_host ${_doh_host}"
			;;
		esac
		[ -n "$direct_dns_query_strategy" ] && V2RAY_DNS_DIRECT_ARGS="${V2RAY_DNS_DIRECT_ARGS} -dns_query_strategy ${direct_dns_query_strategy}"
		[ -n "$direct_dns_client_ip" ] && V2RAY_DNS_DIRECT_ARGS="${V2RAY_DNS_DIRECT_ARGS} -dns_client_ip ${direct_dns_client_ip}"
		
		lua $UTIL_XRAY gen_dns_config ${V2RAY_DNS_DIRECT_ARGS} > $V2RAY_DNS_DIRECT_CONFIG
		ln_run "$(first_type $(config_t_get global_app ${type}_file) ${type})" ${type} $V2RAY_DNS_DIRECT_LOG run -c "$V2RAY_DNS_DIRECT_CONFIG"
		
		[ "$remote_dns_protocol" != "fakedns" ] && {
			V2RAY_DNS_REMOTE_CONFIG="${TMP_PATH}/${flag}_dns_remote.json"
			V2RAY_DNS_REMOTE_LOG="${TMP_PATH}/${flag}_dns_remote.log"
			V2RAY_DNS_REMOTE_LOG="/dev/null"
			V2RAY_DNS_REMOTE_ARGS="-dns_out_tag remote"
			dns_remote_listen_port=$(get_new_port $(expr $dns_listen_port + 2) udp)
			V2RAY_DNS_REMOTE_ARGS="${V2RAY_DNS_REMOTE_ARGS} -dns_listen_port ${dns_remote_listen_port}"
			case "$remote_dns_protocol" in
				udp)
					local _dns=$(get_first_dns remote_dns_udp_server 53 | sed 's/#/:/g')
					local _dns_address=$(echo ${_dns} | awk -F ':' '{print $1}')
					local _dns_port=$(echo ${_dns} | awk -F ':' '{print $2}')
					V2RAY_DNS_REMOTE_ARGS="${V2RAY_DNS_REMOTE_ARGS} -remote_dns_server ${_dns_address} -remote_dns_port ${_dns_port} -remote_dns_udp_server ${_dns_address}"
				;;
				tcp)
					local _dns=$(get_first_dns remote_dns_tcp_server 53 | sed 's/#/:/g')
					local _dns_address=$(echo ${_dns} | awk -F ':' '{print $1}')
					local _dns_port=$(echo ${_dns} | awk -F ':' '{print $2}')
					V2RAY_DNS_REMOTE_ARGS="${V2RAY_DNS_REMOTE_ARGS} -remote_dns_server ${_dns_address} -remote_dns_port ${_dns_port} -remote_dns_tcp_server tcp://${_dns}"
				;;
				doh)
					local _doh_url=$(echo $remote_dns_doh | awk -F ',' '{print $1}')
					local _doh_host_port=$(lua_api "get_domain_from_url(\"${_doh_url}\")")
					#local _doh_host_port=$(echo $_doh_url | sed "s/https:\/\///g" | awk -F '/' '{print $1}')
					local _doh_host=$(echo $_doh_host_port | awk -F ':' '{print $1}')
					local is_ip=$(lua_api "is_ip(\"${_doh_host}\")")
					local _doh_port=$(echo $_doh_host_port | awk -F ':' '{print $2}')
					[ -z "${_doh_port}" ] && _doh_port=443
					local _doh_bootstrap=$(echo $remote_dns_doh | cut -d ',' -sf 2-)
					[ "${is_ip}" = "true" ] && _doh_bootstrap=${_doh_host}
					[ -n "$_doh_bootstrap" ] && V2RAY_DNS_REMOTE_ARGS="${V2RAY_DNS_REMOTE_ARGS} -remote_dns_server ${_doh_bootstrap}"
					V2RAY_DNS_REMOTE_ARGS="${V2RAY_DNS_REMOTE_ARGS} -remote_dns_port ${_doh_port} -remote_dns_doh_url ${_doh_url} -remote_dns_doh_host ${_doh_host}"
				;;
				fakedns)
					V2RAY_DNS_REMOTE_ARGS="${V2RAY_DNS_REMOTE_ARGS} -remote_dns_fake 1"
				;;
			esac
			
			[ -n "$remote_dns_query_strategy" ] && V2RAY_DNS_REMOTE_ARGS="${V2RAY_DNS_REMOTE_ARGS} -dns_query_strategy ${remote_dns_query_strategy}"
			[ -n "$remote_dns_client_ip" ] && V2RAY_DNS_REMOTE_ARGS="${V2RAY_DNS_REMOTE_ARGS} -dns_client_ip ${remote_dns_client_ip}"
			
			V2RAY_DNS_REMOTE_ARGS="${V2RAY_DNS_REMOTE_ARGS} -remote_dns_outbound_socks_address 127.0.0.1 -remote_dns_outbound_socks_port ${socks_port}"
			lua $UTIL_XRAY gen_dns_config ${V2RAY_DNS_REMOTE_ARGS} > $V2RAY_DNS_REMOTE_CONFIG
			ln_run "$(first_type $(config_t_get global_app ${type}_file) ${type})" ${type} $V2RAY_DNS_REMOTE_LOG run -c "$V2RAY_DNS_REMOTE_CONFIG"
		}
		
		[ -n "$dns_listen_port" ] && _extra_param="${_extra_param} -dns_listen_port ${dns_listen_port}"
		[ -n "$dns_cache" ] && _extra_param="${_extra_param} -dns_cache ${dns_cache}"
		_extra_param="${_extra_param} -dns_query_strategy UseIP"
		_extra_param="${_extra_param} -direct_dns_port ${dns_direct_listen_port} -direct_dns_udp_server 127.0.0.1"
		if [ "$remote_dns_protocol" == "fakedns" ]; then
			_extra_param="${_extra_param} -remote_dns_fake 1"
		else
			_extra_param="${_extra_param} -remote_dns_port ${dns_remote_listen_port} -remote_dns_udp_server 127.0.0.1"
		fi
	}
	
	lua $UTIL_XRAY gen_config -node $node -redir_port $redir_port -tcp_proxy_way $tcp_proxy_way -loglevel $loglevel ${_extra_param} > $config_file
	ln_run "$(first_type $(config_t_get global_app ${type}_file) ${type})" ${type} $log_file run -c "$config_file"
}

run_socks() {
	local flag node bind socks_port config_file http_port http_config_file relay_port log_file
	eval_set_val $@
	[ -n "$config_file" ] && [ -z "$(echo ${config_file} | grep $TMP_PATH)" ] && config_file=$TMP_PATH/$config_file
	[ -n "$http_port" ] || http_port=0
	[ -n "$http_config_file" ] && [ -z "$(echo ${http_config_file} | grep $TMP_PATH)" ] && http_config_file=$TMP_PATH/$http_config_file
	if [ -n "$log_file" ] && [ -z "$(echo ${log_file} | grep $TMP_PATH)" ]; then
		log_file=$TMP_PATH/$log_file
	else
		log_file="/dev/null"
	fi
	local type=$(echo $(config_n_get $node type) | tr 'A-Z' 'a-z')
	local remarks=$(config_n_get $node remarks)
	local server_host=$(config_n_get $node address)
	local port=$(config_n_get $node port)
	[ -n "$relay_port" ] && {
		server_host="127.0.0.1"
		port=$relay_port
	}
	local error_msg tmp

	if [ -n "$server_host" ] && [ -n "$port" ]; then
		check_host $server_host
		[ $? != 0 ] && {
			echolog "  - Socks节点：[$remarks]${server_host} 是非法的服务器地址，无法启动！"
			return 1
		}
		tmp="${server_host}:${port}"
	else
		error_msg="某种原因，此 Socks 服务的相关配置已失联，启动中止！"
	fi
	
	if [ "$type" == "v2ray" ] || [ "$type" == "xray" ]; then
		local protocol=$(config_n_get $node protocol)
		if [ "$protocol" == "_balancing" ] || [ "$protocol" == "_shunt" ] || [ "$protocol" == "_iface" ]; then
			unset error_msg
		fi
	fi

	[ -n "${error_msg}" ] && {
		[ "$bind" != "127.0.0.1" ] && echolog "  - Socks节点：[$remarks]${tmp}，启动中止 ${bind}:${socks_port} ${error_msg}"
		return 1
	}
	[ "$bind" != "127.0.0.1" ] && echolog "  - Socks节点：[$remarks]${tmp}，启动 ${bind}:${socks_port}"

	case "$type" in
	v2ray|\
	xray)
		[ "$http_port" != "0" ] && {
			http_flag=1
			config_file=$(echo $config_file | sed "s/SOCKS/HTTP_SOCKS/g")
			local _extra_param="-local_http_port $http_port"
		}
		lua $UTIL_XRAY gen_config -flag SOCKS_$flag -node $node -local_socks_port $socks_port ${_extra_param} > $config_file
		ln_run "$(first_type $(config_t_get global_app ${type}_file) ${type})" ${type} $log_file run -c "$config_file"
	;;
	naiveproxy)
		lua $UTIL_NAIVE gen_config -node $node -run_type socks -local_addr $bind -local_port $socks_port -server_host $server_host -server_port $port > $config_file
		ln_run "$(first_type naive)" naive $log_file "$config_file"
	;;
	brook)
		local protocol=$(config_n_get $node protocol client)
		local prefix=""
		[ "$protocol" == "wsclient" ] && {
			prefix="ws://"
			local brook_tls=$(config_n_get $node brook_tls 0)
			[ "$brook_tls" == "1" ] && {
				prefix="wss://"
				protocol="wssclient"
			}
			local ws_path=$(config_n_get $node ws_path "/ws")
		}
		server_host=${prefix}${server_host}
		ln_run "$(first_type $(config_t_get global_app brook_file) brook)" "brook_SOCKS_${flag}" $log_file "$protocol" --socks5 "$bind:$socks_port" -s "${server_host}:${port}${ws_path}" -p "$(config_n_get $node password)"
	;;
	ssr)
		lua $UTIL_SS gen_config -node $node -local_addr "0.0.0.0" -local_port $socks_port -server_host $server_host -server_port $port > $config_file
		ln_run "$(first_type ssr-local)" "ssr-local" $log_file -c "$config_file" -v -u
	;;
	ss)
		lua $UTIL_SS gen_config -node $node -local_addr "0.0.0.0" -local_port $socks_port -server_host $server_host -server_port $port -mode tcp_and_udp > $config_file
		ln_run "$(first_type ss-local)" "ss-local" $log_file -c "$config_file" -v
	;;
	ss-rust)
		[ "$http_port" != "0" ] && {
			http_flag=1
			config_file=$(echo $config_file | sed "s/SOCKS/HTTP_SOCKS/g")
			local _extra_param="-local_http_port $http_port"
		}
		lua $UTIL_SS gen_config -node $node -local_socks_port $socks_port -server_host $server_host -server_port $port ${_extra_param} > $config_file
		ln_run "$(first_type sslocal)" "sslocal" $log_file -c "$config_file" -v
	;;
	hysteria)
		[ "$http_port" != "0" ] && {
			http_flag=1
			config_file=$(echo $config_file | sed "s/SOCKS/HTTP_SOCKS/g")
			local _extra_param="-local_http_port $http_port"
		}
		lua $UTIL_HYSTERIA gen_config -node $node -local_socks_port $socks_port -server_host $server_host -server_port $port ${_extra_param} > $config_file
		ln_run "$(first_type $(config_t_get global_app hysteria_file))" "hysteria" $log_file -c "$config_file" client
	;;
	esac

	# http to socks
	[ -z "$http_flag" ] && [ "$http_port" != "0" ] && [ -n "$http_config_file" ] && [ "$type" != "v2ray" ] && [ "$type" != "xray" ] && [ "$type" != "socks" ] && {
		local bin=$(first_type $(config_t_get global_app v2ray_file) v2ray)
		if [ -n "$bin" ]; then
			type="v2ray"
		else
			bin=$(first_type $(config_t_get global_app xray_file) xray)
			[ -n "$bin" ] && type="xray"
		fi
		[ -z "$type" ] && return 1
		lua $UTIL_XRAY gen_proto_config -local_http_port $http_port -server_proto socks -server_address "127.0.0.1" -server_port $socks_port -server_username $_username -server_password $_password > $http_config_file
		ln_run "$bin" ${type} /dev/null run -c "$http_config_file"
	}
	unset http_flag
}

node_switch() {
	local flag new_node shunt_logic
	eval_set_val $@
	[ -n "$flag" ] && [ -n "$new_node" ] && {
		pgrep -af "$TMP_BIN_PATH" | awk -v P1="${flag}" 'BEGIN{IGNORECASE=1}$0~P1 && !/acl\/|acl_/{print $1}' | xargs kill -9 >/dev/null 2>&1
		rm -rf $TMP_PATH/${flag}*
		[ "$shunt_logic" != "0" ] && {
			local node=$(config_t_get global node nil)
			[ "$(config_n_get $node protocol nil)" = "_shunt" ] && {
				if [ "$shunt_logic" = "1" ]; then
					uci set $CONFIG.$node.default_node="$new_node"
				elif [ "$shunt_logic" = "2" ]; then
					uci set $CONFIG.$node.main_node="$new_node"
				fi
				uci commit $CONFIG
			}
			new_node=$node
		}

		[ -s "$TMP_SCRIPT_FUNC_PATH/_${flag}" ] && {
			for filename in $(ls ${TMP_SCRIPT_FUNC_PATH} | grep -v "^_"); do
				cmd=$(cat ${TMP_SCRIPT_FUNC_PATH}/${filename})
				[ -n "$(echo $cmd | grep "${flag}")" ] && rm -f ${TMP_SCRIPT_FUNC_PATH}/${filename}
			done
			local script_func=$(cat $TMP_SCRIPT_FUNC_PATH/_${flag})
			local now_node_arg=$(echo $script_func | grep -o -E "node=.*" | awk -F ' ' '{print $1}')
			new_script_func=$(echo $script_func | sed "s#${now_node_arg}#node=${new_node}#g")
			${new_script_func}
			echo $new_node > $TMP_ID_PATH/${flag}
			
			[ "$shunt_logic" != "0" ] && [ "$(config_n_get $new_node protocol nil)" = "_shunt" ] && {
				echo $(config_n_get $new_node default_node nil) > $TMP_ID_PATH/${flag}_default
				echo $(config_n_get $new_node main_node nil) > $TMP_ID_PATH/${flag}_main
				uci commit $CONFIG
			}

			#uci set $CONFIG.@global[0].node=$node
			#uci commit $CONFIG
			source $APP_PATH/helper_dnsmasq.sh logic_restart no_log=1
		}
	}
}

run_global() {
	[ "$NODE" = "nil" ] && return 1
	TYPE=$(echo $(config_n_get $NODE type nil) | tr 'A-Z' 'a-z')
	[ "$TYPE" = "nil" ] && return 1
	echo $REDIR_PORT > $TMP_PORT_PATH/global
	echo $NODE > $TMP_ID_PATH/global
	[ "$(config_n_get $NODE protocol nil)" = "_shunt" ] && {
		local default_node=$(config_n_get $NODE default_node nil)
		local main_node=$(config_n_get $NODE main_node nil)
		echo $default_node > $TMP_ID_PATH/global_default
		echo $main_node > $TMP_ID_PATH/global_main
	}

	if [ $PROXY_IPV6 == "1" ]; then
		echolog "开启实验性IPv6透明代理(TProxy)，请确认您的节点及类型支持IPv6！"
		PROXY_IPV6_UDP=1
	fi
	V2RAY_ARGS="flag=global node=$NODE redir_port=$REDIR_PORT"
	V2RAY_ARGS="${V2RAY_ARGS} dns_listen_port=${TUN_DNS_PORT} direct_dns_query_strategy=${DIRECT_DNS_QUERY_STRATEGY} remote_dns_query_strategy=${REMOTE_DNS_QUERY_STRATEGY} dns_cache=${DNS_CACHE}"
	local msg="${TUN_DNS} （"
	[ -n "$DIRECT_DNS_PROTOCOL" ] && {
		V2RAY_ARGS="${V2RAY_ARGS} direct_dns_protocol=${DIRECT_DNS_PROTOCOL}"
		case "$DIRECT_DNS_PROTOCOL" in
			auto)
				msg="${msg} 直连DNS：${AUTO_DNS}"
			;;
			udp)
				LOCAL_DNS=${DIRECT_DNS}
				V2RAY_ARGS="${V2RAY_ARGS} direct_dns_udp_server=${DIRECT_DNS}"
				msg="${msg} 直连DNS：${DIRECT_DNS}"
			;;
			tcp)
				V2RAY_ARGS="${V2RAY_ARGS} direct_dns_tcp_server=${DIRECT_DNS}"
				msg="${msg} 直连DNS：${DIRECT_DNS}"
			;;
			doh)
				DIRECT_DNS_DOH=$(config_t_get global direct_dns_doh "https://223.5.5.5/dns-query")
				V2RAY_ARGS="${V2RAY_ARGS} direct_dns_doh=${DIRECT_DNS_DOH}"
				msg="${msg} 直连DNS：${DIRECT_DNS_DOH}"
			;;
		esac
		local _direct_dns_client_ip=$(config_t_get global direct_dns_client_ip)
		[ -n "${_direct_dns_client_ip}" ] && V2RAY_ARGS="${V2RAY_ARGS} direct_dns_client_ip=${_direct_dns_client_ip}"
	}

	[ -n "$REMOTE_DNS_PROTOCOL" ] && {
		V2RAY_ARGS="${V2RAY_ARGS} remote_dns_protocol=${REMOTE_DNS_PROTOCOL}"
		case "$REMOTE_DNS_PROTOCOL" in
			udp*)
				V2RAY_ARGS="${V2RAY_ARGS} remote_dns_udp_server=${REMOTE_DNS}"
				msg="${msg} 远程DNS：${REMOTE_DNS}"
			;;
			tcp)
				V2RAY_ARGS="${V2RAY_ARGS} remote_dns_tcp_server=${REMOTE_DNS}"
				msg="${msg} 远程DNS：${REMOTE_DNS}"
			;;
			doh)
				REMOTE_DNS_DOH=$(config_t_get global remote_dns_doh "https://1.1.1.1/dns-query")
				V2RAY_ARGS="${V2RAY_ARGS} remote_dns_doh=${REMOTE_DNS_DOH}"
				msg="${msg} 远程DNS：${REMOTE_DNS_DOH}"
			;;
			fakedns)
				msg="${msg} 远程DNS：FakeDNS"
			;;
		esac
		local _remote_dns_client_ip=$(config_t_get global remote_dns_client_ip)
		[ -n "${_remote_dns_client_ip}" ] && V2RAY_ARGS="${V2RAY_ARGS} remote_dns_client_ip=${_remote_dns_client_ip}"
	}
	msg="${msg}）"
	echolog ${msg}
	
	source $APP_PATH/helper_dnsmasq.sh stretch
	source $APP_PATH/helper_dnsmasq.sh add TMP_DNSMASQ_PATH=$TMP_DNSMASQ_PATH DNSMASQ_CONF_FILE=/tmp/dnsmasq.d/dnsmasq-passwall2.conf DEFAULT_DNS=$AUTO_DNS LOCAL_DNS=$LOCAL_DNS TUN_DNS=$TUN_DNS

	V2RAY_CONFIG=$TMP_PATH/global.json
	V2RAY_LOG=$TMP_PATH/global.log
	[ "$(config_t_get global close_log 1)" = "1" ] && V2RAY_LOG="/dev/null"
	V2RAY_ARGS="${V2RAY_ARGS} log_file=${V2RAY_LOG} config_file=${V2RAY_CONFIG}"

	node_socks_port=$(config_t_get global node_socks_port 1070)
	V2RAY_ARGS="${V2RAY_ARGS} socks_port=${node_socks_port}"
	echo "127.0.0.1:$node_socks_port" > $TMP_PATH/global_SOCKS_server

	node_http_port=$(config_t_get global node_http_port 0)
	[ "$node_http_port" != "0" ] && V2RAY_ARGS="${V2RAY_ARGS} http_port=${node_http_port}"

	run_v2ray $V2RAY_ARGS
	echo "run_v2ray $V2RAY_ARGS" > $TMP_SCRIPT_FUNC_PATH/_global
}

start_socks() {
	[ "$SOCKS_ENABLED" = "1" ] && {
		local ids=$(uci show $CONFIG | grep "=socks" | awk -F '.' '{print $2}' | awk -F '=' '{print $1}')
		[ -n "$ids" ] && {
			echolog "分析 Socks 服务的节点配置..."
			for id in $ids; do
				local enabled=$(config_n_get $id enabled 0)
				[ "$enabled" == "0" ] && continue
				local node=$(config_n_get $id node nil)
				[ "$node" == "nil" ] && continue
				local port=$(config_n_get $id port)
				local config_file="SOCKS_${id}.json"
				local log_file="SOCKS_${id}.log"
				local http_port=$(config_n_get $id http_port 0)
				local http_config_file="HTTP2SOCKS_${id}.json"
				run_socks flag=$id node=$node bind=0.0.0.0 socks_port=$port config_file=$config_file http_port=$http_port http_config_file=$http_config_file
				echo $node > $TMP_ID_PATH/SOCKS_${id}
			done
		}
	}
}

clean_log() {
	logsnum=$(cat $LOG_FILE 2>/dev/null | wc -l)
	[ "$logsnum" -gt 1000 ] && {
		echo "" > $LOG_FILE
		echolog "日志文件过长，清空处理！"
	}
}

clean_crontab() {
	touch /etc/crontabs/root
	#sed -i "/${CONFIG}/d" /etc/crontabs/root >/dev/null 2>&1
	sed -i "/$(echo "/etc/init.d/${CONFIG}" | sed 's#\/#\\\/#g')/d" /etc/crontabs/root >/dev/null 2>&1
	sed -i "/$(echo "lua ${APP_PATH}/rule_update.lua log" | sed 's#\/#\\\/#g')/d" /etc/crontabs/root >/dev/null 2>&1
	sed -i "/$(echo "lua ${APP_PATH}/subscribe.lua start" | sed 's#\/#\\\/#g')/d" /etc/crontabs/root >/dev/null 2>&1
}

start_crontab() {
	clean_crontab
	[ "$ENABLED" != 1 ] && {
		/etc/init.d/cron restart
		return
	}
	auto_on=$(config_t_get global_delay auto_on 0)
	if [ "$auto_on" = "1" ]; then
		time_off=$(config_t_get global_delay time_off)
		time_on=$(config_t_get global_delay time_on)
		time_restart=$(config_t_get global_delay time_restart)
		[ -z "$time_off" -o "$time_off" != "nil" ] && {
			echo "0 $time_off * * * /etc/init.d/$CONFIG stop" >>/etc/crontabs/root
			echolog "配置定时任务：每天 $time_off 点关闭服务。"
		}
		[ -z "$time_on" -o "$time_on" != "nil" ] && {
			echo "0 $time_on * * * /etc/init.d/$CONFIG start" >>/etc/crontabs/root
			echolog "配置定时任务：每天 $time_on 点开启服务。"
		}
		[ -z "$time_restart" -o "$time_restart" != "nil" ] && {
			echo "0 $time_restart * * * /etc/init.d/$CONFIG restart" >>/etc/crontabs/root
			echolog "配置定时任务：每天 $time_restart 点重启服务。"
		}
	fi

	autoupdate=$(config_t_get global_rules auto_update)
	weekupdate=$(config_t_get global_rules week_update)
	dayupdate=$(config_t_get global_rules time_update)
	if [ "$autoupdate" = "1" ]; then
		local t="0 $dayupdate * * $weekupdate"
		[ "$weekupdate" = "7" ] && t="0 $dayupdate * * *"
		echo "$t lua $APP_PATH/rule_update.lua log > /dev/null 2>&1 &" >>/etc/crontabs/root
		echolog "配置定时任务：自动更新规则。"
	fi

	TMP_SUB_PATH=$TMP_PATH/sub_crontabs
	mkdir -p $TMP_SUB_PATH
	for item in $(uci show ${CONFIG} | grep "=subscribe_list" | cut -d '.' -sf 2 | cut -d '=' -sf 1); do
		if [ "$(config_n_get $item auto_update 0)" = "1" ]; then
			cfgid=$(uci show ${CONFIG}.$item | head -n 1 | cut -d '.' -sf 2 | cut -d '=' -sf 1)
			remark=$(config_n_get $item remark)
			week_update=$(config_n_get $item week_update)
			time_update=$(config_n_get $item time_update)
			echo "$cfgid" >> $TMP_SUB_PATH/${week_update}_${time_update}
			echolog "配置定时任务：自动更新【$remark】订阅。"
		fi
	done

	[ -d "${TMP_SUB_PATH}" ] && {
		for name in $(ls ${TMP_SUB_PATH}); do
			week_update=$(echo $name | awk -F '_' '{print $1}')
			time_update=$(echo $name | awk -F '_' '{print $2}')
			local t="0 $time_update * * $week_update"
			[ "$week_update" = "7" ] && t="0 $time_update * * *"
			cfgids=$(echo -n $(cat ${TMP_SUB_PATH}/${name}) | sed 's# #,#g')
			echo "$t lua $APP_PATH/subscribe.lua start $cfgids > /dev/null 2>&1 &" >>/etc/crontabs/root
		done
		rm -rf $TMP_SUB_PATH
	}

	if [ "$ENABLED_DEFAULT_ACL" == 1 ] || [ "$ENABLED_ACLS" == 1 ]; then
		start_daemon=$(config_t_get global_delay start_daemon 0)
		[ "$start_daemon" = "1" ] && $APP_PATH/monitor.sh > /dev/null 2>&1 &

		AUTO_SWITCH_ENABLE=$(config_t_get auto_switch enable 0)
		[ "$AUTO_SWITCH_ENABLE" = "1" ] && $APP_PATH/test.sh > /dev/null 2>&1 &
	else
		echolog "运行于非代理模式，仅允许服务启停的定时任务。"
	fi

	/etc/init.d/cron restart
}

stop_crontab() {
	clean_crontab
	/etc/init.d/cron restart
	#echolog "清除定时执行命令。"
}

kill_all() {
	kill -9 $(pidof "$@") >/dev/null 2>&1
}

acl_app() {
	local items=$(uci show ${CONFIG} | grep "=acl_rule" | cut -d '.' -sf 2 | cut -d '=' -sf 1)
	[ -n "$items" ] && {
		local index=0
		local item
		local redir_port dns_port dnsmasq_port
		local ipt_tmp msg msg2
		redir_port=11200
		dns_port=11300
		dnsmasq_port=11400
		echolog "访问控制："
		for item in $items; do
			index=$(expr $index + 1)
			local enabled sid remarks sources node direct_dns_protocol direct_dns direct_dns_doh direct_dns_client_ip direct_dns_query_strategy remote_dns_protocol only_proxy_fakedns remote_dns remote_dns_doh remote_dns_client_ip remote_dns_query_strategy
			local _ip _mac _iprange _ipset _ip_or_mac rule_list config_file
			sid=$(uci -q show "${CONFIG}.${item}" | grep "=acl_rule" | awk -F '=' '{print $1}' | awk -F '.' '{print $2}')
			eval $(uci -q show "${CONFIG}.${item}" | cut -d'.' -sf 3-)
			[ "$enabled" = "1" ] || continue
			
			[ -z "${sources}" ] && continue
			for s in $sources; do
				is_iprange=$(lua_api "iprange(\"${s}\")")
				if [ "${is_iprange}" = "true" ]; then
					rule_list="${rule_list}\niprange:${s}"
				elif [ -n "$(echo ${s} | grep '^ipset:')" ]; then
					rule_list="${rule_list}\nipset:${s}"
				else
					_ip_or_mac=$(lua_api "ip_or_mac(\"${s}\")")
					if [ "${_ip_or_mac}" = "ip" ]; then
						rule_list="${rule_list}\nip:${s}"
					elif [ "${_ip_or_mac}" = "mac" ]; then
						rule_list="${rule_list}\nmac:${s}"
					fi
				fi
			done
			[ -z "${rule_list}" ] && continue
			mkdir -p $TMP_ACL_PATH/$sid
			echo -e "${rule_list}" | sed '/^$/d' > $TMP_ACL_PATH/$sid/rule_list
			
			tcp_proxy_mode="global"
			udp_proxy_mode="global"
			node=${node:-default}
			direct_dns_protocol=${direct_dns_protocol:-auto}
			direct_dns=${direct_dns:-119.29.29.29}
			[ "$direct_dns_protocol" = "doh" ] && direct_dns=${direct_dns_doh:-https://223.5.5.5/dns-query}
			direct_dns_query_strategy=${direct_dns_query_strategy:-UseIP}
			remote_dns_protocol=${remote_dns_protocol:-tcp}
			remote_dns=${remote_dns:-1.1.1.1}
			[ "$remote_dns_protocol" = "doh" ] && remote_dns=${remote_dns_doh:-https://1.1.1.1/dns-query}
			remote_dns_query_strategy=${remote_dns_query_strategy:-UseIPv4}
			
			[ "$node" != "nil" ] && {
				if [ "$node" = "default" ]; then
					node=$NODE
					redir_port=$REDIR_PORT
				else
					[ "$(config_get_type $node nil)" = "nodes" ] && {
						if [ "$node" = "$NODE" ]; then
							redir_port=$REDIR_PORT
						else
							redir_port=$(get_new_port $(expr $redir_port + 1))
							eval node_${node}_redir_port=$redir_port

							local type=$(echo $(config_n_get $node type) | tr 'A-Z' 'a-z')
							if [ -n "${type}" ]; then
								config_file=$TMP_ACL_PATH/${node}_TCP_UDP_DNS_${redir_port}.json
								dns_port=$(get_new_port $(expr $dns_port + 1))
								local acl_socks_port=$(get_new_port $(expr $redir_port + $index))
								run_v2ray flag=acl_$sid node=$node redir_port=$redir_port socks_address=127.0.0.1 socks_port=$acl_socks_port dns_listen_port=${dns_port} direct_dns_protocol=${direct_dns_protocol} direct_dns_udp_server=${direct_dns} direct_dns_tcp_server=${direct_dns} direct_dns_doh="${direct_dns}" direct_dns_client_ip=${direct_dns_client_ip} direct_dns_query_strategy=${direct_dns_query_strategy} remote_dns_protocol=${remote_dns_protocol} remote_dns_tcp_server=${remote_dns} remote_dns_udp_server=${remote_dns} remote_dns_doh="${remote_dns}" remote_dns_client_ip=${remote_dns_client_ip} remote_dns_query_strategy=${remote_dns_query_strategy} config_file=${config_file}
							fi
							dnsmasq_port=$(get_new_port $(expr $dnsmasq_port + 1))
							redirect_dns_port=$dnsmasq_port
							mkdir -p $TMP_ACL_PATH/$sid/dnsmasq.d
							default_dnsmasq_cfgid=$(uci show dhcp.@dnsmasq[0] |  awk -F '.' '{print $2}' | awk -F '=' '{print $1}'| head -1)
							[ -s "/tmp/etc/dnsmasq.conf.${default_dnsmasq_cfgid}" ] && {
								cp -r /tmp/etc/dnsmasq.conf.${default_dnsmasq_cfgid} $TMP_ACL_PATH/$sid/dnsmasq.conf
								sed -i "/ubus/d" $TMP_ACL_PATH/$sid/dnsmasq.conf
								sed -i "/dhcp/d" $TMP_ACL_PATH/$sid/dnsmasq.conf
								sed -i "/port=/d" $TMP_ACL_PATH/$sid/dnsmasq.conf
								sed -i "/conf-dir/d" $TMP_ACL_PATH/$sid/dnsmasq.conf
								sed -i "/no-poll/d" $TMP_ACL_PATH/$sid/dnsmasq.conf
								sed -i "/no-resolv/d" $TMP_ACL_PATH/$sid/dnsmasq.conf
							}
							echo "port=${dnsmasq_port}" >> $TMP_ACL_PATH/$sid/dnsmasq.conf
							echo "conf-dir=${TMP_ACL_PATH}/${sid}/dnsmasq.d" >> $TMP_ACL_PATH/$sid/dnsmasq.conf
							echo "server=127.0.0.1#${dns_port}" >> $TMP_ACL_PATH/$sid/dnsmasq.conf
							echo "no-poll" >> $TMP_ACL_PATH/$sid/dnsmasq.conf
							echo "no-resolv" >> $TMP_ACL_PATH/$sid/dnsmasq.conf
							#source $APP_PATH/helper_dnsmasq.sh add TMP_DNSMASQ_PATH=$TMP_ACL_PATH/$sid/dnsmasq.d DNSMASQ_CONF_FILE=/dev/null DEFAULT_DNS=$AUTO_DNS TUN_DNS=127.0.0.1#${dns_port} NO_LOGIC_LOG=1
							ln_run "$(first_type dnsmasq)" "dnsmasq_${sid}" "/dev/null" -C $TMP_ACL_PATH/$sid/dnsmasq.conf -x $TMP_ACL_PATH/$sid/dnsmasq.pid
							eval node_${node}_$(echo -n "${tcp_proxy_mode}${remote_dns}" | md5sum | cut -d " " -f1)=${dnsmasq_port}
							filter_node $node TCP > /dev/null 2>&1 &
							filter_node $node UDP > /dev/null 2>&1 &
						fi
						echo "${node}" > $TMP_ACL_PATH/$sid/var_node
					}
				fi
				echo "${redir_port}" > $TMP_ACL_PATH/$sid/var_port
			}
			[ -n "$redirect_dns_port" ] && echo "${redirect_dns_port}" > $TMP_ACL_PATH/$sid/var_redirect_dns_port
			unset enabled sid remarks sources node direct_dns_protocol direct_dns direct_dns_doh direct_dns_client_ip direct_dns_query_strategy remote_dns_protocol remote_dns remote_dns_doh remote_dns_client_ip remote_dns_query_strategy
			unset _ip _mac _iprange _ipset _ip_or_mac rule_list config_file
			unset redirect_dns_port
		done
		unset redir_port dns_port dnsmasq_port
	}
}

start() {
	pgrep -f /tmp/etc/passwall2/bin > /dev/null 2>&1 && {
		echolog "程序已启动，无需重复启动!"
		return 0
	}

	ulimit -n 65535
	start_socks
	
	local USE_TABLES="iptables"
	if [ -z "$(command -v iptables-legacy || command -v iptables)" ] || [ -z "$(command -v ipset)" ]; then
		echolog "系统未安装iptables或ipset，无法透明代理！"
	fi
	
	[ "$ENABLED_DEFAULT_ACL" == 1 ] && run_global
	source $APP_PATH/${USE_TABLES}.sh start
	[ "$ENABLED_DEFAULT_ACL" == 1 ] && source $APP_PATH/helper_dnsmasq.sh logic_restart
	if [ "$ENABLED_DEFAULT_ACL" == 1 ] || [ "$ENABLED_ACLS" == 1 ]; then
		bridge_nf_ipt=$(sysctl -e -n net.bridge.bridge-nf-call-iptables)
		echo -n $bridge_nf_ipt > $TMP_PATH/bridge_nf_ipt
		sysctl -w net.bridge.bridge-nf-call-iptables=0 >/dev/null 2>&1
		[ "$PROXY_IPV6" == "1" ] && {
			bridge_nf_ip6t=$(sysctl -e -n net.bridge.bridge-nf-call-ip6tables)
			echo -n $bridge_nf_ip6t > $TMP_PATH/bridge_nf_ip6t
			sysctl -w net.bridge.bridge-nf-call-ip6tables=0 >/dev/null 2>&1
		}
	fi
	start_crontab
	echolog "运行完成！\n"
}

stop() {
	clean_log
	source $APP_PATH/iptables.sh stop
	kill_all v2ray-plugin obfs-local
	pgrep -f "sleep.*(6s|9s|58s)" | xargs kill -9 >/dev/null 2>&1
	pgrep -af "${CONFIG}/" | awk '! /app\.sh|subscribe\.lua|rule_update\.lua/{print $1}' | xargs kill -9 >/dev/null 2>&1
	unset V2RAY_LOCATION_ASSET
	unset XRAY_LOCATION_ASSET
	stop_crontab
	source $APP_PATH/helper_dnsmasq.sh del
	source $APP_PATH/helper_dnsmasq.sh restart no_log=1
	[ -s "$TMP_PATH/bridge_nf_ipt" ] && sysctl -w net.bridge.bridge-nf-call-iptables=$(cat $TMP_PATH/bridge_nf_ipt) >/dev/null 2>&1
	[ -s "$TMP_PATH/bridge_nf_ip6t" ] && sysctl -w net.bridge.bridge-nf-call-ip6tables=$(cat $TMP_PATH/bridge_nf_ip6t) >/dev/null 2>&1
	rm -rf ${TMP_PATH}
	rm -rf /tmp/lock/${CONFIG}_script.lock
	echolog "清空并关闭相关程序和缓存完成。"
	exit 0
}

ENABLED=$(config_t_get global enabled 0)
NODE=$(config_t_get global node nil)
[ "$ENABLED" == 1 ] && {
	[ "$NODE" != "nil" ] && [ "$(config_get_type $NODE nil)" != "nil" ] && ENABLED_DEFAULT_ACL=1
}
ENABLED_ACLS=$(config_t_get global acl_enable 0)
[ "$ENABLED_ACLS" == 1 ] && {
	[ "$(uci show ${CONFIG} | grep "@acl_rule" | grep "enabled='1'" | wc -l)" == 0 ] && ENABLED_ACLS=0
}
SOCKS_ENABLED=$(config_t_get global socks_enabled 0)
REDIR_PORT=$(echo $(get_new_port 1041 tcp,udp))
tcp_proxy_way=$(config_t_get global_forwarding tcp_proxy_way redirect)
TCP_NO_REDIR_PORTS=$(config_t_get global_forwarding tcp_no_redir_ports 'disable')
UDP_NO_REDIR_PORTS=$(config_t_get global_forwarding udp_no_redir_ports 'disable')
TCP_REDIR_PORTS=$(config_t_get global_forwarding tcp_redir_ports '22,25,53,143,465,587,853,993,995,80,443')
UDP_REDIR_PORTS=$(config_t_get global_forwarding udp_redir_ports '1:65535')
TCP_PROXY_MODE="global"
UDP_PROXY_MODE="global"
LOCALHOST_PROXY=$(config_t_get global localhost_proxy '1')
DIRECT_DNS_PROTOCOL=$(config_t_get global direct_dns_protocol tcp)
DIRECT_DNS=$(config_t_get global direct_dns 119.29.29.29:53 | sed 's/#/:/g' | sed -E 's/\:([^:]+)$/#\1/g')
DIRECT_DNS_QUERY_STRATEGY=$(config_t_get global direct_dns_query_strategy UseIP)
REMOTE_DNS_PROTOCOL=$(config_t_get global remote_dns_protocol tcp)
REMOTE_DNS=$(config_t_get global remote_dns 1.1.1.1:53 | sed 's/#/:/g' | sed -E 's/\:([^:]+)$/#\1/g')
REMOTE_DNS_QUERY_STRATEGY=$(config_t_get global remote_dns_query_strategy UseIPv4)
DNS_CACHE=$(config_t_get global dns_cache 1)

RESOLVFILE=/tmp/resolv.conf.d/resolv.conf.auto
[ -f "${RESOLVFILE}" ] && [ -s "${RESOLVFILE}" ] || RESOLVFILE=/tmp/resolv.conf.auto

ISP_DNS=$(cat $RESOLVFILE 2>/dev/null | grep -E -o "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | sort -u | grep -v 0.0.0.0 | grep -v 127.0.0.1)
ISP_DNS6=$(cat $RESOLVFILE 2>/dev/null | grep -E "([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4}" | awk -F % '{print $1}' | awk -F " " '{print $2}'| sort -u | grep -v -Fx ::1 | grep -v -Fx ::)

DEFAULT_DNS=$(uci show dhcp | grep "@dnsmasq" | grep "\.server=" | awk -F '=' '{print $2}' | sed "s/'//g" | tr ' ' '\n' | grep -v "\/" | head -2 | sed ':label;N;s/\n/,/;b label')
[ -z "${DEFAULT_DNS}" ] && DEFAULT_DNS=$(echo -n $ISP_DNS | tr ' ' '\n' | head -2 | tr '\n' ',')
AUTO_DNS=${DEFAULT_DNS:-119.29.29.29}

PROXY_IPV6=$(config_t_get global_forwarding ipv6_tproxy 0)

export V2RAY_LOCATION_ASSET=$(config_t_get global_rules v2ray_location_asset "/usr/share/v2ray/")
export XRAY_LOCATION_ASSET=$V2RAY_LOCATION_ASSET
mkdir -p /tmp/etc $TMP_PATH $TMP_BIN_PATH $TMP_SCRIPT_FUNC_PATH $TMP_ID_PATH $TMP_PORT_PATH $TMP_ROUTE_PATH $TMP_ACL_PATH $TMP_PATH2

arg1=$1
shift
case $arg1 in
get_new_port)
	get_new_port $@
	;;
run_v2ray)
	run_v2ray $@
	;;
run_socks)
	run_socks $@
	;;
node_switch)
	node_switch $@
	;;
echolog)
	echolog $@
	;;
stop)
	stop
	;;
start)
	start
	;;
esac
