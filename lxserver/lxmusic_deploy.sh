#!/bin/bash
# ============================================
#   LX Music Server 工具箱 (部署/卸载/管理/备份/恢复/自毁)
#   交互式菜单 | 自动获取最新版 | 智能防重复安装
# ============================================

GITHUB_REPO="XCQ0607/lxserver"
PROXY="https://proxy.lalifeier.eu.org/"
TARGET_DIR="$HOME/lxserver"
LOG_FILE="$TARGET_DIR/node.log"
AUTOSTART_TAG="lxserver_autostart"
API_URL="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
MENU_SCRIPT="$HOME/lx_menu.sh"
BACKUP_DIR="$HOME/lxserver_backup"

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

# ==================== 备份与恢复 ====================

backup_data() {
    echo -e "${CYAN}>>> 开始备份数据${NC}"
    mkdir -p "$BACKUP_DIR"
    local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    local BACKUP_FILE="$BACKUP_DIR/lxserver_backup_$TIMESTAMP.tar.gz"
    echo -e "${YELLOW}>>> 正在打包... (排除 node_modules 和日志)${NC}"
    tar --exclude='lxserver/node_modules' --exclude='lxserver/node.log' -czf "$BACKUP_FILE" -C "$HOME" lxserver 2>/dev/null
    if [ -f "$BACKUP_FILE" ]; then
        local SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo -e "${GREEN}✅ 备份成功！文件: ${BACKUP_FILE} (${SIZE})${NC}"
    else
        echo -e "${RED}❌ 备份失败，请检查磁盘空间。${NC}"
    fi
}

