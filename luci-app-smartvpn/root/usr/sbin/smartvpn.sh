#!/bin/sh

############################################
# smartvpn control scrip for OpenWRT
# create by Daniel Yang 2021-06-18
############################################

. /lib/functions.sh
. /lib/functions/network.sh

SMARTVPN_VER='v1.1.4'

smartvpn_logger()
{
    logger -s -t smartvpn "$1"
}

# do not destroy ipset(mwan3 firewall rule still need it)
smartvpn_ipset_delete()
{

    if [[ "$SOFT" != "soft" ]]; then

        smartvpn_logger "Flush ipset for host and network segment..."

        ipset flush ip_oversea
        ipset flush net_oversea

        ipset flush ip_hongkong
        ipset flush net_hongkong

        ipset flush ip_mainland
        ipset flush net_mainland
    fi

    return
}

ipset_create(){
    local _ipset=$1
    local _type=$2

    ipset list | grep $_ipset > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        ipset create $_ipset hash:$_type >/dev/null 2>&1
    else
        [[ "$3" == "hard" ]] && ipset flush $_ipset
    fi    
}

smartvpn_ipset_create()
{

    smartvpn_logger "creating ipset for host..."
    if [[ "$SOFT" = "soft" ]]; then
        smartvpn_logger "soft mode: keep ipset for host"
    fi

    if [[ $vpn_status == "on" && "$SOFT" != "hard"  ]];
    then
        smartvpn_logger "SmartVPN already on, try a soft restart..."
    fi

    ipset_create ip_oversea ip $SOFT
    ipset_create ip_hongkong ip $SOFT
    ipset_create ip_mainland ip $SOFT

    ipset_create net_oversea net
    ipset_create net_hongkong net
    ipset_create net_mainland net 
}

smartvpn_ipset_add_by_file()
{
    local _ipfile=$1
    local _ipset_name=$2

    smartvpn_logger "add network segments to ipset $_ipset_name."
    cat $_ipfile | while read line
    do
        if [ -n "$line" ]; then
            ipset add $_ipset_name $line >/dev/null 2>&1
        fi
    done
}

dnsmasq_conf_path="/etc/dnsmasq.d/"
smartdns_conf_path="/etc/smartvpn/"

smartvpn_enable()
{

    # 根据proxy.txt生成dnsmasq配置
    gensmartdns.sh "/etc/smartvpn/proxy_oversea.txt" "/tmp/dm_oversea.conf" "/tmp/smartvpn_ip.txt" "ip_oversea" "8.8.8.8" > /dev/null 2>&1
    if [ -f /etc/smartvpn/user_oversea.txt ]; then 
        gensmartdns.sh "/etc/smartvpn/user_oversea.txt" "/tmp/dm_oversea.conf" "/tmp/smartvpn_ip.txt" "ip_oversea" "8.8.8.8" append > /dev/null 2>&1
    fi 


    [ -f /tmp/smartvpn_ip.txt ] && {
        smartvpn_ipset_add_by_file /tmp/smartvpn_ip.txt net_oversea
        hostlist_not_null=1
        rm /tmp/smartvpn_ip.txt
    }

    gensmartdns.sh "/etc/smartvpn/proxy_hongkong.txt" "/tmp/dm_hongkong.conf" "/tmp/smartvpn_ip.txt" "ip_hongkong" "1.1.1.1" > /dev/null 2>&1
    if [ -f /etc/smartvpn/user_hongkong.txt ]; then
        gensmartdns.sh "/etc/smartvpn/user_hongkong.txt" "/tmp/dm_hongkong.conf" "/tmp/smartvpn_ip.txt" "ip_hongkong" "1.1.1.1" append > /dev/null 2>&1
    fi

    [ -f /tmp/smartvpn_ip.txt ] && {
        smartvpn_ipset_add_by_file /tmp/smartvpn_ip.txt net_hongkong
        hostlist_not_null=1
        rm /tmp/smartvpn_ip.txt
    }

    gensmartdns.sh "/etc/smartvpn/proxy_mainland.txt" "/tmp/dm_mainland.conf" "/tmp/smartvpn_ip.txt" "ip_mainland" $DNS_MAINLAND > /dev/null 2>&1
    if [ -f /etc/smartvpn/user_mainland.txt ]; then
        gensmartdns.sh "/etc/smartvpn/user_mainland.txt" "/tmp/dm_mainland.conf" "/tmp/smartvpn_ip.txt" "ip_mainland" $DNS_MAINLAND append > /dev/null 2>&1
    fi

    [ -f /tmp/smartvpn_ip.txt ] && {
        smartvpn_ipset_add_by_file /tmp/smartvpn_ip.txt net_mainland
        hostlist_not_null=1
        rm /tmp/smartvpn_ip.txt
    }

    smartvpn_ipset_create   # 创建ipset

    # 把dnsmasq配置文件拷贝到 /etc/dnsmasq.d 目录下
    cp -p /tmp/dm_oversea.conf /tmp/dnsmasq.d
    cp -p /tmp/dm_hongkong.conf /tmp/dnsmasq.d
    cp -p /tmp/dm_mainland.conf /tmp/dnsmasq.d
    rm /tmp/dm_oversea.conf
    rm /tmp/dm_hongkong.conf
    rm /tmp/dm_mainland.conf

    smartvpn_logger "Restarting dnsmasq..."
    /etc/init.d/dnsmasq restart  # 重启nsmasq

    sleep 3

    smartvpn_logger "Restarting mwan3..."
    /etc/init.d/mwan3 restart > /dev/null 2>&1
}

