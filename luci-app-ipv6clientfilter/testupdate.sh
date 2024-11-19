#!/bin/bash

sdir=$(cd "$(dirname "${BASH_SOURCE[0]}")"; pwd)
cd "$sdir"

echo 更新web
cp -vrf htdocs/luci-static/ /www/
echo 更新acl和menu
cp -vrf root/usr/ /
echo 更新启动脚本
cp -vrf root/etc/init.d/ /etc/

echo 重启rpcd 
service rpcd restart

echo done