restore_data() {
    echo -e "${CYAN}>>> 可用的备份文件列表：${NC}"
    local backups=($(ls -t "$BACKUP_DIR"/lxserver_backup_*.tar.gz 2>/dev/null))
    if [ ${#backups[@]} -eq 0 ]; then echo -e "${RED}❌ 没有找到任何备份文件。${NC}"; return 1; fi
    for i in "${!backups[@]}"; do
        echo -e "  ${GREEN}[$((i+1))]${NC} $(basename "${backups[$i]}") ($(du -h "${backups[$i]}" | cut -f1))"
    done
    read -p "请输入要恢复的编号 (输入 0 取消): " choice
    if [ "$choice" == "0" ] || [ -z "$choice" ]; then echo -e "${YELLOW}已取消恢复。${NC}"; return; fi
    local selected_index=$((choice-1))
    if [ -z "${backups[$selected_index]}" ]; then echo -e "${RED}❌ 无效编号。${NC}"; return; fi
    local RESTORE_FILE="${backups[$selected_index]}"
    echo -e "${YELLOW}>>> 停止服务，还原数据...${NC}"
    pkill -f "node index.js --app=node2" 2>/dev/null || true
    sleep 1
    tar -xzf "$RESTORE_FILE" -C "$HOME"
    cd "$TARGET_DIR" && npm install --production > /dev/null 2>&1
    termux-wake-lock
    cd "$TARGET_DIR" && nohup node index.js --app=node2 > "$LOG_FILE" 2>&1 &
    sleep 3
    if check_running; then echo -e "${GREEN}✅ 恢复成功！服务运行在端口 9527。${NC}"; else echo -e "${RED}❌ 恢复后启动失败，请查看日志。${NC}"; fi
}

# ==================== 一键自毁 ====================

self_destruct() {
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}       ⚠️  警  告  ⚠️${NC}"
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}此操作将永久删除以下所有内容：${NC}"
    echo -e "${RED}  1. 洛雪音乐服务目录 (~/lxserver)${NC}"
    echo -e "${RED}  2. 所有数据备份 (~/lxserver_backup)${NC}"
    echo -e "${RED}  3. 交互式菜单脚本 (~/lx_menu.sh)${NC}"
    echo -e "${RED}  4. .bashrc 中的自启逻辑和 lx 别名${NC}"
    echo -e "${RED}  5. 已下载的部署压缩包${NC}"
    echo -e "${RED}  6. 当前部署脚本本身${NC}"
    echo -e "${RED}=========================================${NC}"
    echo ""
    read -p "如要彻底删除，请输入 YES (大写): " confirm1
    if [ "$confirm1" != "YES" ]; then echo -e "${YELLOW}已取消自毁。${NC}"; return; fi

    read -p "最后确认：请输入 DESTROY 执行彻底删除: " confirm2
    if [ "$confirm2" != "DESTROY" ]; then echo -e "${YELLOW}已取消自毁。${NC}"; return; fi

    echo ""
    echo -e "${RED}=========================================${NC}"
    echo -e "${RED}   自毁程序将在 15 秒后启动${NC}"
    echo -e "${YELLOW}   在此期间按 X 或 0 可立即取消${NC}"
    echo -e "${RED}=========================================${NC}"
    echo ""

    local cancelled=0
    for i in $(seq 15 -1 1); do
        printf "\r${RED}倒计时: %2d 秒  (按 X 或 0 取消)   ${NC}" "$i"
        if read -t 1 -n 1 key; then
            if [[ "$key" == "X" || "$key" == "x" || "$key" == "0" ]]; then
                echo ""
                echo ""
                echo -e "${GREEN}✅ 已取消自毁，所有文件完好无损。${NC}"
                cancelled=1
                break
            fi
        fi
    done

    if [ "$cancelled" == "1" ]; then
        return
    fi

    echo ""
    echo ""
    echo -e "${RED}>>> 倒计时结束，正在执行自毁...${NC}"
    echo -e "${YELLOW}>>> 正在停止服务...${NC}"
    pkill -f "node index.js --app=node2" 2>/dev/null || true
    termux-wake-unlock 2>/dev/null || true

    echo -e "${YELLOW}>>> 正在删除服务目录...${NC}"
    rm -rf "$TARGET_DIR"
    rm -rf "$HOME/lxserver_old_temp"

    echo -e "${YELLOW}>>> 正在删除备份目录...${NC}"
    rm -rf "$BACKUP_DIR"

    echo -e "${YELLOW}>>> 正在删除交互菜单...${NC}"
    rm -f "$MENU_SCRIPT"

    echo -e "${YELLOW}>>> 正在清理 .bashrc 配置...${NC}"
    sed -i "/# === ${AUTOSTART_TAG} ===/,/# ==========================/d" ~/.bashrc
    sed -i "/alias lx=/d" ~/.bashrc

    echo -e "${YELLOW}>>> 正在删除下载残留...${NC}"
    rm -f "$HOME"/lx-music-sync-server-*.zip
    rm -f "$HOME"/lxserver_v*.zip

    echo -e "${YELLOW}>>> 正在删除部署脚本自身...${NC}"
    if [ -f "$HOME/lxmusic_deploy.sh" ]; then
        rm -f "$HOME/lxmusic_deploy.sh"
    fi
    if [ -f "$0" ] && [[ "$0" != "/dev/"* ]] && [ "$0" != "bash" ]; then
        rm -f "$0" 2>/dev/null
    fi

    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}   ✅ 已全部清理干净，感谢使用！${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${CYAN}现在你可以安心关闭 Termux 了。${NC}"
    exit 0
}

# ==================== 部署与配置 ====================

