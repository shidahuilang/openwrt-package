include $(TOPDIR)/rules.mk

PKG_NAME:=einat-ebpf
PKG_VERSION:=0.1.2
PKG_RELEASE:=3

#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
#PKG_SOURCE_URL:=https://codeload.github.com/EHfive/einat-ebpf/tar.gz/refs/tags/v$(PKG_VERSION)?
#PKG_HASH:=17bb289475687cb6970415afc35c374ea80cd01e59964f2f9a611f6fe88f4270

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/EHfive/einat-ebpf.git
PKG_SOURCE_VERSION:=9286f98e6ab9fe1ee58aff999adf511d30149163
PKG_MIRROR_HASH:=skip
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_MAINTAINER:=Anya Lin <hukk1996@gmail.com>
PKG_LICENSE:=GPL-2.0-or-later GPL-2.0-only
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=rust/host
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

PKG_CONFIG_DEPENDS+= \
	CONFIG_EINAT_EBPF_IPV6

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/bpf.mk
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk

define Package/$(PKG_NAME)
  SECTION:=net
  CATEGORY:=Network
  SUBMENU:=Routing and Redirection
  TITLE:=eBPF-based Endpoint-Independent NAT
  URL:=https://github.com/EHfive/einat-ebpf
  # You need enable KERNEL_DEBUG_INFO_BTF and disable KERNEL_DEBUG_INFO_REDUCED
  DEPENDS:=$(RUST_ARCH_DEPENDS) $(BPF_DEPENDS) +libelf +zlib +kmod-sched-core +kmod-sched-bpf \
    +@KERNEL_DEBUG_FS +@KERNEL_DEBUG_INFO_BTF
  USERID:=einat:einat
  PROVIDES:=einat
endef

define Package/$(PKG_NAME)/description
  This eBPF application implements an "Endpoint-Independent Mapping" and
  "Endpoint-Independent Filtering" NAT(network address translation) on
  TC egress and ingress hooks.
endef

define Package/$(PKG_NAME)/config
	menu "Features configuration"
		depends on PACKAGE_einat-ebpf

		config EINAT_EBPF_IPV6
			bool "Enable IPV6 NAT66 feature"
			default n
			help
			  It would increase load time of eBPF programs to
			  about 4 times.
	endmenu
endef

RUST_PKG_FEATURES:=$(subst $(space),$(comma),$(strip \
	$(if $(CONFIG_EINAT_EBPF_IPV6),ipv6) \
))

define Package/$(PKG_NAME)/conffiles
/etc/config/einat
endef

define Package/$(PKG_NAME)/install
	$(CURDIR)/.prepare.sh $(VERSION) $(CURDIR) $(PKG_INSTALL_DIR)/bin/einat

	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_INSTALL_DIR)/bin/einat $(1)/usr/bin/

	$(INSTALL_DIR) $(1)/etc/init.d/
	$(INSTALL_BIN) $(CURDIR)/files/einat.init $(1)/etc/init.d/einat

	$(INSTALL_DIR) $(1)/etc/config/
	$(INSTALL_CONF) $(CURDIR)/files/einat.config $(1)/etc/config/einat

	$(INSTALL_DIR) $(1)/etc/capabilities/
	$(INSTALL_CONF) $(CURDIR)/files/capabilities.json $(1)/etc/capabilities/einat.json
endef

$(eval $(call RustBinPackage,$(PKG_NAME)))
$(eval $(call BuildPackage,$(PKG_NAME)))
