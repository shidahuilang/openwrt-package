#!/bin/bash

CONF_FILE=$(uci -q get coredns.config.configfile)
LOG_FILE=$(uci -q get coredns.global.logfile)

cat /dev/null > $LOG_FILE