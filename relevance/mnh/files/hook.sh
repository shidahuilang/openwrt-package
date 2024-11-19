#!/bin/sh

# Global variable
name="$1"
type="$2"
event="$3"
errmsg="$4"
port="$5"
addr="$6"

iptables_check_and_append() {
	iptables -t "filter" -C "MNH" $@ 2>/dev/null \
	|| iptables -t "filter" -A "MNH" $@
}

insert_iptables_rule() {
	iptables_check_and_append -p $type -m $type --dport $port -j ACCEPT
}

remove_iptables_rule() {
	iptables -t "filter" -D "MNH" -p $type -m $type --dport $port -j ACCEPT
}

nft_check_and_append() {
	nft list chain inet fw4 "mnh" | grep -q "$*" 2>/dev/null \
	|| nft add rule inet fw4 "mnh" $@
}

insert_nft_rule() {
	nft_check_and_append $type dport $port accept
}

remove_nft_rule() {
	handle="$(
		nft list chain inet fw4 "mnh" \
		| grep "$type dport $port accept" \
		| sed -E 's/^.*# handle ([0-9]+)$/\1/'
	)"
	nft rule delete inet fw4 "mnh" handle $handle
}

main() {
	cat <<-EOF >"/var/run/mnh/$name"
		${event}
		${errmsg}
		${port}
		${addr}
	EOF

	case "$event" in
		success)
			if fw4 >/dev/null; then
				insert_nft_rule
			else
				insert_iptables_rule
			fi
			;;

		disconnected)
			if fw4 >/dev/null; then
				remove_nft_rule
			else
				remove_iptables_rule
			fi
			;;

	esac
}

main
