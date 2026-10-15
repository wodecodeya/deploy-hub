#!/bin/bash
# ============================================
#   LX Music Server 一键部署 + 自启守护脚本 (官方默认纯净版)
#   支持：自动获取最新版本 | 加速代理 | Termux 唤醒锁 | 开机自启
# ============================================

echo "========================================="
echo "      LX Music Server 一键部署脚本"
echo "========================================="

# ================== 1. 唤醒锁 ==================
termux-wake-lock 2>/dev/null && echo "[✔] 已开启 Termux 唤醒锁 (防止CPU休眠)"

# ================== 2. 变量定义 ==================
GITHUB_REPO="XCQ0607/lxserver"
PROXY="https://proxy.lalifeier.eu.org/"
TARGET_DIR="$HOME/lxserver"
LOG_FILE="$TARGET_DIR/node.log"

# ================== 3. 安装基础环境 ==================
echo ""
echo ">>> 正在检查并安装基础依赖 (wget, unzip, nodejs)..."
pkg update -y > /dev/null 2>&1
pkg install wget unzip nodejs -y > /dev/null 2>&1

# ================== 4. 动态获取最新版本号 ==================
echo ""
echo ">>> 正在查询 GitHub 最新版本..."
LATEST_TAG=""
API_URL="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
RAW_API_URL="${PROXY}${API_URL}"
LATEST_TAG=$(wget -qO- --timeout=30 "$RAW_API_URL" | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "[!] 无法获取最新版本号，尝试直连 GitHub..."
    LATEST_TAG=$(wget -qO- --timeout=30 "$API_URL" | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
fi

if [ -z "$LATEST_TAG" ]; then
    echo "❌ 获取最新版本号失败，请检查网络或代理。"
    termux-wake-unlock 2>/dev/null
    exit 1
fi
echo "    [✔] 当前最新版本: $LATEST_TAG"

# ================== 5. 构造下载链接并下载 ==================
ZIP_NAME="lx-music-sync-server-${LATEST_TAG}-server.zip"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_TAG}/${ZIP_NAME}"
ZIP_FILE="$HOME/${ZIP_NAME}"

echo ""
echo ">>> 正在下载 $ZIP_NAME ..."
download_pkg() {
    echo "    [尝试1] 使用加速代理下载..."
    if wget -q --timeout=30 -O "$ZIP_FILE" "${PROXY}${DOWNLOAD_URL}"; then
        echo "    [✔] 加速代理下载成功！"
        return 0
    fi
    echo "    [!] 加速代理失败，尝试直连 GitHub..."
    if wget -q --timeout=60 -O "$ZIP_FILE" "$DOWNLOAD_URL"; then
        echo "    [✔] 直连下载成功！"
        return 0
    fi
    echo "    [✘] 所有下载方式均失败，请检查网络连接或 VPN。"
    return 1
}
if ! download_pkg; then
    termux-wake-unlock 2>/dev/null
    exit 1
fi

# ================== 6. 解压 & 处理套娃目录 ==================
echo ""
echo ">>> 正在解压并整理目录结构..."
rm -rf "$HOME/lxserver_temp"
mkdir -p "$HOME/lxserver_temp"
unzip -o "$ZIP_FILE" -d "$HOME/lxserver_temp" > /dev/null 2>&1
PROJECT_DIR=$(find "$HOME/lxserver_temp" -name "package.json" -maxdepth 2 -exec dirname {} \; | head -n 1)

if [ -z "$PROJECT_DIR" ]; then
    echo "❌ 解压失败，找不到 package.json，请检查压缩包是否完整。"
    termux-wake-unlock 2>/dev/null
    exit 1
fi

# ================== 7. 备份旧数据 & 替换目录 ==================
if [ -d "$TARGET_DIR" ]; then
    echo "⚠️ 发现原有 lxserver 目录，正在备份为 lxserver_old_temp ..."
    rm -rf "$HOME/lxserver_old_temp"
    mv "$TARGET_DIR" "$HOME/lxserver_old_temp"
fi
mv "$PROJECT_DIR" "$TARGET_DIR"
rm -rf "$HOME/lxserver_temp"

# ================== 8. 安装依赖 ==================
echo ""
echo ">>> 正在安装 Node.js 依赖（耐心等待 1-2 分钟）..."
cd "$TARGET_DIR"
npm install --production > /dev/null 2>&1

# ================== 9. 配置 Termux 开机自启 ==================
echo ""
echo ">>> 正在配置 Termux 自动启动逻辑..."
if ! grep -q "lxserver_autostart" ~/.bashrc; then
    cat << 'EOF' >> ~/.bashrc

# === lxserver_autostart ===
if ! pgrep -f "node index.js --app=node2" > /dev/null; then
    echo ">>> [自启] 检测到洛雪服务未运行，正在自动启动..."
    termux-wake-lock
    cd ~/lxserver && nohup node index.js --app=node2 > ~/lxserver/node.log 2>&1 &
fi
# ==========================
EOF
    echo "[✔] 已配置自动启动 (写入 ~/.bashrc)"
else
    echo "[跳过] 自动启动配置已存在，无需重复添加"
fi

# ================== 10. 启动服务 ==================
echo ""
echo ">>> 正在启动洛雪音乐服务..."
killall -9 node 2>/dev/null || true
nohup node index.js --app=node2 > "$LOG_FILE" 2>&1 &
sleep 4

# ================== 11. 检查启动状态 ==================
echo ""
echo ">>> 正在检查启动状态..."
if cat "$LOG_FILE" | grep -q "Error"; then
    echo "❌ 启动失败，日志如下："
    cat "$LOG_FILE"
else
    echo "✅ 部署启动成功！服务运行在端口 9527。"
    echo "📁 项目目录: $TARGET_DIR"
    echo "📝 日志文件: $LOG_FILE"
fi

termux-wake-unlock 2>/dev/null && echo "[✔] 已释放 Termux 唤醒锁 (后台由 nohup 维持)"
echo "========================================="
