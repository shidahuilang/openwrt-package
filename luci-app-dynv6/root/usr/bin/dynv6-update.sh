#!/bin/sh -e

. /lib/functions.sh


logmsg(){
  logger -t "dynv6" $@
}

if [ -e /usr/bin/curl ]; then
  bin="curl -fsS"
  elif [ -e /usr/bin/wget ]; then
  bin="wget -O-"
else
  logmsg "neither curl nor wget found"
  exit 1
fi

update_address(){
  local hostname=$1
  local device=$2
  local token=$3
  local site=$4
  local file=$HOME/.dynv6.$site
  [ -e $file ] && old=`cat $file`

  if [ -z "$hostname" -o -z "$token" ]; then
    return 0
  fi

  if [ -z "$netmask" ]; then
    netmask=128
  fi

  if [ "$device" = "any" ]; then
    device=""
  fi

  if [ -n "$device" ]; then
    device="dev $device"
  fi
  address=$(ip -6 addr list scope global $device 2>/dev/null | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1)


  if [ -z "$address" ]; then
    return 0
  fi

  # address with netmask
  current=$address/$netmask

  if [ "$old" = "$current" ]; then
    #logmsg "$site IPv6 address unchanged"
    return 0
  fi

  # send addresses to dynv6
  ret6=`$bin "http://dynv6.com/api/update?hostname=$hostname&ipv6=$current&token=$token" 2>/dev/null`
  ret4=`$bin "http://ipv4.dynv6.com/api/update?hostname=$hostname&ipv4=auto&token=$token" 2>/dev/null`

  # save current address
  if [ "$ret6" = "addresses updated" ];then
    echo $current > $file
    logmsg "$site update the new ipv6 address $current to dynv6 zone $hostname, ret=$ret6, success!"
  else
    logmsg "$site update the new ipv6 address $current to dynv6 zone $hostname, ret=$ret6, failed!"
  fi

}

dynv6_update_loop()
{
  local interval=$1
  shift
  while true;do
    update_address $@
    sleep "$interval"
  done
}

wait_for_ipv6()                                                 
{                                                               
        ifstatus $1                                             
        time=0                                                  
        while [ -z "$(ifstatus $1 | grep l3_device)"  ]                                     
        do                                                                                  
                echo "wait ${time}s"                                                        
                sleep 10s                                                                   
                time=$((time+10))                                                           
        done                                                                                
}

site_foreach()
{
    load_site_cb(){
        local site=$1
        local token zone device enabled interval token interface
        config_get enabled "$site" "enabled" "1"
        [ $enabled != '1' ] && return 0
        config_get zone "$site" "zone"
        config_get token "$site" "token"
        config_get interface "$site" "interface" "any"
        config_get interval "$site" "interval" "60"
        ##### wait ipv6 #######################
        echo "start to wait for getting ipv6" #
        wait_for_ipv6 $interface              #
        echo "got ipv6"                       #
        ##### wait ipv6 #######################
        device="$(ifstatus $interface 2>/dev/null| jsonfilter -e '@.l3_device' 2>/dev/null)"
        [ -z $device ] && device="any"
        [ -n "$zone" ] && [ -n "$device" ] && [ -n "$token" ] && {
          dynv6_update_loop $interval $zone $device $token $site &
        }
    }
    config_foreach load_site_cb site
}

config_load dynv6
site_foreach