setup_autostart() {
    sed -i "/# === ${AUTOSTART_TAG} ===/,/# ==========================/d" ~/.bashrc
    cat << EOF >> ~/.bashrc

# === ${AUTOSTART_TAG} ===
if ! pgrep -f "node index.js --app=node2" > /dev/null; then
    echo ""
    echo ">>> [自启] 检测到洛雪服务未运行，正在进入管理菜单..."
    echo ""
    bash ~/lx_menu.sh
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
echo "  [8] 备份数据"
echo "  [9] 恢复数据"
echo "  [10] 一键自毁 (删除所有文件与配置)"
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
    1) bash <(curl -sL "https://proxy.lalifeier.eu.org/https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lxserver/lxmusic_deploy.sh") install ;;
    2) 
        if pgrep -f "node index.js --app=node2" > /dev/null; then echo "⚠️ 服务已经在运行中。"
        else
            termux-wake-lock
            cd ~/lxserver && nohup node index.js --app=node2 > ~/lxserver/node.log 2>&1 &
            sleep 2; echo "✅ 服务已启动，端口 9527。"
        fi ;;
    3) pkill -f "node index.js --app=node2" 2>/dev/null; termux-wake-unlock 2>/dev/null; echo "✅ 服务已停止。" ;;
    4) pkill -f "node index.js --app=node2" 2>/dev/null; sleep 1; termux-wake-lock; cd ~/lxserver && nohup node index.js --app=node2 > ~/lxserver/node.log 2>&1 & sleep 2; echo "✅ 服务已重启，端口 9527。" ;;
    5) if pgrep -f "node index.js --app=node2" > /dev/null; then echo "✅ 运行中 (端口: 9527)"; ps -ef | grep "node index.js" | grep -v grep; else echo "❌ 未运行"; fi; echo ""; echo ">>> 目录占用:"; du -sh ~/lxserver 2>/dev/null ;;
    6) echo ">>> 显示最近 50 行日志 (按 Ctrl+C 退出)"; tail -n 50 -f ~/lxserver/node.log ;;
    7) read -p "确定要卸载吗？此操作会删除所有数据，请输入 'yes' 确认: " confirm
        if [ "$confirm" == "yes" ]; then
            pkill -f "node index.js --app=node2" 2>/dev/null
            rm -rf ~/lxserver
            sed -i "/# === lxserver_autostart ===/,/# ==========================/d" ~/.bashrc
            sed -i "/alias lx=/d" ~/.bashrc
            rm -f ~/lx_menu.sh
            echo "✅ 卸载完成！备份保留在 ~/lxserver_backup/"
            exit 0
        else echo "已取消卸载。"; fi ;;
    8) mkdir -p "$HOME/lxserver_backup"; TIMESTAMP=$(date +%Y%m%d_%H%M%S); BACKUP_FILE="$HOME/lxserver_backup/lxserver_backup_$TIMESTAMP.tar.gz"; echo ">>> 正在打包备份..."; tar --exclude='lxserver/node_modules' --exclude='lxserver/node.log' -czf "$BACKUP_FILE" -C "$HOME" lxserver 2>/dev/null
        if [ -f "$BACKUP_FILE" ]; then echo "✅ 备份成功！文件：$BACKUP_FILE"; du -h "$BACKUP_FILE"; else echo "❌ 备份失败，请检查存储空间。"; fi ;;
    9) backups=($(ls -t "$HOME/lxserver_backup"/lxserver_backup_*.tar.gz 2>/dev/null))
        if [ ${#backups[@]} -eq 0 ]; then echo "❌ 没有找到备份文件。"
        else
            echo ">>> 请选择要恢复的备份："
            for i in "${!backups[@]}"; do echo "  [$((i+1))] $(basename ${backups[$i]})"; done
            read -p "输入编号 (0 取消): " ridx
            if [ "$ridx" != "0" ] && [ -n "$ridx" ] && [ -n "${backups[$((ridx-1))]}" ]; then
                pkill -f "node index.js --app=node2" 2>/dev/null; sleep 1
                echo ">>> 正在还原..."; tar -xzf "${backups[$((ridx-1))]}" -C "$HOME"
                cd ~/lxserver && npm install --production > /dev/null 2>&1
                termux-wake-lock; cd ~/lxserver && nohup node index.js --app=node2 > ~/lxserver/node.log 2>&1 & sleep 3
                echo "✅ 恢复完成！服务已启动。"
            else echo "已取消恢复。"; fi
        fi ;;
    10) echo "⚠️  危险操作：一键自毁将删除所有文件和配置！"
        read -p "输入 YES 确认: " c1
        if [ "$c1" != "YES" ]; then echo "已取消。"; break; fi
        read -p "再次输入 DESTROY 执行彻底删除: " c2
        if [ "$c2" != "DESTROY" ]; then echo "已取消。"; break; fi
        echo ""
        echo "========================================="
        echo "   自毁程序将在 15 秒后启动"
        echo "   在此期间按 X 或 0 可立即取消"
        echo "========================================="
        echo ""
        cxl=0
        for i in $(seq 15 -1 1); do
            printf "\r倒计时: %2d 秒  (按 X 或 0 取消)   " "$i"
            if read -t 1 -n 1 key; then
                if [[ "$key" == "X" || "$key" == "x" || "$key" == "0" ]]; then
                    echo ""; echo ""; echo "✅ 已取消自毁，所有文件完好无损。"; cxl=1; break
                fi
            fi
        done
        if [ "$cxl" == "1" ]; then break; fi
        echo ""; echo ""
        echo ">>> 倒计时结束，正在执行自毁..."
        pkill -f "node index.js --app=node2" 2>/dev/null
        termux-wake-unlock 2>/dev/null
        rm -rf ~/lxserver ~/lxserver_backup ~/lxserver_old_temp ~/lx_menu.sh
        sed -i "/# === lxserver_autostart ===/,/# ==========================/d" ~/.bashrc
        sed -i "/alias lx=/d" ~/.bashrc
        rm -f ~/lx-music-sync-server-*.zip ~/lxserver_v*.zip
        echo "✅ 已全部清理干净，感谢使用！"; exit 0 ;;
    0) exit 0 ;;
    *) echo "⏰ 无效输入，自动启动服务..."
        if ! pgrep -f "node index.js --app=node2" > /dev/null; then
            termux-wake-lock; cd ~/lxserver && nohup node index.js --app=node2 > ~/lxserver/node.log 2>&1 & sleep 2
            echo "✅ 服务已自动启动，端口 9527。"
        else echo "✅ 服务已经在运行中。"; fi ;;
