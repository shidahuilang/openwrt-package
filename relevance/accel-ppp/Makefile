#B
#
# Copyright (C) 2013-2015 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=accel-ppp
PKG_RELEASE:=8
PKG_VERSION:=1.13.0

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL=https://github.com/accel-ppp/accel-ppp.git
PKG_SOURCE_VERSION:=dbffa39b4304f1be5e099f056a9e5001c3100393

PKG_MAINTAINER:=Konstantine Shevlakov <shevlakov@132lan.ru>
PKG_LICENSE:=GPL-2.0

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

#PKG_INSTALL:=1
#PKG_CONFIG_DEPENDS:=CONFIG_PACKAGE_accel-ppp_$(BUILD_VARIANT)_ext_cer_id

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk
include $(INCLUDE_DIR)/kernel.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  TITLE:=accel-ppp VPN server
  DEPENDS:=+libpcre +libopenssl +libpthread +librt +libatomic +libucontext
endef

CMAKE_OPTIONS += \
	-DKDIR=$(LINUX_DIR) \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_BUILD_TYPE=Release \
	-DLOG_PGSQL=FALSE \
	-DSHAPER=TRUE \
	-DRADIUS=FALSE \
	-DNETSNMP=FALSE \
	-DLOG_FILE=TRUE \
	-DLIB_SUFFIX= \

ifeq ($(ARCH),$(filter $(ARCH), x86_64 i386))
  CMAKE_OPTIONS += \
	-DBUILD_IPOE_DRIVER=TRUE \
	-DBUILD_VLAN_MON_DRIVER=TRUE
endif


CMAKE_BINARY_DIR := $(PKG_BUILD_DIR)/build
TARGET_CFLAGS += -I$(STAGING_DIR)/opt/include -D_GNU_SOURCE -g -O2 -Wno-incompatible-pointer-types
TARGET_LDFLAGS += -lpthread -latomic -lucontext

define KernelPackage/$(PKG_NAME)-ipoe
  SUBMENU:= Accel-PPP kernel modules
  TITLE:=Accel-PPP IPoE kernel module
  DEPENDS:=+accel-ppp
  FILES:=$(CMAKE_BINARY_DIR)/drivers/ipoe/driver/ipoe.ko
  AUTOLOAD:=$(call AutoProbe,ipoe)
endef

define KernelPackage/$(PKG_NAME)-vlan-mon
  SUBMENU:=Accel-PPP kernel modules
  TITLE:=Accel-PPP vlan-mon kernel module
  DEPENDS:=+accel-ppp
  FILES:=$(CMAKE_BINARY_DIR)/drivers/vlan_mon/driver/vlan_mon.ko
  AUTOLOAD:=$(call AutoProbe,vlan_mon)
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) \
		$(1)/usr/sbin \
		$(1)/usr/bin \
		$(1)/usr/lib \
		$(1)/usr/lib/accel-ppp \
		$(1)/usr/share/accel-ppp \
		$(1)/usr/share/accel-ppp/radius \
		$(1)/usr/share/accel-ppp/l2tp \
		$(1)/etc/init.d \
		$(1)/etc/accel-ppp

	$(INSTALL_BIN) \
		$(PKG_INSTALL_DIR)/usr/sbin/accel-pppd \
		$(1)/usr/sbin/

	$(INSTALL_BIN) \
		$(PKG_INSTALL_DIR)/usr/bin/accel-cmd \
		$(1)/usr/bin/

	$(INSTALL_BIN) \
		$(PKG_INSTALL_DIR)/usr/lib/accel-ppp/*.so \
		$(1)/usr/lib/accel-ppp/

	$(INSTALL_DATA) \
		$(PKG_INSTALL_DIR)/usr/share/accel-ppp/l2tp/dictionary.* \
		$(1)/usr/share/accel-ppp/l2tp/

	$(INSTALL_BIN) \
		files/accel-ppp.init \
		$(1)/etc/init.d/accel-ppp

	$(INSTALL_DATA) \
		files/accel-ppp.conf \
		$(1)/etc/accel-ppp

endef

define Package/$(PKG_NAME)/postinst
for l in $$(ls -1 /usr/lib/accel-ppp/); do
	ln -s /usr/lib/accel-ppp/$$l /usr/lib/
done
endef

define Package/$(PKG_NAME)/prerm
for l in $$(ls -1 /usr/lib/accel-ppp/); do
	rm -f /usr/lib/$$l
done
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
ifeq ($(ARCH),$(filter $(ARCH), x86_64 i386))
  $(eval $(call KernelPackage,$(PKG_NAME)-ipoe))
  $(eval $(call KernelPackage,$(PKG_NAME)-vlan-mon))
endif
