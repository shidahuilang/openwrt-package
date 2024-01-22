#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

zhcn_dir="$(find -maxdepth 4 -name 'zh-cn')"
zhtw_dir="$(find -maxdepth 4 -name 'zh-tw')"

# i18n name was changed in master
for cn_dir in ${zhcn_dir}; do mv "${cn_dir}" "${cn_dir/zh-cn/zh_Hans}"; done
for tw_dir in ${zhtw_dir}; do mv "${tw_dir}" "${tw_dir/zh-tw/zh_Hant}"; done

# backport translation
./build/i18n-merge-master.pl

# recovery changes
for cn_dir in ${zhcn_dir}; do mv "${cn_dir/zh-cn/zh_Hans}" "${cn_dir}"; done
for tw_dir in ${zhtw_dir}; do mv "${tw_dir/zh-tw/zh_Hant}" "${tw_dir}"; done
