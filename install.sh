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
KEYS_DIR="/etc/apk/keys"

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
  KEY_URL="$FALLBACK/builder.rsa.pub"
else
  PKG_URL="$(pick 'luci-app-unblockneteasemusic-[0-9a-z.-]*\.apk')"
  KEY_URL="$(pick 'builder\.rsa\.pub')"
  [ -n "$KEY_URL" ] || KEY_URL="$(pick 'public-key\.pem')"
  [ -n "$KEY_URL" ] || KEY_URL="$(pick 'key-build[^"]*\.pub')"
fi

if command -v apk >/dev/null 2>&1; then
  ########## OpenWrt 25.12（apk） ##########
  [ -n "$PKG_URL" ] || die "取不到 apk 下载地址"
  say "OpenWrt 25.12 / 使用 apk"

  say "安装依赖 node + dnsmasq"
  apk update || true
  apk add node dnsmasq || echo "（依赖安装失败请手动处理，继续尝试安装插件）"

  if [ -n "$KEY_URL" ]; then
    say "导入构建签名公钥"
    mkdir -p "$KEYS_DIR"
    get "$KEY_URL" "$KEYS_DIR/builder.rsa.pub"
  fi

  say "下载插件"
  get "$PKG_URL" /tmp/unb-pkg.apk

  say "安装插件"
  apk add --allow-untrusted /tmp/unb-pkg.apk

elif command -v opkg >/dev/null 2>&1; then
  ########## OpenWrt 24.10（opkg） ##########
  PKG_IPK="$(echo "$JSON" | tr ',{' '\n\n' | grep -o "https://[^\"]*luci-app-unblockneteasemusic[^.]*[0-9a-z.-]*\.ipk" | head -1)"
  [ -n "$PKG_IPK" ] || die "Release 里没有 .ipk（当前 Release 只针对 25.12 编译）"

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
