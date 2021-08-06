include $(TOPDIR)/rules.mk

PKG_NAME:=k3screenctrl
PKG_VERSION:=0.10
PKG_RELEASE:=2

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/lwz322/k3screenctrl.git
PKG_SOURCE_VERSION:=7b81497bb3719d7f3a741307417e39a4505d309d
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_SOURCE_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.xz
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_SOURCE_SUBDIR)
PKG_MAINTAINER:=Hamster Tian <haotia@gmail.com>

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS+= -D_GNU_SOURCE

define Package/k3screenctrl
  SECTION:=utils
  CATEGORY:=Utilities
  DEPENDS:=@(TARGET_bcm53xx_generic_DEVICE_phicomm_k3||TARGET_bcm53xx_generic_DEVICE_phicomm-k3||TARGET_bcm53xx_DEVICE_phicomm-k3) +@KERNEL_DEVMEM +coreutils +coreutils-od +bash +curl
  TITLE:=LCD screen controller on PHICOMM K3
  URL:=https://github.com/lwz322/k3screenctrl.git
endef

define Package/k3screenctrl/description
 K3 Screen Controller (k3screenctrl) is a program utilizing
the LCD screen on PHICOMM K3 to display some stats.
endef

define Package/k3screenctrl/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/lib/k3screenctrl
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/lib/k3screenctrl/oui
	$(INSTALL_DIR) $(1)/etc/config

	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/k3screenctrl $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/k3screenctrl/wan.sh $(1)/lib/k3screenctrl/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/k3screenctrl/wifi.sh $(1)/lib/k3screenctrl/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/k3screenctrl/port.sh $(1)/lib/k3screenctrl/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/k3screenctrl/basic.sh $(1)/lib/k3screenctrl/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/k3screenctrl/host.sh $(1)/lib/k3screenctrl/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/k3screenctrl/weather.sh $(1)/lib/k3screenctrl/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/k3screenctrl/oui/oui.txt $(1)/lib/k3screenctrl/oui/

	$(INSTALL_BIN) ./files/k3screenctrl.init $(1)/etc/init.d/k3screenctrl
	$(INSTALL_BIN) ./files/k3screenctrl $(1)/etc/config/
endef

$(eval $(call BuildPackage,k3screenctrl))
