#!/bin/bash
export ip="$1"
export port="$2"
export ip4p="$3"
export inner_port="$4"
export protocol="$5"
export inner_ip="$6"
shift 6

. /usr/share/libubox/jshn.sh
INITD='/etc/init.d/natmap'
STATUS_PATH='/var/run/natmap'

if [ -n "$RWFW" -a "$($INITD info|jsonfilter -qe "@['$(basename $INITD)'].instances['$SECTIONID'].data.firewall[0].dest_port")" != "$port" ]; then
	export PUBPORT="$port" #PROCD_DEBUG=1
	$INITD start "$SECTIONID"
fi
(
	json_init
	json_add_string sid "$SECTIONID"
	json_add_string comment "$COMMENT"
	json_add_string ip "$ip"
	json_add_int port "$port"
	json_add_string ip4p "$ip4p"
	json_add_int inner_port "$inner_port"
	json_add_string protocol "$protocol"
	json_add_string inner_ip "$inner_ip"
	json_dump > "$STATUS_PATH/$PPID.json"
)

if [ -n "$REFRESH" ]; then
	json_init
	json_load "$REFRESH_PARAM"
	json_add_int port "$port"
	$REFRESH "$(json_dump)"
fi
if [ -n "$NOTIFY" ]; then
	_text="$(jsonfilter -qs "$NOTIFY_PARAM" -e '@["text"]')"
	[ -z "$_text" ] && _text="NATMap: ${COMMENT:+$COMMENT: }[${protocol^^}] $inner_ip:$inner_port -> $ip:$port" \
	|| _text="$(echo "$_text" | sed " \
		s|<comment>|$COMMENT|g; \
		s|<protocol>|$protocol|g; \
		s|<inner_ip>|$inner_ip|g; \
		s|<inner_port>|$inner_port|g; \
		s|<ip>|$ip|g; \
		s|<port>|$port|g")"
	json_init
	json_load "$NOTIFY_PARAM"
	json_add_string comment "$COMMENT"
	json_add_string text "$_text"
	$NOTIFY "$(json_dump)"
fi
if [ -n "$DDNS" ]; then
	_hostype="$(jsonfilter -qs "$DDNS_PARAM" -e '@["hostype"]')"
	_svcparams="$(jsonfilter -qs "$DDNS_PARAM" -e '@["https_svcparams"]')"
	_svcparams="$(echo "$_svcparams" | sed -E "s,\s*(port=\d*|$), port=${port},")" # port
	[ "$_hostype" = A ]    && _svcparams="$(echo "$_svcparams" | sed -E "s|\b(ipv4hint=)[\d\.]*|\1${ip}|")" # ipv4hint
	[ "$_hostype" = AAAA ] && _svcparams="$(echo "$_svcparams" | sed -E "s|\b(ipv6hint=)[[:xdigit:]:\.]*|\1${ip}|")" # ipv6hint
	json_init
	json_load "$DDNS_PARAM"
	json_add_string https_svcparams "$_svcparams"
	json_add_string ip "$ip"
	json_add_int port "$port"
	$DDNS "$(json_dump)"
fi

[ -n "${CUSTOM_SCRIPT}" ] && {
	export -n CUSTOM_SCRIPT
	exec "${CUSTOM_SCRIPT}" "$ip" "$port" "$ip4p" "$inner_port" "$protocol" "$inner_ip" "$SECTIONID" "$COMMENT" "$@"
}
