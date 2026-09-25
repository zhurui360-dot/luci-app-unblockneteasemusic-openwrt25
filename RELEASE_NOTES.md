## luci-app-unblockneteasemusic 编译产物

源码：[UnblockNeteaseMusic/luci-app-unblockneteasemusic](https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic) `js` 分支
许可证：GPL-3.0-only

本仓库不修改上游任何代码，仅用 OpenWrt 官方 SDK 重新编译并发布。

### 产物说明

| 文件 | 说明 |
| --- | --- |
| `luci-app-unblockneteasemusic-3.4-r1.apk` | 插件本体，OpenWrt 25.12（内核 6.12），apk 安装 |
| `builder.rsa.pub` | 本次构建的签名公钥，内容同 `public-key.pem`，符合 apk 命名习惯 |

插件本身与 CPU 架构无关（`all`），因此 x86/64 SDK 编出的包可直接用于 aarch64 / arm 等任何架构。

> 每次 workflow 运行都会用 SDK 生成一把新密钥，所以**升级到新版本时要重新导入本 Release 里的公钥**（下面的安装命令和 `install.sh` 都已经处理了）。

### 一键安装（推荐）

```sh
wget -O - https://raw.githubusercontent.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/main/install.sh | sh
```

### 手动安装（OpenWrt 25.12）

```sh
apk update
apk add node dnsmasq

# 导入本版本的构建签名公钥
mkdir -p /etc/apk/keys
wget -O /etc/apk/keys/builder.rsa.pub \
  https://github.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/releases/latest/download/builder.rsa.pub

# 安装插件，不需要 --allow-untrusted
wget -O /tmp/unb.apk \
  https://github.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/releases/latest/download/luci-app-unblockneteasemusic-3.4-r1.apk
apk add /tmp/unb.apk

rm -rf /tmp/luci-* && service rpcd restart && service uhttpd restart
```

来不及导公钥就临时跳过校验：`apk add --allow-untrusted /tmp/unb.apk`（会报 `UNTRUSTED signature` / code 99 时用它）

### 使用

1. LuCI → 服务 → 解除网易云音乐播放限制，勾选启用
2. 音源接口选「默认」，高音质推荐「酷我」或「咪咕」
3. **劫持方式建议选 Hosts**：25.12 默认防火墙是 fw4/nftables，老的 IPset 劫持方式大概率失效
4. 首次启动会在后台下载 Node.js 核心，启动较慢属正常现象