smartvpn_open()
{
    if [ $softether_status == "stop" ];
    then
        smartvpn_logger "softether not start! can not enable smartvpn."
        return 1
    fi

    # ifdown lanman
    # ifdown vpnhub01
    # ifdown vpnhub02

    ifup lanman
    ifup vpnhub01
    ifup vpnhub02

    network_is_up lanman
    if [ $? -ne 0 ]; then
        smartvpn_logger "softether tap interface is missing."
        return 2
    fi

    smartvpn_enable
    
    smartvpn_logger "SmartVPN is on!"
    echo

    return
}

smartvpn_close()
{    
    # smartvpn_logger "Stoping mwan3..."
    # /etc/init.d/mwan3 stop > /dev/null 2>&1

    smartvpn_ipset_delete
    rm /tmp/dnsmasq.d/dm_oversea.conf >/dev/null 2>&1
    rm /tmp/dnsmasq.d/dm_hongkong.conf >/dev/null 2>&1
    rm /tmp/dnsmasq.d/dm_mainland.conf >/dev/null 2>&1

    smartvpn_logger "Restarting dnsmasq..."
    /etc/init.d/dnsmasq restart  # 重启nsmasq

    sleep 3

    smartvpn_logger "Restarting mwan3..."
    /etc/init.d/mwan3 restart > /dev/null 2>&1

    smartvpn_logger "SmartVPN is off!"
    echo

    return
}

smartvpn_status()
{
    local _savefile="/etc/smartvpn/user_ipset.sav"

    if [ $softether_status == "stop" ]; then
        echo "VPN service is missing"
    else
        network_is_up lanman
        if [ $? -ne 0 ]; then
            echo "VPN tunnel is missing ($SMARTVPN_VER)"
        else
            if [ $vpn_status == "on" ]; then
                echo "SmartVPN is ON ($SMARTVPN_VER)"
            else
                echo "SmartVPN is OFF ($SMARTVPN_VER)"
            fi
        fi
    fi

    if [ $vpn_status == "on" ]; then

        mlip=`ipset list ip_mainland | grep "Number of entries" | awk '{print $4}'`
        hkip=`ipset list ip_hongkong | grep "Number of entries" | awk '{print $4}'`
        osip=`ipset list ip_oversea | grep "Number of entries" | awk '{print $4}'`

        saved_mlip=0
        saved_hkip=0
        saved_osip=0

        if [ -f $_savefile ]; then
            saved_mlip=`grep "add ip_mainland" $_savefile | wc -l`
            saved_hkip=`grep "add ip_hongkong" $_savefile | wc -l`
            saved_osip=`grep "add ip_oversea" $_savefile | wc -l`
        fi

        if [[ "$SHORT" == "short" ]]; then
            echo "match $mlip (snapshot: $saved_mlip)"
            echo "match $hkip (snapshot: $saved_hkip)"
            echo "match $osip (snapshot: $saved_osip)"
        else
            echo "Mainland ip match $mlip (snapshot: $saved_mlip)"
            echo "Hongkong ip match $hkip (snapshot: $saved_hkip)"
            echo "Oversea ip  macth $osip (snapshot: $saved_osip)"
        fi

    else
        echo "-"
        echo "-"
        echo "-"
    fi

    cd /usr/share/smartvpn
    . ./conf/network.conf
    echo "${SMARTVPN_USERID:-NoUser} (netid=${SMARTVPN_NETID:-null})"
}

