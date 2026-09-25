include $(TOPDIR)/rules.mk

# Node.js 已从 OpenWrt 官方 packages feed 移除（25.12 起），
# 这里把 nodejs.org 官方 musl-x64 预编译二进制重新打成 apk。
# 仓库：https://github.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25

PKG_NAME:=node
PKG_VERSION:=22.23.3
PKG_RELEASE:=1

PKG_SOURCE:=node-v$(PKG_VERSION)-linux-x64-musl.tar.xz
PKG_SOURCE_URL:=https://nodejs.org/dist/v$(PKG_VERSION)/
PKG_HASH:=0564c678817e6b6fd7860689283185cecdf42e644135b45636094757b9a7922b

PKG_BUILD_DIR:=$(BUILD_DIR)/node-v$(PKG_VERSION)-linux-x64-musl
PKGARCH:=x86_64

PKG_LICENSE:=MIT
PKG_LICENSE_FILES:=LICENSE
PKG_MAINTAINER:=repacked from nodejs.org official linux-x64-musl build

include $(INCLUDE_DIR)/package.mk

define Package/node
  SECTION:=lang
  CATEGORY:=Languages
  SUBMENU:=Node.js
  TITLE:=Node.js runtime (official musl x86_64 build)
  URL:=https://nodejs.org/
  DEPENDS:=@TARGET_x86_64 +libc +libgcc +libstdcpp
  PROVIDES:=nodejs
endef

# The official linux-x64-musl binary requests musl's loader as a SONAME.
# OpenWrt packages libc under an ABI package name, so declare the loader SONAME
# explicitly to map the ELF dependency to the libc package dependency above.
define Package/node/extra_provides
	echo "libc.musl-x86_64.so.1"
endef

define Package/node/description
  Node.js 22 runtime, repackaged from the official linux-x64-musl prebuilt
  binary, so that packages depending on "node" can be installed via apk.
endef

# 二进制是预编译的，无需 configure / compile
define Build/Configure
endef

define Build/Compile
endef

define Package/node/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/node $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/npm $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/npx $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/bin/corepack $(1)/usr/bin/
	$(CP) $(PKG_BUILD_DIR)/lib/node_modules $(1)/usr/lib/
endef

$(eval $(call BuildPackage,node))
