#!/bin/bash
# ============================================
#   LX Music Server 工具箱 (部署/卸载/管理)
#   交互式菜单 | 自动获取最新版 | 智能防重复安装
# ============================================

GITHUB_REPO="XCQ0607/lxserver"
PROXY="https://proxy.lalifeier.eu.org/"
TARGET_DIR="$HOME/lxserver"
LOG_FILE="$TARGET_DIR/node.log"
AUTOSTART_TAG="lxserver_autostart"
API_URL="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
MENU_SCRIPT="$HOME/lx_menu.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

check_running() {
    pgrep -f "node index.js --app=node2" > /dev/null
}

get_latest_version() {
    local tag=""
    tag=$(wget -qO- --timeout=30 "${PROXY}${API_URL}" 2>/dev/null | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
    [ -z "$tag" ] && tag=$(wget -qO- --timeout=30 "$API_URL" 2>/dev/null | grep '"tag_name":' | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/')
    echo "$tag"
}

get_local_version() {
    if [ -f "$TARGET_DIR/package.json" ]; then
        grep '"version":' "$TARGET_DIR/package.json" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/'
    fi
}

setup_autostart() {
    if grep -q "$AUTOSTART_TAG" ~/.bashrc; then
        echo -e "${GREEN}    [✔] 自启逻辑已存在${NC}"
        return
    fi
    cat << EOF >> ~/.bashrc

# === ${AUTOSTART_TAG} ===
if ! pgrep -f "node index.js --app=node2" > /dev/null; then
    echo ">>> [自启] 检测到洛雪服务未运行，正在自动启动..."
    termux-wake-lock
    cd ~/lxserver && nohup node index.js --app=node2 > ~/lxserver/node.log 2>&1 &
fi
# ==========================
EOF
    echo -e "${GREEN}    [✔] 已写入自启逻辑到 ~/.bashrc${NC}"
}

setup_alias() {
    if [ -f "$MENU_SCRIPT" ] && grep -q "alias lx=" ~/.bashrc; then
        echo -e "${GREEN}    [✔] 快捷别名 lx 已存在${NC}"
        return
    fi

    cat > "$MENU_SCRIPT" << 'MENU_EOF'
#!/bin/bash
clear
echo "========================================="
echo "       🎵 LX Music Server 工具箱"
echo "========================================="
echo "  [1] 安装 / 更新"
echo "  [2] 启动服务"
echo "  [3] 停止服务"
echo "  [4] 重启服务"
echo "  [5] 查看状态"
echo "  [6] 查看日志"
echo "  [7] 卸载服务"
echo "  [0] 退出"
echo "========================================="
echo "💡 提示：10 秒内无操作，将自动启动服务"
echo "========================================="
read -t 10 -p "请输入选项数字: " choice

if [ -z "$choice" ]; then
    echo ""
    echo "⏰ 超时，自动启动服务..."
    if ! pgrep -f "node index.js --app=node2" > /dev/null; then
        termux-wake-lock
        cd ~/lxserver && nohup node index.js --app=node2 > ~/lxserver/node.log 2>&1 &
        sleep 2
        echo "✅ 服务已自动启动，端口 9527。"
    else
        echo "✅ 服务已经在运行中。"
    fi
    exit 0
fi

case $choice in
    1)
        echo ">>> 正在从 GitHub 拉取部署脚本..."
        bash <(curl -sL "https://proxy.lalifeier.eu.org/https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lxserver/lxmusic_deploy.sh") install
        ;;
    2)
        if pgrep -f "node index.js --app=node2" > /dev/null; then
            echo "⚠️ 服务已经在运行中。"
        else
            termux-wake-lock
            cd ~/lxserver && nohup node index.js --app=node2 > ~/lxserver/node.log 2>&1 &
            sleep 2
            echo "✅ 服务已启动，端口 9527。"
        fi
        ;;
    3)
        pkill -f "node index.js --app=node2" 2>/dev/null
        termux-wake-unlock 2>/dev/null
        echo "✅ 服务已停止。"
        ;;
    4)
        pkill -f "node index.js --app=node2" 2>/dev/null
        sleep 1
        termux-wake-lock
        cd ~/lxserver && nohup node index.js --app=node2 > ~/lxserver/node.log 2>&1 &
        sleep 2
        echo "✅ 服务已重启，端口 9527。"
        ;;
    5)
        if pgrep -f "node index.js --app=node2" > /dev/null; then
            echo "✅ 运行中 (端口: 9527)"
            ps -ef | grep "node index.js" | grep -v grep
        else
            echo "❌ 未运行"
        fi
        echo ""
        echo ">>> 目录占用:"
        du -sh ~/lxserver 2>/dev/null
        ;;
    6)
        echo ">>> 显示最近 50 行日志 (按 Ctrl+C 退出)"
        tail -n 50 -f ~/lxserver/node.log
        ;;
    7)
        read -p "确定要卸载 LX Music Server 吗？此操作会删除所有数据，请输入 'yes' 确认: " confirm
        if [ "$confirm" == "yes" ]; then
            pkill -f "node index.js --app=node2" 2>/dev/null
            rm -rf ~/lxserver
            sed -i "/# === lxserver_autostart ===/,/# ==========================/d" ~/.bashrc
            sed -i "/alias lx=/d" ~/.bashrc
            rm -f ~/lx_menu.sh
            echo "✅ 卸载完成！"
            exit 0
        else
            echo "已取消卸载。"
        fi
        ;;
    0)
        exit 0
        ;;
    *)
        echo "⏰ 无效输入，自动启动服务..."
        if ! pgrep -f "node index.js --app=node2" > /dev/null; then
            termux-wake-lock
            cd ~/lxserver && nohup node index.js --app=node2 > ~/lxserver/node.log 2>&1 &
            sleep 2
            echo "✅ 服务已自动启动，端口 9527。"
        else
            echo "✅ 服务已经在运行中。"
        fi
        ;;
