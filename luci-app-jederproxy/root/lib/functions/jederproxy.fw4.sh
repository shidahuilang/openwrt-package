FIREWALL_INCLUDE="/usr/share/jederproxy/firewall_include.ut"

log() {
    logger -st jederproxy[$$] -p4 "$@"
}

setup_firewall() {
    ip route add local default dev lo table 100
    ip rule  add fwmark 0x2333        table 100

    log "Generating firewall4 rules..."
    /usr/bin/utpl ${FIREWALL_INCLUDE} > /var/etc/jederproxy/firewall_include.nft

    log "Triggering firewall4 reload..."
    /etc/init.d/firewall reload 2>/dev/null
}

flush_firewall() {
    ip rule  del   table 100
    ip route flush table 100

    log "Flushing firewall4 rules..."
    rm /var/etc/jederproxy/firewall_include.nft 2>/dev/null || log ".. but fw4 rule file not exists"

    log "Triggering firewall4 reload..."
    /etc/init.d/firewall reload 2>/dev/null
}
