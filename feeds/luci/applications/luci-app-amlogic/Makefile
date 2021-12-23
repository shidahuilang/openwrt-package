#======================================================================================================================
# Description: Support install OpenWrt to EMMC, update the OpenWrt firmware or kernel, and backup/restore config.
# Borrow/Copyright: https://github.com/unifreq/openwrt_packit, luci-app-filetransfer, luci-app-cpufreq, Vernesong, etc.
#======================================================================================================================


include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-amlogic
PKG_VERSION:=3.1.44
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0 License
PKG_MAINTAINER:=ophub <https://github.com/ophub/luci-app-amlogic>

LUCI_TITLE:=LuCI support for Amlogic, Allwinner and Rockchip related boxs
LUCI_PKGARCH:=all
LUCI_DEPENDS:= \
	@(aarch64||arm) +luci-lib-fs +block-mount +blkid +parted \
	+dosfstools +e2fsprogs +lsblk +pv +resize2fs +losetup +uuidgen

define Package/$(PKG_NAME)/conffiles
/etc/config/amlogic
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
