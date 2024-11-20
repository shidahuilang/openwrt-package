include $(TOPDIR)/rules.mk

PKG_NAME:=einat-ebpf
PKG_VERSION:=0.1.3
PKG_RELEASE:=7

#PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
#PKG_SOURCE_URL:=https://codeload.github.com/EHfive/einat-ebpf/tar.gz/refs/tags/v$(PKG_VERSION)?
#PKG_HASH:=17bb289475687cb6970415afc35c374ea80cd01e59964f2f9a611f6fe88f4270

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/EHfive/einat-ebpf.git
PKG_SOURCE_VERSION:=ccb32a353238415f208ca27a988c8a7c4c9d27ee
PKG_MIRROR_HASH:=skip
PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz

PKG_MAINTAINER:=Anya Lin <hukk1996@gmail.com>
PKG_LICENSE:=GPL-2.0-or-later GPL-2.0-only
PKG_LICENSE_FILES:=LICENSE

PKG_BUILD_DEPENDS:=rust/host libbpf #install libbpf headers
PKG_BUILD_PARALLEL:=1
PKG_BUILD_FLAGS:=no-mips16

PKG_CONFIG_DEPENDS+= \
	CONFIG_EINAT_EBPF_IPV6 \
	CONFIG_EINAT_EBPF_BACKEND_LIBBPF \
	CONFIG_EINAT_EBPF_BINDGEN \
	CONFIG_EINAT_EBPF_STATIC \

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
  DEPENDS:=$(RUST_ARCH_DEPENDS) $(BPF_DEPENDS) \
	+kmod-sched-core +kmod-sched-bpf \
    +EINAT_EBPF_BACKEND_LIBBPF:libbpf \
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

		config EINAT_EBPF_BACKEND_LIBBPF
			bool "Enable libbpf backend"
			default n
			help
			  Add fallback BPF loading backend: "libbpf".

		config EINAT_EBPF_BINDGEN
			bool "Enable bindgen"
			default n
			help
			  Bindgen for libbpf headers, required on 32-bit
			  platforms.

		config EINAT_EBPF_STATIC
			bool "Enable static compile"
			default n
	endmenu
endef

RUST_PKG_FEATURES:=$(subst $(space),$(comma),$(strip \
	$(if $(CONFIG_EINAT_EBPF_IPV6),ipv6) \
	$(if $(CONFIG_EINAT_EBPF_BACKEND_LIBBPF),libbpf) \
	$(if $(CONFIG_EINAT_EBPF_BINDGEN),bindgen) \
	$(if $(CONFIG_EINAT_EBPF_STATIC),static) \
))

#export EINAT_BPF_CFLAGS="-I/usr/include/aarch64-linux-gnu"

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
