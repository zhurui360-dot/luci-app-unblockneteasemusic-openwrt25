# luci-app-unblockneteasemusic 自动编译

用 GitHub Actions + OpenWrt 官方 SDK 重新编译
[UnblockNeteaseMusic/luci-app-unblockneteasemusic](https://github.com/UnblockNeteaseMusic/luci-app-unblockneteasemusic)
（`js` 分支，即 LuCI JS 版本），并把产物发到 GitHub Release。

不修改上游任何代码，仅做重新打包。上游项目使用 GPL-3.0-only 协议。

## 为什么需要重新编译

上游 Release 只提供 `.ipk`，而 OpenWrt 25.12（内核 6.12）已将包管理器从 opkg 换成
**apk**，`.ipk` 无法直接安装。本仓库用 25.12 SDK 编出 `.apk` 供新版本使用。

## 触发方式

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
