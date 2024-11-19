#!/bin/sh

. /lib/functions.sh
. /lib/functions/network.sh
. ../netifd-proto.sh
init_proto "$@"

proto_t2s_init_config(){
	no_device=1
	available=1
	proto_config_add_string "ipaddr"
	proto_config_add_string "netmask"
	proto_config_add_string "gateway"
	proto_config_add_string "host"
	proto_config_add_string "proxy"
	proto_config_add_string "encrypt"
	proto_config_add_string "loglevel"
	proto_config_add_string "obfs_host"
	proto_config_add_string "username"
	proto_config_add_string "password"
	proto_config_add_string "opts"
	proto_config_add_string "sockpath"
	proto_config_add_int "mtu"
	proto_config_add_int "fwmark"
	proto_config_add_boolean "socket"
	proto_config_add_boolean "base64enc"
	proto_config_add_defaults
}

check_encrypt(){
	case $encrypt in
		"none"|\
		"table"|\
		"rc4"|\
		"rc4-md5"|\
		"aes-128-cfb"|\
		"aes-192-cfb"|\
		"aes-256-cfb"|\
		"aes-128-ctr"|\
		"aes-192-ctr"|\
		"aes-256-ctr"|\
		"aes-128-gcm"|\
		"aes-192-gcm"|\
		"aes-256-gcm"|\
		"camellia-128-cfb"|\
		"camellia-192-cfb"|\
		"camellia-256-cfb"|\
		"bf-cfb"|\
		"salsa20"|\
		"chacha20"|\
		"chacha20-ietf"|\
		"chacha20-ietf-poly1305"|\
		"xchacha20-ietf-poly1305")
				continue
		;;
		*)
			proto_notify_error "$interface" WRONG_ENCRYPT_METHOD
			proto_set_available "$interface" 0
		;;
	esac
}

proto_t2s_setup(){
	local interface="$1"
	local ifname ipaddr netmask gateway host proxy encrypt loglevel fwmark 
	local base64enc socket obfs_host port mtu
	local username password opts sockpath $PROTO_DEFAULT_OPTIONS
	json_get_vars ifname ipaddr netmask gateway host proxy encrypt loglevel fwmark
	json_get_vars base64enc socket obfs_host port mtu
	json_get_vars username password opts sockpath $PROTO_DEFAULT_OPTIONS
	ifname=$interface
	[ "$metric" = "" ] && metric="0"
	[ "$proxy" = "" ] && proxy=socks5
	[ "$loglevel" = "" ] && loglevel=error
	[ "$host" ] && {
		case "$proxy" in
			http) ARGS="-proxy ${proxy}://${host}" ;;
			socks4)
				[ "$username" ] && {
					ARGS="-proxy ${proxy}://${username}@${host}"
				} || {
					ARGS="-proxy ${proxy}://${host}"
				}
			;;
			socks5)
				[ "$username" -a "$password" ] && {
					ARGS="-proxy ${proxy}://${username}:${password}@${host}"
				} || {
					ARGS="-proxy ${proxy}://${host}"
				}
			;;
			ss)
				#check_encrypt
				[ "$encrypt" -a "$password" ] && {
					[ "$base64enc" = "1" ] && {
						base64gen=$(echo ${encrypt}:${password} | base64)
						[ "$obfs_host" ] && {
							ARGS="-proxy ${proxy}://${base64gen}@${host}/\<\?obfs=http\;obfs-host=$obfs_host\>"
						} || {
							ARGS="-proxy ${proxy}://${base64gen}@${host}"
						}
					} || {
						[ "$obfs_host" ] && {
							ARGS="-proxy ${proxy}://${encrypt}:${password}@${host}/\<\?obfs=http\;obfs-host=$obfs_host\>"
						} || {
							ARGS="-proxy ${proxy}://${encrypt}:${password}@${host}"
						}
					}
				} || {
					proto_notify_error "$interface" CONFIGURE_FAILED
					proto_set_available "$interface" 0
				}
			;;
			relay)
				[ "$username" -a "$password" ] && {
					ARGS="-proxy ${proxy}://${encrypt}:${password}@${host}/\<nodelay=false\>"
				} || {
					ARGS="-proxy ${proxy}://${host}/\<nodelay=false\>"
				}
			;;
		esac
	}

	case $proxy in
		direct|reject) ARGS="-proxy ${proxy}://" ;;
		socks5)
			[ "$socket" ] &&  {
				[ "$sockpath" ] && {
					ARGS="-proxy ${proxy}://${sockpath}"
				} || {
					proto_notify_error "$interface" CONFIGURE_FAILED
					proto_set_available "$interface" 0
				}
			}
		;;
	esac

	[ "x${ARGS}" = "x" ] && {
		proto_notify_error "$interface" CONFIGURE_FAILED
		proto_set_available "$interface" 0
	}

	[ "$loglevel" ] && {
		ARGS="$ARGS -loglevel $loglevel"
	}

	[ "$fwmark" ] && {
		ARGS="$ARGS -fwmark $fwmark"
	}

	[ "$mtu" ] && {
		ARGS="$ARGS -mtu $mtu"
	}

	[ "$opts" ] && {
		 ARGS="$ARGS $opts"
	}

	proto_init_update "$interface" 1
	proto_add_data
	proto_close_data
	ip tuntap add mode tun dev $interface
	proto_set_keep 1
	proto_add_ipv4_address $ipaddr $netmask
	[ $gateway ] && {
		proto_add_ipv4_route "0.0.0.0" 0 $gateway $ipaddr
	}
	proto_add_data
	proto_close_data
	proto_send_update "$interface"
	proto_run_command "$interface" /usr/sbin/tun2socks \
		-device "$interface" $ARGS
}

proto_t2s_teardown(){
	local interface="$1"
	proto_kill_command "$interface"
	ip tuntap del mode tun dev $interface
}

add_protocol t2s
