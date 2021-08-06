include $(TOPDIR)/rules.mk

PKG_NAME:=install-program
PKG_VERSION:=2.6
PKG_RELEASE:=20210106

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Install to emmc script for phicomm n1, beikeyun etc
	DEPENDS:=+block-mount +blkid +parted +dosfstools +e2fsprogs +lsblk +pv +resize2fs +tune2fs +losetup +uuidgen
endef

define Package/$(PKG_NAME)/description
	Install to emmc script for phicomm n1 or beikeyun, it can help you to install the openwrt system to the emmc storage.
endef

define Build/Prepare
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_BIN) ./files/beikeyun-update $(1)/usr/bin/beikeyun-update
	$(INSTALL_BIN) ./files/n1-install $(1)/usr/bin/n1-install
	$(INSTALL_BIN) ./files/n1-update $(1)/usr/bin/n1-update
	$(INSTALL_CONF) ./files/fstab $(1)/etc/config/fstab
	$(INSTALL_CONF) ./files/fstab $(1)/etc/config/fstab.bak
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
