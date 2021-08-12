#!/bin/bash
# Copyright (C) 2017 XiaoShan https://www.mivm.cn

online_list=($(grep -v "0x0" /proc/net/arp | grep "br-lan" |awk '{print $1}'))
mac_online_list=($(grep -v "0x0" /proc/net/arp | grep "br-lan" |awk '{print $4}'))

arp_ip=($(grep "br-lan" /proc/net/arp | awk '{print $1}'))

uci show k3screenctrl > /tmp/k3_custom

if [ -z "$(iptables --list | grep UPSP)" -a -z "$(iptables --list | grep DWSP)" ]; then
	iptables -N UPSP
	iptables -N DWSP
	mkdir /tmp/lan_speed
fi
for ((i=0;i<${#arp_ip[@]};i++))
do
	if [ -z "$(iptables -nvx -L FORWARD | grep DWSP | grep ${arp_ip[i]} -w)" -a -z "$(iptables -nvx -L FORWARD | grep UPSP | grep ${arp_ip[i]} -w)" ]; then
		iptables -I FORWARD 1 -s ${arp_ip[i]} -j UPSP
		iptables -I FORWARD 1 -d ${arp_ip[i]} -j DWSP
		echo $(date +%s) > /tmp/lan_speed/${arp_ip[i]}
		echo 0 >> /tmp/lan_speed/${arp_ip[i]}
		echo 0 >> /tmp/lan_speed/${arp_ip[i]}
	fi
done

if [ -s /tmp/lan_online_list.temp ]; then
	cat /tmp/lan_online_list.temp
	rm /tmp/lan_online_list.temp
	exit 0
else
	echo ${#online_list[@]}
fi

for ((i=0;i<${#online_list[@]};i++))
do
	hostname[i]=$(grep ${online_list[i]} -w /tmp/dhcp.leases | awk '{print $4}')
	hostmac=${mac_online_list[i]//:/} && hostmac=${hostmac:0:6}
	logo[i]=$(grep -i $hostmac /lib/k3screenctrl/oui/oui.txt | awk '{print $1}')
	
	#for k3_custom
	tmp_mac=$(echo ${mac_online_list[i]} | tr 'a-z' 'A-Z')
	tmp_uci=$(cat /tmp/k3_custom | grep $tmp_mac | awk -F'=' '{print $1}' | awk -F'.' '{print$1"."$2}')
	if [ -n "$tmp_uci" ];then
		hostname[i]=$(uci get $tmp_uci.name)
		logo[i]=$(uci get $tmp_uci.icon)
	fi

	last_speed_time=$(cut -d$'\n' -f,1 /tmp/lan_speed/${online_list[i]})
	last_speed_up=$(cut -d$'\n' -f,2 /tmp/lan_speed/${online_list[i]})
	last_speed_dw=$(cut -d$'\n' -f,3 /tmp/lan_speed/${online_list[i]})
	now_speed_time=$(date +%s)
	now_speed_up=$(iptables -nvx -L FORWARD | grep UPSP | grep ${online_list[i]} -w  | awk '{print $2}')
	now_speed_dw=$(iptables -nvx -L FORWARD | grep DWSP | grep ${online_list[i]} -w  | awk '{print $2}')

	if [ -z "${last_speed_time}" ]; then
		last_speed_time=0
	fi
	if [ -z "${last_speed_up}" ]; then
		last_speed_up=0
	fi
	if [ -z "${last_speed_dw}" ]; then
		last_speed_dw=0
	fi
	time_s=$(($now_speed_time - $last_speed_time))
	if [ $time_s -eq 0 ];then
		time_s=1
	fi
	up_sp[i]=$((($now_speed_up - $last_speed_up) / $time_s))
	dw_sp[i]=$((($now_speed_dw - $last_speed_dw) / $time_s))
	echo $now_speed_time > /tmp/lan_speed/${online_list[i]}
	echo $now_speed_up >> /tmp/lan_speed/${online_list[i]}
	echo $now_speed_dw >> /tmp/lan_speed/${online_list[i]}

	if [ -z "${hostname[i]}" -o "${hostname[i]}" = "*" ]; then
		hostname[i]="Unknown"
	fi
	if [ -z "${logo[i]}" ]; then
		logo[i]="0"
	fi
	echo "${hostname[i]}"
	echo "${dw_sp[i]}"
	echo "${up_sp[i]}"
	echo "${logo[i]}"
done

now_arp_refresh_time=$(date +%s)
if [ -s /tmp/arp_refresh_time ]; then
	last_arp_refresh_time=$(cat /tmp/arp_refresh_time)
	if [ $(($now_arp_refresh_time - $last_arp_refresh_time)) -ge 600 ]; then
		echo ${#online_list[@]} > /tmp/lan_online_list.temp
		for ((i=0;i<${#online_list[@]};i++))
		do
			#arp -d ${online_list[i]}
			echo "${hostname[i]}" >> /tmp/lan_online_list.temp
			echo "${dw_sp[i]}" >> /tmp/lan_online_list.temp
			echo "${up_sp[i]}" >> /tmp/lan_online_list.temp
			echo "${logo[i]}" >> /tmp/lan_online_list.temp
		done
		echo 0 >> /tmp/lan_online_list.temp
		echo $now_arp_refresh_time > /tmp/arp_refresh_time
	fi
else
	echo $now_arp_refresh_time > /tmp/arp_refresh_time
fi

echo 0
