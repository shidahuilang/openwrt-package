#!/bin/sh

. /lib/functions.sh
. /lib/config/uci.sh

setup_switch() {
	echo "setup_switch"

	# if eth0 not up,action of switch setting will crash
	ifconfig eth0 up

	# reset switch
	switch 2
	#	/etc/init.d/macbind2port reload

	mode=$(uci_get switchmode.settings.mode)
	wifich=$(uci_get wireless.wlan0.channel)

	# a urgly method!
	# change wifi channel,force wifi reload, so than 'brctl addif wlan0' be executed
	#	if [ "$wifich" -eq 14 ]; then
	#		wifich=11
	#	else
	#		wifich=$(expr $wifich + 1);
	#	fi

	if [ "$mode" = "1" ]; then
		uci -q batch <<-EOF
			set network.wan.device='eth0.1'
			set network.wan6.device='eth0.1'
			set network.lan=interface
			set network.lan.type='bridge'
			set network.lan.proto='static'
			set network.lan.ipaddr='192.168.1.1'
			set network.lan.netmask='255.255.255.0'
			set network.lan.ip6assign='60'
			set network.lan.device='eth0.2'
			set wireless.wlan0.channel='$wifich'
		EOF
		# WLLL,router mode
		switch 1
	elif [ "$mode" = "0" ]; then
		uci -q batch <<-EOF
			set network.wan.device='eth0'
			set network.wan6.device='eth0'
			delete network.lan
			set network.lan.ip6assign='60'
			set network.lan=interface
			set network.lan.type='bridge'
			set network.lan.proto='static'
			set network.lan.ipaddr='192.168.1.1'
			set network.lan.netmask='255.255.255.0'
			set network.lan.device='wlan0'
			set wireless.wlan0.channel='$wifich'
		EOF
		# restore_ip175d, defualt is switch mode
		switch 0
	else
		echo "invalid mode value"
	fi
	uci commit
}

reset_switch() {
	# reset ip175d
	switch 2
	echo "reset_switch"
}
