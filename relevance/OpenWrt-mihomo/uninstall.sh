#!/bin/sh

if [ -x "/bin/opkg" ]; then
	opkg remove luci-i18n-mihomo-zh-cn
	opkg remove luci-app-mihomo
	opkg remove mihomo
elif [ -x "/usr/bin/apk" ]; then
	apk del luci-i18n-mihomo-zh-cn
	apk del luci-app-mihomo
	apk del mihomo
fi

rm -rf /etc/mihomo
rm -f /etc/config/mihomo
