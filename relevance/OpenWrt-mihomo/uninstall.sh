#!/bin/sh

# uninstall
if [ -x "/bin/opkg" ]; then
	opkg remove luci-i18n-nikki-zh-cn
	opkg remove luci-app-nikki
	opkg remove nikki
elif [ -x "/usr/bin/apk" ]; then
	apk del luci-i18n-nikki-zh-cn
	apk del luci-app-nikki
	apk del nikki
fi
# remove config
rm -f /etc/config/nikki
# remove files
rm -rf /etc/nikki
