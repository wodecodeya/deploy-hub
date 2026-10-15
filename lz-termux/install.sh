#!/bin/bash
# ============================================================
# LZ 服务管理控制台 - 一键安装脚本 (安全重构版)
# ============================================================

set -e

GITHUB_URL="https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh"

echo ">>> 正在下载 LZ 主脚本..."

# ============ 通用下载函数（支持进度条 + 自动重试） ============
download_file() {
    local url="$1"
    local out="$2"
    if command -v curl &>/dev/null; then
        curl -fL --retry 3 --connect-timeout 15 --progress-bar "$url" -o "$out" && return 0
    fi
    if command -v wget &>/dev/null; then
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
mkdir -p $PREFIX/bin
ln -sf ~/lz-menu.sh $PREFIX/bin/lz

# ============ 安全配置开机自启动 ============
echo ">>> 正在配置开机自启动..."

# 1. 检查并修复可能因异常退出导致的 .bashrc 损坏
if ! bash -n ~/.bashrc &>/dev/null; then
    echo ">>> [警告] 检测到 .bashrc 存在语法错误，正在自动备份并重置..."
    mv ~/.bashrc ~/.bashrc.bak.$(date +%Y%m%d%H%M%S)
    touch ~/.bashrc
fi

# 2. 创建独立的启动配置文件 (隔离风险)
cat << 'EOF' > ~/.lz_profile
# LZ 服务管理控制台自动启动
if [ -n "$PS1" ] && [ -z "$LZ_MENU_STARTED" ]; then
    export LZ_MENU_STARTED=1
    [ -f ~/lz-menu.sh ] && bash ~/lz-menu.sh --boot
fi
EOF

# 3. 清理 .bashrc 中的旧配置残留，并安全引入新配置
sed -i '/LZ_MENU_STARTED/d; /lz-menu.sh/d; /lz_profile/d' ~/.bashrc 2>/dev/null || true
echo '[ -f ~/.lz_profile ] && source ~/.lz_profile' >> ~/.bashrc

echo ""
echo "========================================="
echo "✅ 部署完成！"
echo "   重启 App 自动进菜单"
echo "   或输入 lz 秒进菜单"
echo "========================================="