esac
MENU_EOF

    chmod +x "$MENU_SCRIPT"

    sed -i "/alias lx=/d" ~/.bashrc
    echo "alias lx='bash ~/lx_menu.sh'" >> ~/.bashrc

    echo -e "${GREEN}    [✔] 已生成 lx 菜单脚本和别名${NC}"
    echo -e "${CYAN}    💡 以后重开 Termux 后输入 lx 回车即可进入菜单${NC}"
    echo -e "${CYAN}    💡 10 秒内无操作将自动启动服务${NC}"
}

install_lxserver() {
    echo -e "${CYAN}>>> 开始安装/更新 LX Music Server${NC}"
    termux-wake-lock 2>/dev/null || true

    echo -e "${YELLOW}>>> 正在安装基础依赖 (wget, unzip, nodejs)...${NC}"
    pkg update -y > /dev/null 2>&1
    pkg install wget unzip nodejs -y > /dev/null 2>&1

    echo -e "${YELLOW}>>> 正在查询最新版本...${NC}"
    local LATEST_TAG=$(get_latest_version)
    if [ -z "$LATEST_TAG" ]; then
        echo -e "${RED}❌ 获取版本号失败，请检查网络或代理。${NC}"
        termux-wake-unlock 2>/dev/null; return 1
    fi

    local LOCAL_VER=$(get_local_version)
    local clean_local=$(echo "$LOCAL_VER" | sed 's/^v//')
    local clean_latest=$(echo "$LATEST_TAG" | sed 's/^v//')

    if [ "$clean_local" == "$clean_latest" ] && [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}⚠️ 检测到当前已安装最新版本: $LOCAL_VER${NC}"
        echo -e "${YELLOW}>>> 跳过下载安装，检查自启和别名配置...${NC}"
        setup_autostart
        setup_alias
        termux-wake-unlock 2>/dev/null || true
        return 0
    fi

    echo -e "${GREEN}    [✔] 最新版本: ${LATEST_TAG}${NC}"
    local ZIP_NAME="lx-music-sync-server-${LATEST_TAG}-server.zip"
    local DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_TAG}/${ZIP_NAME}"
    local ZIP_FILE="$HOME/${ZIP_NAME}"

    echo -e "${YELLOW}>>> 正在下载 ${ZIP_NAME} ...${NC}"
    if ! wget -q --timeout=30 -O "$ZIP_FILE" "${PROXY}${DOWNLOAD_URL}"; then
        echo -e "${YELLOW}    [!] 加速代理失败，尝试直连...${NC}"
        if ! wget -q --timeout=60 -O "$ZIP_FILE" "$DOWNLOAD_URL"; then
            echo -e "${RED}❌ 下载失败，请检查网络。${NC}"
            termux-wake-unlock 2>/dev/null; return 1
        fi
    fi
    echo -e "${GREEN}    [✔] 下载成功${NC}"

    echo -e "${YELLOW}>>> 正在解压...${NC}"
    rm -rf "$HOME/lxserver_temp"
    mkdir -p "$HOME/lxserver_temp"
    unzip -o "$ZIP_FILE" -d "$HOME/lxserver_temp" > /dev/null 2>&1

    local PROJECT_DIR=$(find "$HOME/lxserver_temp" -name "package.json" -maxdepth 2 -exec dirname {} \; | head -n 1)
    if [ -z "$PROJECT_DIR" ]; then
        echo -e "${RED}❌ 解压失败，找不到 package.json${NC}"
        termux-wake-unlock 2>/dev/null; return 1
    fi

    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}    [!] 备份旧版本到 ~/lxserver_old_temp ...${NC}"
        rm -rf "$HOME/lxserver_old_temp"
        mv "$TARGET_DIR" "$HOME/lxserver_old_temp"
    fi
    mv "$PROJECT_DIR" "$TARGET_DIR"
    rm -rf "$HOME/lxserver_temp"

    echo -e "${YELLOW}>>> 正在安装依赖 (耐心等待)...${NC}"
    cd "$TARGET_DIR" && npm install --production > /dev/null 2>&1

    setup_autostart
    setup_alias

    echo -e "${YELLOW}>>> 正在启动服务...${NC}"
    pkill -f "node index.js --app=node2" 2>/dev/null || true
    cd "$TARGET_DIR" && nohup node index.js --app=node2 > "$LOG_FILE" 2>&1 &
    sleep 4

    if grep -q "Error" "$LOG_FILE"; then
        echo -e "${RED}❌ 启动失败，日志如下：${NC}"
        cat "$LOG_FILE"
    else
        echo -e "${GREEN}✅ 部署启动成功！服务运行在端口 9527。${NC}"
    fi
    termux-wake-unlock 2>/dev/null || true
}

