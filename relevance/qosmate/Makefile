include $(TOPDIR)/rules.mk

PKG_NAME:=qosmate
PKG_VERSION:=0.5.34
PKG_RELEASE:=7

PKG_MAINTAINER:=Markus Hütter <mh@hudra.net>
PKG_LICENSE:=GPL-3.0-or-later

include $(INCLUDE_DIR)/package.mk

define Package/qosmate
  SECTION:=net
  CATEGORY:=Base system
  TITLE:=QoSmate - Quality of Service management tool
  DEPENDS:=+kmod-sched +ip-full +kmod-veth +tc-full +kmod-netem +kmod-sched-ctinfo +kmod-ifb +kmod-sched-cake
endef

define Package/qosmate/description
  QoSmate is a Quality of Service management tool for OpenWrt
endef

define Build/Prepare
endef

define Build/Compile
endef

define Package/qosmate/conffiles
/etc/config/qosmate
endef

define Package/qosmate/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(INSTALL_DIR) $(1)/etc/config

	$(INSTALL_BIN) ./etc/qosmate.sh $(1)/etc/
	$(INSTALL_BIN) ./etc/init.d/qosmate $(1)/etc/init.d/
	$(INSTALL_CONF) ./etc/hotplug.d/iface/13-qosmateHotplug $(1)/etc/hotplug.d/iface/
	$(INSTALL_CONF) ./etc/config/qosmate $(1)/etc/config/
endef

$(eval $(call BuildPackage,qosmate))
