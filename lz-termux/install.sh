#!/bin/bash
# ============================================================
# LZ 服务管理控制台 - 一键安装脚本 (兼容 curl 和 wget)
# ============================================================

set -e

GITHUB_URL="https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh"
PROXY_URL="https://tvv.tw/$GITHUB_URL"

echo ">>> 正在下载 LZ 主脚本..."

download_file() {
    local url="$1"
    local out="$2"
    if command -v curl &>/dev/null; then
        curl -fsSL --connect-timeout 10 "$url" -o "$out" && return 0
    fi
    if command -v wget &>/dev/null; then
        wget -q --timeout=10 -O "$out" "$url" && return 0
    fi
    return 1
}

if download_file "$GITHUB_URL" ~/lz-menu.sh; then
    echo "    [✔] 直连成功"
elif download_file "$PROXY_URL" ~/lz-menu.sh; then
    echo "    [✔] 代理成功"
else
    echo ">>> [失败] 无法下载脚本，请检查网络！"
    exit 1
fi

echo ">>> 正在授权并创建 lz 快捷命令..."
chmod +x ~/lz-menu.sh
ln -sf ~/lz-menu.sh $PREFIX/bin/lz

echo ">>> 正在配置开机自启动..."
sed -i '/LZ_MENU_STARTED/d' ~/.bashrc 2>/dev/null || true
sed -i '/lz-menu.sh/d' ~/.bashrc 2>/dev/null || true
printf '\n# LZ 服务管理控制台自动启动\nif [ -n "$PS1" ] && [ -z "$LZ_MENU_STARTED" ]; then\n    export LZ_MENU_STARTED=1\n    bash ~/lz-menu.sh --boot\nfi\n' >> ~/.bashrc

echo ""
echo "========================================="
echo "✅ 部署完成！"
echo "   重启 App 自动进菜单"
echo "   或输入 lz 秒进菜单"
echo "========================================="
