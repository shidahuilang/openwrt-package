#!/bin/sh
# Copyright 2024 Rafał Wabik (IceG) - From eko.one.pl forum
# Licensed to the GNU General Public License v3.0.

chmod +x /etc/uci-defaults/setup_easyconfig_transfer.sh 2>&1 &
chmod +x /sbin/transfer2cron.sh 2>&1 &
chmod +x /sbin/backup2cron.sh 2>&1 &
chmod +x /usr/sbin/easyconfig_statistics.sh 2>&1 &
chmod +x /usr/sbin/easyconfig_statistics.uc 2>&1 &

echo "{}" > /tmp/easyconfig_statistics.json

rm -rf /tmp/luci-indexcache  2>&1 &
rm -rf /tmp/luci-modulecache/  2>&1 &
exit 0
