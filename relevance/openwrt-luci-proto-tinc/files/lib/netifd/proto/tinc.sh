#!/bin/sh

[ -x /usr/sbin/tincd ] || exit 0

[ -n "$INCLUDE_ONLY" ] || {
	. /lib/functions.sh
	. ../netifd-proto.sh
	init_proto "$@"
}

proto_tinc_append() {
	append "$3" "$1"
}

proto_tinc_init_config() {
	no_device=1
	available=1
	renew_handler=1

	proto_config_add_string ipaddr
	proto_config_add_string ip6addr
	proto_config_add_string name
	proto_config_add_string bindtoaddr
	proto_config_add_string 'mode:or("router","switch","hub")'
	proto_config_add_string 'priority:or("low","normal","high")'
	proto_config_add_string 'strict_subnets:or("no","yes")'
	proto_config_add_array 'connect:list(string)'
	proto_config_add_array 'option:list(string)'
	proto_config_add_array 'subnet:list(string)'
	proto_config_add_array 'route:list(string)'
	proto_config_add_int mtu
}

proto_tinc_setup() {
	local config="$1"

	local ipaddr ip6addr name bindtoaddr connect connects mode priority strict_subnets option options subnet subnets route routes mtu
	json_get_vars ipaddr ip6addr name bindtoaddr mode priority strict_subnets mtu
	json_for_each_item proto_tinc_append connect connects
	json_for_each_item proto_tinc_append option options
	json_for_each_item proto_tinc_append subnet subnets
	json_for_each_item proto_tinc_append route routes

	proto_export CONFIG="$config"
	proto_export IPADDR="$ipaddr"
	proto_export IP6ADDR="$ip6addr"
	proto_export ROUTES="$routes"
	proto_export MTU="$mtu"

	config_dir="/etc/tinc/$config"
	tmp_config_dir="/tmp/tinc/$config"
	tmp_config_file="$tmp_config_dir/tinc.conf"

	rm -rf $tmp_config_dir
	cp -rf $config_dir $tmp_config_dir
	cp -f /lib/netifd/tinc.script $tmp_config_dir/tinc-up
	chmod 755 $tmp_config_dir/tinc-up

	mkdir -p $config_dir/hosts $tmp_config_dir/hosts
	{
		echo "Name=$name"
		echo "Interface=tinc-$config"
		echo "Mode=$mode"

		[ -z "$bindtoaddr" ] || echo "BindToAddress=$bindtoaddr"
		[ -z "$priority" ] || echo "ProcessPriority=$priority"
		[ -z "$strict_subnets" ] || echo "StrictSubnets=$strict_subnets"

		for host in $connects; do
			echo "ConnectTo=$host"
		done

		for option in $options; do
			echo "$option"
		done
	} > $tmp_config_file

	if [ ! -f $tmp_config_dir/hosts/$name ]; then
		tincd -c $tmp_config_dir -K
		cp -f $tmp_config_dir/*.priv $config_dir
		cp -rf $tmp_config_dir/hosts $config_dir
	fi

	{
		if [ -n "$ipaddr" ]; then
			echo "Subnet=${ipaddr%%/*}/32"
		fi
		if [ -n "$ip6addr" ]; then
			echo "Subnet=${ip6addr%%/*}/128"
		fi
		for subnet in $subnets; do
			echo "Subnet=$subnet"
		done
		cat $config_dir/hosts/$name
	} > $tmp_config_dir/hosts/$name

	proto_run_command "$config" /usr/sbin/tincd \
		-c $tmp_config_dir \
		--no-detach \
		--pidfile=/var/run/tinc.${config}.pid \
		--logfile=/tmp/log/tinc.${config}.log
}

proto_tinc_teardown() {
	local config="$1"
	logger -t tinc "stopping..."
	proto_kill_command "$config" 9
}

proto_tinc_renew() {
	local iface="$1"
	logger -t tinc "renew $iface ..."
}

[ -n "$INCLUDE_ONLY" ] || {
	add_protocol tinc
}

