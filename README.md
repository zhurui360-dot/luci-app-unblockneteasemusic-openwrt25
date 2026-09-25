# luci-app-unblockneteasemusic for OpenWrt 25.12

解锁网易云音乐灰色/无版权歌曲的 LuCI 插件（OpenWrt/iStoreOS 25.12 专用 apk 版）。

## 这是什么

本仓库是 [UnblockNeteaseMusic/luci-app-unblockneteasemusic](https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic)（`js` 分支）的**自动编译仓库**：用 GitHub Actions + OpenWrt 官方 25.12 SDK 重新打包，不发到 Release 之外的任何改动。上游项目使用 GPL-3.0-only 协议。

插件本体功能（来自上游）：

- 在路由器层面代理网易云音乐客户端的请求，用其他音源（酷狗 / 酷我 / 咪咕等）替换灰色歌曲
- 全屋生效：家里所有设备（手机、平板、车机）无需装任何客户端
- 提供 LuCI 网页界面，可开关、选音源、看运行状态和日志

### 为什么需要重新编译

上游 Release 只提供 `.ipk`，而 OpenWrt 25.12（iStoreOS 25.12.x，内核 6.12）已把包管理器从 opkg 换成 **apk**，`.ipk` 装不上。本仓库用 25.12 SDK 编出 `.apk`。

另外，25.12 的官方软件源**已移除 Node.js**，而插件依赖 `node` 运行核心脚本。本仓库把 Node.js 官方 musl-x64 预编译版打成 `node-22.23.3-r1.apk` 一并发布（仅支持 x86_64 设备）。

## 怎么安装

### 一键安装（推荐，需 x86_64 设备）

SSH 登录路由器后执行：

```sh
wget -O - https://raw.githubusercontent.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/main/install.sh | sh
```

脚本会自动判断 apk/opkg、安装 Node.js 运行时和 dnsmasq-full、下载并校验（SHA-256）插件包、刷新 LuCI。

指定历史版本：

```sh
export RELEASE_TAG=v3.4-1-openwrt25.12
wget -O - https://raw.githubusercontent.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/main/install.sh | sh
```

### 手动安装（OpenWrt 25.12 / apk）

```sh
# 1. 先装 Node.js 运行时（官方源已移除）
apk add --allow-untrusted \
  https://github.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/releases/latest/download/node-22.23.3-r1.apk

# 2. 装插件
apk add --allow-untrusted \
  https://github.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/releases/latest/download/luci-app-unblockneteasemusic-3.4-r1.apk

# 3. 刷新 LuCI
rm -rf /tmp/luci-* && service rpcd restart && service uhttpd restart
```

> 说明：OpenWrt SDK 打出的 `.apk` 单文件不带签名，`apk add` 本地文件必须加
> `--allow-untrusted`（导入公钥没用，签名只在软件源索引上生效）。完整性由
> HTTPS 下载 + 一键安装脚本内的 SHA-256 摘要校验保障。

### OpenWrt 24.10（opkg，旧版系统）

```sh
opkg update
opkg install node dnsmasq
opkg install ./luci-app-unblockneteasemusic_*.ipk
```

## 怎么用

1. 浏览器打开路由器管理页 → 左侧菜单 **服务 → 解除网易云音乐播放限制**
2. **勾选「启用本插件」**
3. **音源接口**选「默认」即可（想要更高音质可试「酷我」或「咪咕」）
4. **劫持方式选 Hosts** —— 25.12 使用 fw4/nftables，旧的 IPset 方式不生效
5. 首次启动会自动下载音乐核心（Node.js 脚本），走 GitHub，国内网络可能较慢，可在「状态」页看进度
6. 手机/电脑上的网易云音乐 App 照常登录使用，灰色歌曲即可播放

HTTPS 音源（可选）：需要在客户端信任证书
[ca.crt](https://raw.githubusercontent.com/UnblockNeteaseMusic/server/enhanced/ca.crt)

## 支持的设备

| 架构 | 插件界面 | Node.js 运行时 |
|------|:---:|:---:|
| x86_64（iStoreOS 常见软路由） | ✅ 任意架构可用 | ✅ |
| ARM / MIPS 等 | ✅ 任意架构可用 | ❌ 暂未提供，需自行解决 node 依赖 |

## 自己编译

```sh
# 推送 v* 标签自动触发，或手动：
gh workflow run build.yml -f tag=<tag名> -f publish=true
```

构建流程：拉取上游 `js` 分支 → OpenWrt 25.12.4 SDK（x86/64）→ 编译插件 + Node 运行时 → 发布 Release。

## 注意

- 25.12 的 LuCI 是 JS 版，必须用上游 `js` 分支；`master` 分支是 Lua 版，装上去界面不显示
- 本仓库不修改上游任何代码，仅重新打包；如遇插件功能问题请到[上游仓库](https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic)反馈