esac
MENU_EOF

    chmod +x "$MENU_SCRIPT"
    sed -i "/alias lx=/d" ~/.bashrc
    echo "alias lx='bash ~/lx_menu.sh'" >> ~/.bashrc
    echo -e "${GREEN}    [✔] 已生成 lx 菜单脚本和别名${NC}"
}

install_lxserver() {
    echo -e "${CYAN}>>> 开始安装/更新 LX Music Server${NC}"
    termux-wake-lock 2>/dev/null || true
    echo -e "${YELLOW}>>> 正在安装基础依赖...${NC}"
    pkg update -y > /dev/null 2>&1
    pkg install wget unzip nodejs -y > /dev/null 2>&1
    echo -e "${YELLOW}>>> 正在查询最新版本...${NC}"
    local LATEST_TAG=$(get_latest_version)
    if [ -z "$LATEST_TAG" ]; then echo -e "${RED}❌ 获取版本号失败，请检查网络或代理。${NC}"; termux-wake-unlock 2>/dev/null; return 1; fi
    local LOCAL_VER=$(get_local_version)
    local clean_local=$(echo "$LOCAL_VER" | sed 's/^v//')
    local clean_latest=$(echo "$LATEST_TAG" | sed 's/^v//')
    if [ "$clean_local" == "$clean_latest" ] && [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}⚠️ 已是最新版: $LOCAL_VER，跳过下载，检查自启和别名...${NC}"
        setup_alias; setup_autostart; termux-wake-unlock 2>/dev/null || true; return 0
    fi
    echo -e "${GREEN}    [✔] 最新版本: ${LATEST_TAG}${NC}"
    local ZIP_NAME="lx-music-sync-server-${LATEST_TAG}-server.zip"
    local DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${LATEST_TAG}/${ZIP_NAME}"
    local ZIP_FILE="$HOME/${ZIP_NAME}"
    echo -e "${YELLOW}>>> 正在下载...${NC}"
    if ! wget -q --timeout=30 -O "$ZIP_FILE" "${PROXY}${DOWNLOAD_URL}"; then
        echo -e "${YELLOW}    [!] 加速失败，尝试直连...${NC}"
        if ! wget -q --timeout=60 -O "$ZIP_FILE" "$DOWNLOAD_URL"; then
            echo -e "${RED}❌ 下载失败，请检查网络。${NC}"; termux-wake-unlock 2>/dev/null; return 1
        fi
    fi
    echo -e "${YELLOW}>>> 正在解压...${NC}"
    rm -rf "$HOME/lxserver_temp"; mkdir -p "$HOME/lxserver_temp"
    unzip -o "$ZIP_FILE" -d "$HOME/lxserver_temp" > /dev/null 2>&1
    local PROJECT_DIR=$(find "$HOME/lxserver_temp" -name "package.json" -maxdepth 2 -exec dirname {} \; | head -n 1)
    if [ -z "$PROJECT_DIR" ]; then echo -e "${RED}❌ 解压失败${NC}"; termux-wake-unlock 2>/dev/null; return 1; fi
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${YELLOW}    [!] 备份旧版本到 ~/lxserver_old_temp ...${NC}"
        rm -rf "$HOME/lxserver_old_temp"; mv "$TARGET_DIR" "$HOME/lxserver_old_temp"
    fi
    mv "$PROJECT_DIR" "$TARGET_DIR"; rm -rf "$HOME/lxserver_temp"
    echo -e "${YELLOW}>>> 正在安装依赖 (耐心等待)...${NC}"
    cd "$TARGET_DIR" && npm install --production > /dev/null 2>&1
    setup_alias; setup_autostart
    echo -e "${YELLOW}>>> 正在启动服务...${NC}"
    pkill -f "node index.js --app=node2" 2>/dev/null || true
    cd "$TARGET_DIR" && nohup node index.js --app=node2 > "$LOG_FILE" 2>&1 &
    sleep 4
    if grep -q "Error" "$LOG_FILE"; then
        echo -e "${RED}❌ 启动失败，日志如下：${NC}"; cat "$LOG_FILE"
    else
        echo -e "${GREEN}✅ 部署启动成功！服务运行在端口 9527。${NC}"
    fi
    termux-wake-unlock 2>/dev/null || true
}

