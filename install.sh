#!/bin/sh
# 一键安装 luci-app-unblockneteasemusic（OpenWrt 25.12 / 24.10）
#
# 用法：
#   wget -O - https://raw.githubusercontent.com/zhurui360-dot/luci-app-unblockneteasemusic-openwrt25/main/install.sh | sh
#
set -e

OWNER="zhurui360-dot"
REPO="luci-app-unblockneteasemusic-openwrt25"
RELEASE_TAG="${RELEASE_TAG:-v3.4-1-openwrt25.12}"

say() { echo "==> $*"; }
die() { echo "!!! $*" >&2; exit 1; }

# 下载工具（OpenWrt 不一定有 curl）
if command -v curl >/dev/null 2>&1; then
  fetch() { curl -fsSL "$1"; }
  get()   { curl -fsSL -o "$2" "$1"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget -qO- "$1"; }
  get()   { wget -q -O "$2" "$1"; }
elif command -v uclient-fetch >/dev/null 2>&1; then
  fetch() { uclient-fetch -q -O- "$1"; }
  get()   { uclient-fetch -q -O "$2" "$1"; }
else
  die "找不到 curl / wget / uclient-fetch，请先 opkg/apk install curl"
fi

# 从 Release 里挑出对应格式的产物和签名公钥
API="https://api.github.com/repos/$OWNER/$REPO/releases/latest"
FALLBACK="https://github.com/$OWNER/$REPO/releases/download/$RELEASE_TAG"

JSON="$(fetch "$API" 2>/dev/null || true)"

pick() {
  echo "$JSON" | tr ',{' '\n\n' | grep -o "https://[^\"]*$1" | head -1
}

if [ -z "$JSON" ]; then
  say "无法访问 GitHub API，改用固定版本 $RELEASE_TAG"
  PKG_URL="$FALLBACK/luci-app-unblockneteasemusic-3.4-r1.apk"
  NODE_URL="$FALLBACK/node-22.23.3-r1.apk"
  KEY_URL="$FALLBACK/builder.rsa.pub"
else
  PKG_URL="$(pick 'luci-app-unblockneteasemusic-[0-9a-z.-]*\.apk')"
  NODE_URL="$(pick 'node-[0-9][^"]*\.apk')"
  KEY_URL="$(pick 'builder\.rsa\.pub')"
  [ -n "$KEY_URL" ] || KEY_URL="$(pick 'public-key\.pem')"
  [ -n "$KEY_URL" ] || KEY_URL="$(pick 'key-build[^"]*\.pub')"
fi

if command -v apk >/dev/null 2>&1; then
  ########## OpenWrt 25.12（apk） ##########
  [ -n "$PKG_URL" ] || die "取不到 apk 下载地址"
  say "OpenWrt 25.12 / 使用 apk"

  # 说明：OpenWrt SDK 打出的 .apk 单文件本身不带签名（签名只在软件源索引上），
  # 因此本地 apk add 必然报 UNTRUSTED，导入公钥也无济于事。
  # 这里的完整性保障是：HTTPS 下载 + GitHub Release API 的 sha256 摘要校验。
  verify_digest() {
    # verify_digest <下载URL> <本地文件> —— 尽力而为：拿不到摘要就跳过
    [ -n "$JSON" ] || return 0
    want="$(echo "$JSON" | tr ',' '\n' | awk -v u="$1" '
      /browser_download_url/ { if (index($0, u)) { print d; exit } }
      /sha256:[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]/ {
        d = $0; sub(/.*sha256:/, "", d); sub(/".*/, "", d); d = "sha256:" d
      }')"
    [ -n "$want" ] || { say "（未取到 SHA-256 摘要，跳过校验）"; return 0; }
    got="sha256:$(sha256sum "$2" | cut -d' ' -f1)"
    if [ "$got" = "$want" ]; then
      say "SHA-256 校验通过"
    else
      die "SHA-256 校验失败（期望 $want，实际 $got），文件可能被篡改或下载不完整"
    fi
  }

  # OpenWrt 25.12 官方源已移除 Node.js，本仓库提供官方 musl 二进制打好的包
  if ! command -v node >/dev/null 2>&1; then
    if [ -n "$NODE_URL" ]; then
      say "安装 Node.js 运行时（本仓库提供，官方源已移除）"
      get "$NODE_URL" /tmp/unb-node.apk
      verify_digest "$NODE_URL" /tmp/unb-node.apk
      apk add --allow-untrusted /tmp/unb-node.apk
      rm -f /tmp/unb-node.apk
    else
      say "尝试从软件源安装 node"
      apk update || true
      apk add node || die "软件源里没有 node，且 Release 里也没找到 node-*.apk"
    fi
  else
    say "已检测到 Node.js: $(node -v 2>/dev/null || echo unknown)"
  fi

  say "安装 dnsmasq-full（插件需要）"
  apk update || true
  apk add dnsmasq-full || echo "（dnsmasq-full 安装失败请手动处理，Hosts 劫持方式用系统自带 dnsmasq 也能跑）"

  say "下载插件"
  get "$PKG_URL" /tmp/unb-pkg.apk
  verify_digest "$PKG_URL" /tmp/unb-pkg.apk

  say "安装插件"
  apk add --allow-untrusted /tmp/unb-pkg.apk
  rm -f /tmp/unb-pkg.apk

  # 校验 node 真的能跑（musl / glibc 不匹配会在这里暴露）
  if ! node -v >/dev/null 2>&1; then
    echo "!!! 警告：node 无法执行，多半是 musl/glibc 不匹配" >&2
    echo "    本仓库的 node 包是 musl 版（OpenWrt 默认 libc）。" >&2
    echo "    请把 \`ls /lib/ld-* /lib/libc.so*\` 的输出发给我确认。" >&2
  fi

elif command -v opkg >/dev/null 2>&1; then
  ########## OpenWrt 24.10（opkg） ##########
  PKG_IPK="$(echo "$JSON" | tr ',{' '\n\n' | grep -o "https://[^\"]*luci-app-unblockneteasemusic[^.]*[0-9a-z.-]*\.ipk" | head -1)"
  [ -n "$PKG_IPK" ] || die "Release 里没有 .ipk（当前只针对 OpenWrt 25.12 发布）"

  say "OpenWrt 24.10 / 使用 opkg"
  opkg update || true
  opkg install node dnsmasq || echo "（依赖安装失败请手动处理）"

  say "下载插件"
  get "$PKG_IPK" /tmp/unb-pkg.ipk

  say "安装插件"
  opkg install /tmp/unb-pkg.ipk
else
  die "既没有 apk 也没有 opkg，这好像不是 OpenWrt"
fi

say "刷新 LuCI 缓存"
rm -rf /tmp/luci-* /tmp/unb-pkg.* 2>/dev/null || true
/etc/init.d/rpcd restart 2>/dev/null || service rpcd restart 2>/dev/null || true
/etc/init.d/uhttpd restart 2>/dev/null || service uhttpd restart 2>/dev/null || true

cat <<'EOF'

安装完成。

下一步：
  1. LuCI → 服务 → 解除网易云音乐播放限制，勾选「启用本插件」
  2. 音源接口选「默认」（要高音质选「酷我」或「咪咕」）
  3. 「劫持方式」选 Hosts —— 25.12 用 fw4/nftables，IPset 方式不生效
  4. 首次启动会在后台下载 Node.js 核心，慢是正常的；可在「状态」页看进度

HTTPS 音源需要在客户端信任证书（可选）：
  https://raw.githubusercontent.com/UnblockNeteaseMusic/server/enhanced/ca.crt
EOF
