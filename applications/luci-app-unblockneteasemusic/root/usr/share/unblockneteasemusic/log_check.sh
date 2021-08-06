#!/bin/sh
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2019-2021 Tianling Shen <cnsztl@immortalwrt.org>

NAME="unblockneteasemusic"

log_max_size="4" #使用KB计算
log_file="/tmp/$NAME.log"

log_size="$(expr $(ls -l "${log_file}" | awk -F ' ' '{print $5}') / "1024")"
[ "${log_size}" -lt "${log_max_size}" ] || echo "" > "${log_file}"

[ "*$(uci get $NAME.@$NAME[0].daemon_enable 2>/dev/null)*" != "*1*" ] || { [ -n "$(ps |grep "$NAME" |grep "app.js" |grep -v "grep")" ] || /etc/init.d/$NAME restart; }
