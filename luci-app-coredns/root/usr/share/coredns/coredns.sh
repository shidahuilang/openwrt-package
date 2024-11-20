#!/bin/sh

script_action=${1}

restart_service() {
    /etc/init.d/coredns restart
}

case $script_action in
    "restart_service")
        restart_service
    ;;
    "checkfile")
        [ -f ${2} ] && echo true || echo false
    ;;
    *)
        exit 0
    ;;
esac
