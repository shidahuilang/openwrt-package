#
# Copyright (C) 2015-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v3.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=k3wifi
PKG_VERSION:=1
PKG_RELEASE:=3

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	TITLE:=k3wifi
	DEPENDS:=
	URL:=https://github.com/xiangfeidexiaohuo/Phicomm-K3_Wireless-Firmware
endef

define Package/$(PKG_NAME)/description
  k3wifi fw
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef


define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/lib
	$(INSTALL_DIR) $(1)/lib/firmware
	$(INSTALL_DIR) $(1)/lib/firmware/brcm
#	$(INSTALL_DATA) ./files/lib/firmware/brcm/brcmfmac4366c-pcie.bin_69027 $(1)/lib/firmware/brcm/brcmfmac4366c-pcie.bin
	$(INSTALL_DATA) ./files/lib/firmware/brcm/brcmfmac4366c-pcie.bin_ac88.48260 $(1)/lib/firmware/brcm/brcmfmac4366c-pcie.bin
#	$(INSTALL_DATA) ./files/lib/firmware/brcm/brcmfmac4366c-pcie.bin_ac88_1 $(1)/lib/firmware/brcm/brcmfmac4366c-pcie.bin
#	$(INSTALL_DATA) ./files/lib/firmware/brcm/brcmfmac4366c-pcie.bin_ac88_2 $(1)/lib/firmware/brcm/brcmfmac4366c-pcie.bin
#	$(INSTALL_DATA) ./files/lib/firmware/brcm/brcmfmac4366c-pcie.bin_ac88_3 $(1)/lib/firmware/brcm/brcmfmac4366c-pcie.bin
#	$(INSTALL_DATA) ./files/lib/firmware/brcm/brcmfmac4366c-pcie.bin_asus-dhd24 $(1)/lib/firmware/brcm/brcmfmac4366c-pcie.bin
#	$(INSTALL_DATA) ./files/lib/firmware/brcm/brcmfmac4366c-pcie.bin_ea9500_175339 $(1)/lib/firmware/brcm/brcmfmac4366c-pcie.bin
#	$(INSTALL_DATA) ./files/lib/firmware/brcm/brcmfmac4366c-pcie.bin_ea9500_179240 $(1)/lib/firmware/brcm/brcmfmac4366c-pcie.bin
#	$(INSTALL_DATA) ./files/lib/firmware/brcm/brcmfmac4366c-pcie.bin_k3 $(1)/lib/firmware/brcm/brcmfmac4366c-pcie.bin
#	$(INSTALL_DATA) ./files/lib/firmware/brcm/brcmfmac4366c-pcie.bin_r8500 $(1)/lib/firmware/brcm/brcmfmac4366c-pcie.bin
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
