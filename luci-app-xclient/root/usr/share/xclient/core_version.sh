#!/bin/sh
cur_core_version=$(/usr/bin/xray -version | awk '{print $2}' | sed -n 1P 2>&1 & >/dev/null)
if [ "$?" -eq "0" ]; then
rm -rf /usr/share/xclient/core_version
if [ $cur_core_version ]; then
echo $cur_core_version > /usr/share/xclient/core_version 2>&1 & >/dev/null
elif [ $cur_core_version == "" ]; then
echo "--" > /usr/share/xclient/core_version 2>&1 & >/dev/null
fi
fi



new_core_version=`curl -sL "https://github.com/XTLS/Xray-core/tags"| grep "/XTLS/Xray-core/releases/"| head -n 1| awk -F "/tag/" '{print $2}'| sed 's/\">//'`
if [ "$?" -eq "0" ]; then
rm -rf /usr/share/xclient/new_core
if [ $new_core_version ]; then
echo $new_core_version > /usr/share/xclient/new_core 2>&1 & >/dev/null
elif [ $new_core_version == "" ]; then
echo 0 > /usr/share/xclient/new_core 2>&1 & >/dev/null
fi
fi
