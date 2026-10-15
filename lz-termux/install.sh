#!/bin/bash
# ============================================================
# LZ 服务管理控制台 - 一键安装脚本 (兼容 curl 和 wget)
# ============================================================

set -e

GITHUB_URL="https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh"

echo ">>> 正在下载 LZ 主脚本..."

# ============ 通用下载函数（支持进度条 + 自动重试） ============
download_file() {
    local url="$1"
    local out="$2"
    if command -v curl &>/dev/null; then
        # -f 失败不写入垃圾，-L 跟随重定向，--retry 3 重试3次，--progress-bar 显示进度条
        curl -fL --retry 3 --connect-timeout 15 --progress-bar "$url" -o "$out" && return 0
    fi
    if command -v wget &>/dev/null; then
        # --tries=3 重试3次，--progress=bar:force 强制显示进度条
        wget --tries=3 --timeout=15 --progress=bar:force -O "$out" "$url" && return 0
    fi
    return 1
}

# ============ 多节点容灾下载逻辑 ============
SUCCESS=0
URLS=(
    "$GITHUB_URL"
    "https://tvv.tw/$GITHUB_URL"
    "https://proxy.lalifeier.eu.org/$GITHUB_URL"
    "https://ghproxy.net/$GITHUB_URL"
    "https://mirror.ghproxy.com/$GITHUB_URL"
)

for url in "${URLS[@]}"; do
    echo ">>> 尝试: $url"
    if download_file "$url" ~/lz-menu.sh; then
        SUCCESS=1
        echo "    [✔] 下载成功"
        break
    else
        echo "    [✘] 该节点失败，尝试下一个..."
    fi
done

if [ "$SUCCESS" -eq 0 ]; then
    echo ">>> [失败] 所有节点均无法下载，请检查网络！"
    exit 1
fi

# ============ 配置环境 ============
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