uninstall_lxserver() {
    echo -e "${RED}>>> 确定要卸载 LX Music Server 吗？${NC}"
    read -p "此操作会删除所有数据，请输入 'yes' 确认: " confirm
    if [ "$confirm" != "yes" ]; then echo -e "${YELLOW}已取消卸载。${NC}"; return; fi
    pkill -f "node index.js --app=node2" 2>/dev/null || true
    rm -rf "$TARGET_DIR"
    sed -i "/# === ${AUTOSTART_TAG} ===/,/# ==========================/d" ~/.bashrc
    sed -i "/alias lx=/d" ~/.bashrc
    rm -f "$MENU_SCRIPT"
    echo -e "${GREEN}✅ 卸载完成！备份保留在 ~/lxserver_backup/${NC}"
}

start_lxserver() {
    if check_running; then echo -e "${YELLOW}⚠️ 服务已经在运行中。${NC}"; return; fi
    termux-wake-lock 2>/dev/null || true
    cd "$TARGET_DIR" && nohup node index.js --app=node2 > "$LOG_FILE" 2>&1 &
    sleep 2
    if check_running; then echo -e "${GREEN}✅ 服务已启动，端口 9527。${NC}"; else echo -e "${RED}❌ 启动失败，请查看日志。${NC}"; fi
}

stop_lxserver() {
    if ! check_running; then echo -e "${YELLOW}⚠️ 服务没有在运行。${NC}"; return; fi
    pkill -f "node index.js --app=node2" 2>/dev/null
    termux-wake-unlock 2>/dev/null || true
    echo -e "${GREEN}✅ 服务已停止。${NC}"
}

restart_lxserver() { stop_lxserver; sleep 1; start_lxserver; }

view_logs() {
    echo -e "${CYAN}>>> 显示最近 50 行日志 (按 Ctrl+C 退出)${NC}"
    if [ -f "$LOG_FILE" ]; then tail -n 50 -f "$LOG_FILE"; else echo -e "${RED}❌ 日志文件不存在。${NC}"; fi
}

check_status() {
    echo -e "${CYAN}>>> 当前服务状态：${NC}"
    if check_running; then echo -e "${GREEN}✅ 运行中 (端口: 9527)${NC}"; ps -ef | grep "node index.js" | grep -v grep
    else echo -e "${RED}❌ 未运行${NC}"; fi
    echo ""
    echo -e "${CYAN}>>> 目录结构：${NC}"
    if [ -d "$TARGET_DIR" ]; then du -sh "$TARGET_DIR" 2>/dev/null; else echo -e "${RED}lxserver 目录不存在${NC}"; fi
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
    echo -e "  ${GREEN}[8]${NC} 备份数据"
    echo -e "  ${GREEN}[9]${NC} 恢复数据"
    echo -e "  ${RED}[10]${NC} 一键自毁 (删除所有文件与配置)"
    echo -e "  ${GREEN}[0]${NC} 退出"
    echo -e "${CYAN}=========================================${NC}"
    echo -e "${CYAN}  💡 提示：以后重启手机后，打开 Termux 输入 lx 回车即可进入菜单${NC}"
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
        8) backup_data ;;
        9) restore_data ;;
        10) self_destruct ;;
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
