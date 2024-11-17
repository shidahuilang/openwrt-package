#!/bin/sh
#
# Depends: coreutils-timeout
#
# Author: muink
# Github: https://github.com/muink/luci-app-natmap
#
# Args: <udp stun server:port> <tcp stun server:port> <localport> [output]
[ "$#" -ge 3 ] || exit 1
udpstun="$1" && shift
tcpstun="$1" && shift
port="$1" && shift
[ -n "$1" ] && output="$1"

[ "$(echo "$udpstun" | sed 's|[A-Za-z0-9:.-]||g')" == "" ] || exit 1
[ "$(echo "$tcpstun" | sed 's|[A-Za-z0-9:.-]||g')" == "" ] || exit 1
[ "$(echo "$port" | sed 's|[0-9]||g')" == "" ] || exit 1

PROG="/usr/libexec/natmap/natmap-natest"
if [ -x "$(command -v stunclient)" ]; then ln -s "$(command -v stunclient)" "$PROG" 2>/dev/null; else exit 1; fi

#/etc/init.d/firewall reload >/dev/null 2>&1

udp_result="$(timeout 30 $PROG --protocol udp --mode full --localport $port ${udpstun%:*} ${udpstun#*:} 2>/dev/null)"
tcp_result="$(timeout 10 $PROG --protocol tcp --mode full --localport $port ${tcpstun%:*} ${udpstun#*:} 2>/dev/null)"

cat <<- EOF
UDP TEST:
${udp_result:=Test timeout}

TCP TEST:
${tcp_result:=Test timeout}

EOF

render() {
echo "$1" | sed -E "\
	s,\b((S|s)uccess)\b,<font color=\"green\">\1</font>,g;\
	s,\b((F|f)ail)\b,<font color=\"#ff331f\">\1</font>,g;\
	s|(Nat behavior:\s*)\b(Unknown Behavior)\b|\1<font color=\"#808080\">\2</font>|g;\
	s|(Nat behavior:\s*)\b(Direct Mapping)\b|\1<font color=\"#1e96fc\">\2</font>|g;\
	s|(Nat behavior:\s*)\b(Endpoint Independent Mapping)\b|\1<font color=\"#7cfc00\">\2</font>|g;\
	s|(Nat behavior:\s*)\b(Address Dependent Mapping)\b|\1<font color=\"#ffc100\">\2</font>|g;\
	s|(Nat behavior:\s*)\b(Address and Port Dependent Mapping)\b|\1<font color=\"#ff8200\">\2</font>|g;\
	s|(Nat behavior:\s*)\b(Unknown NAT Behavior)\b|\1<font color=\"#808080\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Unknown Filtering)\b|\1<font color=\"#808080\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Direct Mapping (Filtering))\b|\1<font color=\"#1e96fc\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Endpoint Independent Filtering)\b|\1<font color=\"#7cfc00\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Address Dependent Filtering)\b|\1<font color=\"#ffc100\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Address and Port Dependent Filtering)\b|\1<font color=\"#ff8200\">\2</font>|g;\
	s|(Nat filtering:\s*)\b(Unknown NAT Filtering)\b|\1<font color=\"#808080\">\2</font>|g;\
	s|(:\s*)(.*)$|\1<b>\2</b><br>|g"
}

if [ -n "$output" ]; then
	cat <<- EOF > "$output"
	<table><tbody>
	<tr><td>UDP TEST</td><td>TCP TEST</td></tr>
	<tr>
	<td>
	$(render "$udp_result")
	</td>
	<td>
	$(render "$tcp_result")
	</td>
	</tr>
	</tbody></table>
	EOF
fi
#/usr/libexec/natmap/natcheck.sh stun.miwifi.com:3478 stunserver.stunprotocol.org:3478 3445 /tmp/natmap-natBehavior
