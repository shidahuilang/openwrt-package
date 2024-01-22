#!/bin/sh

appdir="${PWD}"
workdir="${PWD}/tmp"
rm -rf $workdir
txt=$(cat applications/luci-app-cloudflarespeedtest/Makefile|tr '\n' ',')
version=`echo $txt|sed -r 's/.*PKG_VERSION:=(.*),PKG_RELEASE.*/\1/'`

mkdir -p $workdir/luci-app-cloudflarespeedtest/usr/lib/lua/luci
[ -d applications/luci-app-cloudflarespeedtest/luasrc ] && cp -R applications/luci-app-cloudflarespeedtest/luasrc/* $workdir/luci-app-cloudflarespeedtest/usr/lib/lua/luci/
[ -d applications/luci-app-cloudflarespeedtest/root ] && cp -R applications/luci-app-cloudflarespeedtest/root/* $workdir/luci-app-cloudflarespeedtest/
chmod +x $workdir/luci-app-cloudflarespeedtest/etc/init.d/* >/dev/null 2>&1
[ -d applications/luci-app-cloudflarespeedtest/po ] && sudo -E apt-get -y install gcc make && \
mkdir -p $workdir/po2lmo && mkdir -p $workdir/luci-app-cloudflarespeedtest/usr/lib/lua/luci/i18n/ && \
wget -O $workdir/po2lmo/po2lmo.c https://raw.githubusercontent.com/openwrt/luci/openwrt-18.06/modules/luci-base/src/po2lmo.c && \
wget -O $workdir/po2lmo/Makefile https://raw.githubusercontent.com/openwrt/luci/openwrt-18.06/modules/luci-base/src/Makefile && \
wget -O $workdir/po2lmo/template_lmo.h https://raw.githubusercontent.com/openwrt/luci/openwrt-18.06/modules/luci-base/src/template_lmo.h && \
wget -O $workdir/po2lmo/template_lmo.c https://raw.githubusercontent.com/openwrt/luci/openwrt-18.06/modules/luci-base/src/template_lmo.c && \
cd $workdir/po2lmo && make po2lmo && ./po2lmo $appdir/applications/luci-app-cloudflarespeedtest/po/zh_Hans/cloudflarespeedtest.po $workdir/luci-app-cloudflarespeedtest/usr/lib/lua/luci/i18n/cloudflarespeedtest.zh-cn.lmo
mkdir -p $workdir/luci-app-cloudflarespeedtest/CONTROL
cat > $workdir/luci-app-cloudflarespeedtest/CONTROL/control <<EOF
Package: luci-app-cloudflarespeedtest
Version: ${version}
Depends: libc cdnspeedtest
Architecture: all
Maintainer: mingxiaoyu <fengying0347@163.com>
Section: luci
Priority: optional
Description: LuCI support for Cloudflares Speed Test
Source: http://github.com/mingxiaoyu/luci-app-cloudflarespeedtest
EOF
cat > $workdir/luci-app-cloudflarespeedtest/CONTROL/postinst <<EOF
#!/bin/sh
[ "${IPKG_NO_SCRIPT}" = "1" ] && exit 0
[ -s ${IPKG_INSTROOT}/lib/functions.sh ] || exit 0
. ${IPKG_INSTROOT}/lib/functions.sh
default_postinst \$0 \$@
EOF
 
chmod +x $workdir/luci-app-cloudflarespeedtest/usr/bin/cloudflarespeedtest/*.sh
chmod +x $workdir/luci-app-cloudflarespeedtest/CONTROL/postinst
wget -O $workdir/ipkg-build https://raw.githubusercontent.com/openwrt/openwrt/openwrt-18.06/scripts/ipkg-build && \
chmod +x $workdir/ipkg-build && \
$workdir/ipkg-build -o root -g root $workdir/luci-app-cloudflarespeedtest $workdir
