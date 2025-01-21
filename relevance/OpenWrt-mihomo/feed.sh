#!/bin/sh

# MihomoTProxy's feed

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
	# add key
	echo "add key"
	key_build_pub_file="key-build.pub"
	curl -s -L -o "$key_build_pub_file" "$repository_url/key-build.pub"
	opkg-key add "$key_build_pub_file"
	rm -f "$key_build_pub_file"
	# add feed
	echo "add feed"
	if (grep -q mihomo /etc/opkg/customfeeds.conf); then
		sed -i '/mihomo/d' /etc/opkg/customfeeds.conf
	fi
	echo "src/gz mihomo $feed_url" >> /etc/opkg/customfeeds.conf
	# update feeds
	echo "update feeds"
	opkg update
elif [ -x "/usr/bin/apk" ]; then
	# todo: wait for upstream support to build apk with signature
	# add key
	# echo "add key"
	# curl -s -L -o "/etc/apk/keys/mihomo.pem" "$repository_url/public-key.pem"
	# add feed
	echo "add feed"
	if (grep -q mihomo /etc/apk/repositories.d/customfeeds.list); then
		sed -i '/mihomo/d' /etc/apk/repositories.d/customfeeds.list
	fi
	echo "$feed_url/packages.adb" >> /etc/apk/repositories.d/customfeeds.list
	# update feeds
	echo "update feeds"
	apk update --allow-untrusted
fi

echo "success"
