## luci-app-unblockneteasemusic 编译产物

源码：[UnblockNeteaseMusic/luci-app-unblockneteasemusic](https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic) `js` 分支
许可证：GPL-3.0-only

本仓库不修改上游任何代码，仅用 OpenWrt 官方 SDK 重新编译并发布。

### 产物说明

| 文件 | 适用系统 | 包管理器 |
| --- | --- | --- |
| `*.apk` | OpenWrt 25.12.x（内核 6.12） | apk |
| `*.ipk` | OpenWrt 24.10.x（内核 6.6） | opkg |

插件本身与 CPU 架构无关（`all`），因此 x86/64 SDK 编出的包可直接用于 aarch64 / arm 等任何架构。

### 安装（OpenWrt 25.12）

```sh
# 依赖：LuCI JS 界面 + Node.js 核心 + dnsmasq（Hosts 劫持）
apk add node dnsmasq

# 安装插件（自签包需要 --allow-untrusted）
apk add --allow-untrusted ./luci-app-unblockneteasemusic-*.apk

# 刷新 LuCI 缓存
rm -rf /tmp/luci-*
service rpcd restart
service uhttpd restart
```

### 安装（OpenWrt 24.10）

```sh
opkg update
opkg install node dnsmasq
opkg install ./luci-app-unblockneteasemusic_*.ipk
```

### 使用

1. LuCI → 服务 → 解除网易云音乐播放限制，勾选启用
2. 音源接口选「默认」，高音质推荐「酷我」或「咪咕」
3. **劫持方式建议选 Hosts**：25.12 默认防火墙是 fw4/nftables，老的 IPset 劫持方式大概率失效
4. 首次启动会在后台下载 Node.js 核心，启动较慢属正常现象
