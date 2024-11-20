#!/bin/sh

. $IPKG_INSTROOT/lib/functions.sh

get_coredns() {
    config_get enabled $1 enabled 0
    config_get listen_port $1 listen_port 5336
    config_get redirect $1 redirect 0
    config_get dns $1 dns "119.29.29.29 223.5.5.5"
    config_get bootstrap_dns $1 bootstrap_dns ""
    config_get policy $1 policy "random"
    config_get enabled_cache $1 enabled_cache 0
    config_get configfile $1 configfile "/usr/share/coredns/Corefile"
    config_get path_reload $1 path_reload "2s"
	config_get expire $1 expire "15s"
	config_get max_fails $1 max_fails "3"
	config_get health_check $1 health_check "2s"
    config_get disable_ipv6 $1 disable_ipv6 "0"
}

get_coredns_redir() {
    config_get name $1 name ""
    config_get file $1 file ""
    config_get enabled $1 enabled 0
    config_get dns $1 dns "119.29.29.29 223.5.5.5"
    config_get bootstrap_dns $1 bootstrap_dns ""
    config_get policy $1 policy "random"
    config_get path_reload $1 path_reload "2s"
	config_get expire $1 expire "15s"
	config_get max_fails $1 max_fails "3"
	config_get health_check $1 health_check "2s"

    if [ $enabled -ne 0 ]
    then
        echo "dnsredir /usr/share/coredns/${file} {"
        echo "        path_reload $path_reload"

        echo "        max_fails $max_fails"
        echo "        health_check $health_check"
        echo "        policy $policy"
        echo "        spray"
        echo ""
        echo "        to $dns"
        echo "        expire $expire"
        [[ "$bootstrap_dns" != "" ]] && echo "        bootstrap $bootstrap_dns"
        echo "        no_ipv6"
        echo "    }"
        echo ""
    fi
}

echo "开始生成 coredns 配置文件" >> /tmp/coredns.log

config_load "coredns"
config_foreach get_coredns "coredns"

# CONF_FILE="/etc/coredns/Corefile"
# CONF_FOLDER="/etc/coredns"
# CONF_FILE="/usr/share/coredns/Corefile"
# CONF_FOLDER="/usr/share/coredns"
# CONF_FILE = "$configfile"
CONF_FILE=$(uci -q get coredns.config.configfile)

echo $CONF_FILE >> /tmp/coredns.log

rm -rf $CONF_FILE
# mkdir -p $CONF_FOLDER

touch $CONF_FILE

cat <<EOF >>$CONF_FILE
(ads) {
    ads {
        default-lists
        blacklist https://raw.githubusercontent.com/privacy-protection-tools/anti-AD/master/anti-ad-domains.txt
        whitelist https://files.krnl.eu/whitelist.txt
        log
        auto-update-interval 24h
        list-store ads-cache
    }
}

(dnsredir_default) {
    dnsredir . {
        path_reload $path_reload

        max_fails $max_fails
        health_check $health_check
        policy $policy
        spray

        to ${dns}
        `[[ "$bootstrap_dns" != "" ]] && echo "bootstrap $bootstrap_dns"`
        expire $expire
        no_ipv6
    }
}

(global_cache) {
    # https://coredns.io/plugins/cache/
    cache {
        # [5, 60]
        success 65536 3600 300
        # [1, 10]
        denial 8192 600 60
        prefetch 1 60m 10%
    }
}

.:${listen_port}  {

    hosts /usr/share/coredns/hosts {
        fallthrough
    }
    health
    #prometheus :9153
    errors
    log
    loop
    reload 60s

    `[[  $disable_ipv6 -ne 0 ]] && echo "template IN AAAA ."`

    `[ $enabled_cache -ne 0 ] && echo "import global_cache"`
    #import ads

    `config_foreach get_coredns_redir "coredns_rule_file"`

    `config_foreach get_coredns_redir "coredns_rule_url"`

    import dnsredir_default
}
EOF

echo "配置文件已生成" >> /tmp/coredns.log