smartvpn_saveipset()
{
    local _savefile="/etc/smartvpn/user_ipset.sav"

    echo "Saving ipset to $_savefile"
    ipset save net_hongkong >  $_savefile
    ipset save ip_hongkong  >> $_savefile
    ipset save net_oversea  >> $_savefile
    ipset save ip_oversea   >> $_savefile
    ipset save ip_mainland  >> $_savefile
    ipset save net_mainland >> $_savefile
}

smartvpn_restoreipset()
{

    local _savefile="/etc/smartvpn/user_ipset.sav"

    echo "Restoring ipset from $_savefile"
    ipset restore -! < $_savefile
}



vpn_status_get()
{
    if [ -f /tmp/dnsmasq.d/dm_oversea.conf ]; then
        vpn_status="on"
    else
        vpn_status="off"
    fi

    return
}

softether_status_get()
{
    __tmpPID=$(ps | grep "vpnserver" | grep -v "grep vpnserver" | awk '{print $1}' 2>/dev/null)

    if [[ -n "$__tmpPID" ]]; then
        softether_status="start"
    else
        softether_status="stop"
    fi
    return
}

smartvpn_usage()
{
    echo "usage: smartvpn.sh status"
    echo "       smartvpn.sh on [hard]      # hard -- start with clean ipset"
    echo "       smartvpn.sh off [soft]     # soft -- keep ipset in memory"
    echo "       smartvpn.sh save|restore"
    echo ""
    echo "softether status = $softether_status"
    echo "smartvpn status = $vpn_status"
    echo ""
    return
}

# main

vpn_status_get
softether_status_get

config_load "smartvpn"
config_get VPN_ENABLE global vpn_enable 0
config_get DNS_MAINLAND global dns_mainland 119.29.29.29

OPT=$1
SOFT=$2
SHORT=$2

case $OPT in
    on)
        if [[ ! -z "$SOFT" && "$SOFT" != "hard" ]]; then
            echo "***Error*** second parameter only support 'hard'"
            exit 1
        fi
    ;;

    on|off)
        if [[ ! -z "$SOFT" && "$SOFT" != "soft" ]]; then
            echo "***Error*** second parameter only support 'soft'"
            exit 1
        fi
    ;;

esac

smartvpn_lock="/var/run/smartvpn.lock"
smartvpn_work="/var/run/smartvpn.work"
trap "lock -u $smartvpn_lock; rm ${smartvpn_work}; exit 2" SIGHUP SIGINT SIGTERM
lock $smartvpn_lock
echo $$ > ${smartvpn_work}

retval=0

case $OPT in
    on)
    	grep 'declare Cascade0' /usr/libexec/softethervpn/vpn_server.config > /dev/null
        if [ $? -ne 0 ]; then
            echo "***Error*** The vpnserver dose not setup with upstream connection"
            retval=3
        else
            smartvpn_open
            retval=$?
        fi
    ;;

    off)
        smartvpn_close
        retval=$?
    ;;

    status)
        smartvpn_status
        retval=$?
    ;;

    save)
        if [ $vpn_status == "on" ]; then
            smartvpn_saveipset
            retval=$?
        else
            echo "***Error*** SmartVPN service is not enabled"
            retval=2
        fi
    ;;

    restore)
        if [ $vpn_status == "on" ]; then
            smartvpn_restoreipset
            retval=$?
        else
            echo "***Error*** SmartVPN service is not enabled"
            retval=2
        fi
    ;;

    status)
        smartvpn_status
        retval=$?
    ;;

    *)
        smartvpn_usage
        retval=$?
    ;;
esac

rm ${smartvpn_work}
lock -u $smartvpn_lock

exit $retval