uninstall_lxserver() {
    echo -e "${RED}>>> 确定要卸载 LX Music Server 吗？${NC}"
    read -p "此操作会删除所有数据，请输入 'yes' 确认: " confirm
    if [ "$confirm" != "yes" ]; then
        echo -e "${YELLOW}已取消卸载。${NC}"; return
    fi

    echo -e "${YELLOW}>>> 正在停止服务...${NC}"
    pkill -f "node index.js --app=node2" 2>/dev/null || true

    echo -e "${YELLOW}>>> 正在删除目录...${NC}"
    rm -rf "$TARGET_DIR"

    echo -e "${YELLOW}>>> 正在清理自启配置、别名和菜单脚本...${NC}"
    sed -i "/# === ${AUTOSTART_TAG} ===/,/# ==========================/d" ~/.bashrc
    sed -i "/alias lx=/d" ~/.bashrc
    rm -f "$MENU_SCRIPT"

    echo -e "${GREEN}✅ 卸载完成！${NC}"
}

start_lxserver() {
    if check_running; then
        echo -e "${YELLOW}⚠️ 服务已经在运行中。${NC}"
        return
    fi
    termux-wake-lock 2>/dev/null || true
    cd "$TARGET_DIR" && nohup node index.js --app=node2 > "$LOG_FILE" 2>&1 &
    sleep 2
    if check_running; then
        echo -e "${GREEN}✅ 服务已启动，端口 9527。${NC}"
    else
        echo -e "${RED}❌ 启动失败，请查看日志。${NC}"
    fi
}

stop_lxserver() {
    if ! check_running; then
        echo -e "${YELLOW}⚠️ 服务没有在运行。${NC}"
        return
    fi
    pkill -f "node index.js --app=node2" 2>/dev/null
    termux-wake-unlock 2>/dev/null || true
    echo -e "${GREEN}✅ 服务已停止。${NC}"
}

restart_lxserver() {
    stop_lxserver
    sleep 1
    start_lxserver
}

view_logs() {
    echo -e "${CYAN}>>> 显示最近 50 行日志 (按 Ctrl+C 退出)${NC}"
    if [ -f "$LOG_FILE" ]; then
        tail -n 50 -f "$LOG_FILE"
    else
        echo -e "${RED}❌ 日志文件不存在。${NC}"
    fi
}

check_status() {
    echo -e "${CYAN}>>> 当前服务状态：${NC}"
    if check_running; then
        echo -e "${GREEN}✅ 运行中 (端口: 9527)${NC}"
        ps -ef | grep "node index.js" | grep -v grep
    else
        echo -e "${RED}❌ 未运行${NC}"
    fi
    echo ""
    echo -e "${CYAN}>>> 目录结构：${NC}"
    if [ -d "$TARGET_DIR" ]; then
        du -sh "$TARGET_DIR" 2>/dev/null
    else
        echo -e "${RED}lxserver 目录不存在${NC}"
    fi
}

show_menu() {
    clear
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}       🎵 LX Music Server 工具箱${NC}"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "  ${GREEN}[1]${NC} 安装 / 更新"
    echo -e "  ${GREEN}[2]${NC} 启动服务"
    echo -e "  ${GREEN}[3]${NC} 停止服务"
    echo -e "  ${GREEN}[4]${NC} 重启服务"
    echo -e "  ${GREEN}[5]${NC} 查看状态"
    echo -e "  ${GREEN}[6]${NC} 查看日志"
    echo -e "  ${GREEN}[7]${NC} 卸载服务"
    echo -e "  ${GREEN}[0]${NC} 退出"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}  💡 提示：以后重启手机后，打开 Termux 输入 lx 回车即可启动服务${NC}"
    echo -e "${CYAN}=========================================${NC}"
    read -p "请输入选项数字: " choice
    case $choice in
        1) install_lxserver ;;
        2) start_lxserver ;;
        3) stop_lxserver ;;
        4) restart_lxserver ;;
        5) check_status ;;
        6) view_logs ;;
        7) uninstall_lxserver ;;
        0) exit 0 ;;
        *) echo -e "${RED}❌ 无效选项，请重新输入。${NC}"; sleep 2 ;;
    esac
}

if [ "$1" == "install" ]; then
    install_lxserver
elif [ "$1" == "uninstall" ]; then
    uninstall_lxserver
elif [ "$1" == "start" ]; then
    start_lxserver
elif [ "$1" == "stop" ]; then
    stop_lxserver
else
    while true; do
        show_menu
        echo ""
        read -p "按回车键继续..." dummy
    done
fi
