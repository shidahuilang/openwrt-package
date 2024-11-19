#!/bin/sh

######################################################
# smartvpn dnsmasq domain configuration file generator
# create by Daniel Yang 2021-07-22
######################################################

domain_file_formated="/tmp/smartvpn_domain_format.tmp"
domain_file_sorted="/tmp/smartvpn_domain_sort.tmp"
#domain_file_smartvpn="/etc/smartvpn/smartdns.conf"

#ipset_name="smartvpn"

rule_file=$1
domain_file=$2
ip_file=$3
ipset_name=$4
dnsserver=$5
append=$6

usage()
{
    echo "gensmartdns.sh rule_file domain_file ip_file ipset_name [dnsserver] [append]"
    echo "-- rule_file : must specify"
    echo "-- domain_file : must specify, writable, domain list output"
    echo "-- ip_file : must specify, writable, ip list output"
    echo "-- ipset_name : must specify"
    echo "-- dnsserver : optional, default is 8.8.8.8"
    echo ""
}


# echo "gen arg list: "$*" "

[ -z $rule_file ] && {
    usage
    return 1
}

[ -z $ip_file ] && {
    usage
    return 1
}

[ -z $dnsserver ] && {
    dnsserver="8.8.8.8"
}

[ -z $ipset_name ] && {
    ipset_name="smartvpn"
}

echo "gensmartdns: domain_file=$rule_file, ip_file=$ip_file, dnsserver=$dnsserver"

format2domain()
{
    local _rule=$1
    local _dmf=$2
    local _ipf=$3

    [ -z $append ] && {
        echo "" > $_dmf
        echo "" > $_ipf
    }

    cat $_rule | while read line || [ -n "$line" ]
    do
        if [ -n "$line" ]; then
            if [[ "${line:0:1}" = "." ]]; then
                echo "${line:1}" >> $_dmf
            elif [[ "${line:0:1}" = "#" ]]; then
                line=""
            else
                echo "$line" >> $_ipf
            fi
        fi
    done
}

format2domain $rule_file $domain_file_formated $ip_file
[ $? -ne 0 ] && {
    echo "format2domain error!"
    return 1
}

sort $domain_file_formated | uniq > $domain_file_sorted
cat $domain_file_sorted | while read line
do
    if [ -n "$line" ]; then
        echo "server=/$line/$dnsserver"
        echo "ipset=/$line/$ipset_name"
    fi
done > $domain_file

# rm $domain_file_formated
# rm $domain_file_sorted
echo "Gen smartdns conf done!"

