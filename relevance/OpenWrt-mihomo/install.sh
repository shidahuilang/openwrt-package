#!/bin/sh

# MihomoTProxy's installer

# check env
if [[ ! -x "/bin/opkg" && ! -x "/usr/bin/apk" || ! -x "/sbin/fw4" ]]; then
	echo "only supports OpenWrt build with firewall4!"
	exit 1
fi

# include openwrt_release
. /etc/openwrt_release

# get branch/arch
arch="$DISTRIB_ARCH"
branch=
case "$DISTRIB_RELEASE" in
	*"23.05"*)
		branch="openwrt-23.05"
		;;
	*"24.10"*)
		branch="openwrt-24.10"
		;;
	"SNAPSHOT")
		branch="SNAPSHOT"
		;;
	*)
		echo "unsupported release: $DISTRIB_RELEASE"
		exit 1
		;;
esac

# feed url
repository_url="https://mihomotproxy.pages.dev"
feed_url="$repository_url/$branch/$arch/mihomo"

if [ -x "/bin/opkg" ]; then
	# download ipks
	eval $(curl -s -L $feed_url/index.json | jsonfilter -e 'version=@["packages"]["mihomo"]' -e 'app_version=@["packages"]["luci-app-mihomo"]' -e 'i18n_version=@["packages"]["luci-i18n-mihomo-zh-cn"]')
	curl -s -L -J -O $feed_url/mihomo_${version}_${arch}.ipk
	curl -s -L -J -O $feed_url/luci-app-mihomo_${app_version}_all.ipk
	curl -s -L -J -O $feed_url/luci-i18n-mihomo-zh-cn_${i18n_version}_all.ipk
	# update feeds
	echo "update feeds"
	opkg update
	# install ipks
	echo "install ipks"
	opkg install mihomo_*.ipk luci-app-mihomo_*.ipk luci-i18n-mihomo-zh-cn_*.ipk
	rm -f -- *mihomo*.ipk
elif [ -x "/usr/bin/apk" ]; then
	# install apks from remote repository
	echo "install apks from remote repository"
	apk add --allow-untrusted --repository $feed_url/packages.adb mihomo luci-app-mihomo luci-i18n-mihomo-zh-cn
fi

echo "success"
