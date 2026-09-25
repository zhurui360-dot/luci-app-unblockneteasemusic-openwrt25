# luci-app-unblockneteasemusic 自动编译

用 GitHub Actions + OpenWrt 官方 SDK 重新编译
[UnblockNeteaseMusic/luci-app-unblockneteasemusic](https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic)
（`js` 分支，即 LuCI JS 版本），并把产物发到 GitHub Release。

不修改上游任何代码，仅做重新打包。上游项目使用 GPL-3.0-only 协议。

## 为什么需要重新编译

上游 Release 只提供 `.ipk`，而 OpenWrt 25.12（内核 6.12）已将包管理器从 opkg 换成
**apk**，`.ipk` 无法直接安装。本仓库用 25.12 SDK 编出 `.apk` 供新版本使用。

## 一键安装（推荐）

在路由器 SSH 里执行一行：

```sh
wget -O - https://raw.githubusercontent.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/main/install.sh | sh
```

脚本会自己判断 `apk` / `opkg`、拉依赖（node、dnsmasq）、导入构建签名公钥、装插件并刷新 LuCI。

想装历史版本可指定（把 RELEASE_TAG 换成 Release 页面的 tag）：

```sh
export RELEASE_TAG=v3.4-1-openwrt25.12
wget -O - https://raw.githubusercontent.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/main/install.sh | sh
```

## 手动安装

### OpenWrt 25.12（apk）

```sh
apk update
apk add node dnsmasq

# 一次性导入构建签名公钥，之后这台机器就免 --allow-untrusted
mkdir -p /etc/apk/keys
wget -O /etc/apk/keys/builder.rsa.pub \
  https://github.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/releases/latest/download/key-build.rsa.pub

wget -O /tmp/unb.apk \
  https://github.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/releases/latest/download/luci-app-unblockneteasemusic-3.4-r1.apk
apk add /tmp/unb.apk

rm -rf /tmp/luci-* && service rpcd restart && service uhttpd restart
```

不想导公钥就临时跳过校验：`apk add --allow-untrusted /tmp/unb.apk`

### OpenWrt 24.10（opkg）

```sh
opkg update
opkg install node dnsmasq
opkg install ./luci-app-unblockneteasemusic_*.ipk
```

## 触发编译

```sh
# 只编译，不发 Release
gh workflow run build.yml

# 编译并发布到指定 tag
gh workflow run build.yml -f tag=v3.4-1-openwrt25.12 -f publish=true

# 或者推送 tag 自动触发
git tag v3.4-1-openwrt25.12 && git push origin v3.4-1-openwrt25.12
```

## 注意

- 25.12 的 LuCI 是 JS 版，必须用上游 `js` 分支；`master` 分支是 Lua 版，装上去界面不显示
- 插件与架构无关（`all`），x86/64 SDK 编出的包可用于任意架构
- SDK 编译出的包是自签名的，安装时需要 `apk add --allow-untrusted`
