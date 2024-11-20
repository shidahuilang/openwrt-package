#!/bin/sh

# This is open source software, licensed under the MIT License.
#
# Copyright (C) 2024 BobbyUnknown
#
# Description:
# This software provides a tunneling application for OpenWrt using Mihomo core.
# The application allows users to configure and manage proxy rules, connections,
# and network traffic routing through a user-friendly web interface, enabling
# advanced networking capabilities and traffic control on OpenWrt routers.


CONF_DIR=/etc/insomclash
PROFILE_DIR="$CONF_DIR/profile"
RUN_DIR="$CONF_DIR/run"
RUN_CONF="$RUN_DIR/config.yaml"
PROG=/etc/insomclash/core/mihomo
LOG_DIR="/var/log/insomclash"
APP_LOG_PATH="$LOG_DIR/app.log"
CORE_LOG_PATH="$LOG_DIR/core.log"
RULES_SCRIPT="/usr/share/insomclash/insomclash-rules"

PID_FILE="/var/run/insomclash.pid"

ulimit -SHn 1048576

cleanup() {
    log "Caught signal, cleaning up..."
    stop_insomclash
    rm -f "$PID_FILE"
    exit 1
}

trap cleanup INT TERM

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') $1" >> "$APP_LOG_PATH"
    echo "$1"
}

prepare_config() {
    mkdir -p "$RUN_DIR"
    mkdir -p "$LOG_DIR"
    if [ -f "$PROFILE_DIR/config.yaml" ]; then
        cp "$PROFILE_DIR/config.yaml" "$RUN_CONF"
    else
        log "Error: Configuration file not found in profile directory"
        return 1
    fi
}

check_running() {
    if [ -f "$PID_FILE" ]; then
        if kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            return 0
        else
            rm -f "$PID_FILE"
        fi
    fi
    return 1
}

start_insomclash() {
    if check_running; then
        log "InsomClash is already running"
        return 1
    fi
    
    if pgrep -f mihomo > /dev/null; then
        killall mihomo
        log "Stopping existing InsomClash instance"
        sleep 1
    fi
    
    if [ -x "$RULES_SCRIPT" ]; then
        "$RULES_SCRIPT" stop > /dev/null 2>&1
    fi
    
    prepare_config || return 1
    
    nohup $PROG -d "$RUN_DIR" >> "$CORE_LOG_PATH" 2>&1 &
    MIHOMO_PID=$!
    
    echo $MIHOMO_PID > "$PID_FILE"
    
    sleep 2
    if kill -0 $MIHOMO_PID 2>/dev/null; then
        log "InsomClash started successfully with PID $MIHOMO_PID"
        
        uci -q batch <<-EOF
            del dhcp.@dnsmasq[0].server
            del dhcp.@dnsmasq[0].cachesize
            del dhcp.@dnsmasq[0].noresolv
            del dhcp.@dnsmasq[0].localuse
            del dhcp.@dnsmasq[0].rebind_protection
            add_list dhcp.@dnsmasq[0].server='127.0.0.1#7874'
            set dhcp.@dnsmasq[0].cachesize='0'
            set dhcp.@dnsmasq[0].noresolv='1'
            set dhcp.@dnsmasq[0].localuse='1'
            set dhcp.@dnsmasq[0].rebind_protection='0'
            commit dhcp
EOF
        
        if /etc/init.d/dnsmasq restart > /dev/null 2>&1; then
            log "DNS settings applied and dnsmasq restarted."
        else
            log "Warning: Failed to restart dnsmasq"
        fi
        
        if [ -x "$RULES_SCRIPT" ]; then
            "$RULES_SCRIPT" start
            log "Firewall rules applied."
        else
            log "Warning: Firewall rules script not found or not executable."
        fi
        
        (
            while kill -0 $MIHOMO_PID 2>/dev/null; do
                sleep 5
            done
            log "Mihomo process died unexpectedly"
            stop_insomclash
            rm -f "$PID_FILE"
        ) &
    else
        log "Error: InsomClash failed to start. Check $CORE_LOG_PATH for details."
        rm -f "$PID_FILE"
        return 1
    fi
}

stop_insomclash() {
    if [ -f "$PID_FILE" ]; then
        MIHOMO_PID=$(cat "$PID_FILE")
        if kill -0 $MIHOMO_PID 2>/dev/null; then
            kill $MIHOMO_PID
            log "InsomClash stopped (PID: $MIHOMO_PID)."
        fi
        rm -f "$PID_FILE"
    elif pgrep -f mihomo > /dev/null; then
        killall mihomo
        log "InsomClash stopped (killall)."
    fi
    
    sleep 1
    
    if [ -x "$RULES_SCRIPT" ]; then
        "$RULES_SCRIPT" stop > /dev/null 2>&1
        log "Firewall rules removed."
    fi
    
    uci -q batch <<-EOF
        del dhcp.@dnsmasq[0].server
        del dhcp.@dnsmasq[0].cachesize
        del dhcp.@dnsmasq[0].noresolv
        del dhcp.@dnsmasq[0].localuse
        del dhcp.@dnsmasq[0].rebind_protection
        add_list dhcp.@dnsmasq[0].server='1.1.1.1'
        add_list dhcp.@dnsmasq[0].server='8.8.8.8'
        commit dhcp
EOF
    
    if /etc/init.d/dnsmasq restart > /dev/null 2>&1; then
        log "DNS settings restored and dnsmasq restarted."
    else
        log "Warning: Failed to restart dnsmasq"
    fi
}

case "$1" in
    start)
        start_insomclash
        ;;
    stop)
        stop_insomclash
        ;;
    restart)
        stop_insomclash
        sleep 2
        start_insomclash
        ;;
    status)
        if check_running; then
            log "InsomClash is running (PID: $(cat $PID_FILE))"
            exit 0
        else
            log "InsomClash is not running"
            exit 1
        fi
        ;;
    *)
        log "Usage: $0 {start|stop|restart|status}"
        exit 1
esac

exit 0