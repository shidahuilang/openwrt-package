#!/bin/sh
LOCK_DIR="/var/run/ssrplusupdate.lock"
LOOP_STAMP="/var/run/ssrplusupdate.loop"
MODE="$(uci -q get shadowsocksr.@server_subscribe[0].config_auto_update_mode 2>/dev/null || echo 0)"

mkdir "$LOCK_DIR" 2>/dev/null || exit 0
trap 'rmdir "$LOCK_DIR" 2>/dev/null' EXIT INT TERM

if [ "$1" = "loop" ]; then
	[ "$(uci -q get shadowsocksr.@server_subscribe[0].auto_update 2>/dev/null || echo 0)" = "1" ] || exit 0
	[ "$MODE" = "1" ] || exit 0

	INTERVAL="$(uci -q get shadowsocksr.@server_subscribe[0].config_update_interval 2>/dev/null || echo 60)"
	case "$INTERVAL" in
		''|*[!0-9]*)
			INTERVAL=60
		;;
	esac
	[ "$INTERVAL" -gt 0 ] 2>/dev/null || INTERVAL=60

	NOW="$(date +%s)"
	LAST_RUN=0
	[ -f "$LOOP_STAMP" ] && LAST_RUN="$(cat "$LOOP_STAMP" 2>/dev/null || echo 0)"
	case "$LAST_RUN" in
		''|*[!0-9]*)
			LAST_RUN=0
		;;
	esac

	if [ $((NOW - LAST_RUN)) -lt $((INTERVAL * 60)) ]; then
		exit 0
	fi
fi

/usr/bin/lua /usr/share/shadowsocksr/update.lua
sleep 2s
/usr/share/shadowsocksr/chinaipset.sh /var/etc/ssrplus/china_ssr.txt
sleep 2s
/usr/bin/lua /usr/share/shadowsocksr/subscribe.lua

if [ "$1" = "loop" ]; then
	date +%s > "$LOOP_STAMP"
fi
