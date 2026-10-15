#!/bin/bash
# ============================================================
# LZ 服务管理控制台 v2.1 (合并 start.sh + 菜单 + GitHub更新)
# ============================================================

# >>> 部署后改成你自己的 GitHub 地址 <<<
GITHUB_URL="https://raw.githubusercontent.com/你的用户名/你的仓库/main/lz.sh"

termux-wake-lock
LOGDIR=/storage/emulated/0/lz/logs
mkdir -p "$LOGDIR"

SERVICES=(
"1|ttyd 终端|7681|ttyd|ttyd.log|cd /storage/emulated/0/lz/ && nohup ttyd -p 7681 bash > $LOGDIR/ttyd.log 2>&1 &"
"2|简单音乐|5566|music_api-main|node1.log|cd ~/music_api-main && nohup node index.js > $LOGDIR/node1.log 2>&1 &"
"3|洛雪音乐|9527|lxserver|node.log|cd ~/lxserver && nohup node index.js --app=node2 > $LOGDIR/node.log 2>&1 &"
"4|PHP Web|8088|php|php.log|cd /storage/emulated/0/lz/ && nohup php -S 0.0.0.0:8088 -t ./www > $LOGDIR/php.log 2>&1 &"
"5|短剧聚合|8998|juku|juku.log|cd /storage/emulated/0/lz/ && nohup ~/juku -lan > $LOGDIR/juku.log 2>&1 &"
"6|听书聚合|8999|duoju-ting-android|duoju-ting.log|cd /storage/emulated/0/lz/ && nohup ~/duoju-ting-android -lan > $LOGDIR/duoju-ting.log 2>&1 &"
"7|本地包go|1988|yt001|yt001.log|cd /storage/emulated/0/lz/ && nohup ~/yt001 > $LOGDIR/yt001.log 2>&1 &"
"8|央视频直播|8767|ysp-live-v8.1.py|ysp-live-v8.1.py.log|cd /storage/emulated/0/lz/py/ && nohup python /sdcard/lz/py/ysp-live-v8.1.py > $LOGDIR/ysp-live-v8.1.py.log 2>&1 &"
"9|Mihomo 代理|9090|mihomo/mihomo|mihomo.log|cd /storage/emulated/0/lz/mihomo && nohup ~/mihomo/mihomo -d . > $LOGDIR/mihomo.log 2>&1 &"
"10|管理控制台|8081|manage.py|manage.log|cd /storage/emulated/0/lz/ && nohup python manage.py > $LOGDIR/manage.log 2>&1 &"
"11|多聚漫画|8992|duoju-manhua-android|duoju-manhua.log|cd /storage/emulated/0/lz/ && nohup ~/duoju-manhua-android -port 8992 -bind 127.0.0.1 > $LOGDIR/duoju-manhua.log 2>&1 &"
)

check_port() {
    python3 -c "import socket; s=socket.socket(); s.settimeout(0.5); exit(0 if s.connect_ex(('127.0.0.1',$1))==0 else 1)" 2>/dev/null
}

get_service() {
    local id=$1
    for svc in "${SERVICES[@]}"; do
        IFS='|' read -r sid _ _ _ _ _ <<< "$svc"
        [ "$sid" == "$id" ] && { echo "$svc"; return 0; }
    done
    return 1
}

show_status() {
    for svc in "${SERVICES[@]}"; do
        IFS='|' read -r sid sname sport spattern slog scmd <<< "$svc"
        if check_port "$sport"; then
            printf "  [%-2s] %-16s %-6s \033[32m[运行中]\033[0m\n" "$sid" "$sname" "$sport"
        else
            printf "  [%-2s] %-16s %-6s \033[31m[未运行]\033[0m\n" "$sid" "$sname" "$sport"
        fi
    done
}

start_service() {
    local id=$1
    local svc=$(get_service "$id")
    [ -z "$svc" ] && { echo "[错误] 无效编号: $id"; return 1; }
    IFS='|' read -r sid sname sport spattern slog scmd <<< "$svc"
    if check_port "$sport"; then
        echo "[跳过] $sname 已在运行 (端口 $sport)"
        return 0
    fi
    eval "$scmd"
    sleep 1
    if check_port "$sport"; then
        echo "[✔ 成功] $sname 已启动 (端口 $sport)"
    else
        echo "[✘ 失败] $sname 启动失败 (端口 $sport)"
    fi
}

stop_service() {
    local id=$1
    local svc=$(get_service "$id")
    [ -z "$svc" ] && { echo "[错误] 无效编号: $id"; return 1; }
    IFS='|' read -r sid sname sport spattern slog scmd <<< "$svc"
    if ! check_port "$sport"; then
        echo "[跳过] $sname 未在运行 (端口 $sport)"
        return 0
    fi
    fuser -k -n tcp "$sport" 2>/dev/null
    sleep 1
    if ! check_port "$sport"; then
        echo "[✔ 成功] $sname 已停止"
    else
        pkill -9 -f "$spattern" 2>/dev/null
        sleep 1
        if ! check_port "$sport"; then
            echo "[✔ 成功] $sname 已停止 (pkill)"
        else
            echo "[✘ 失败] $sname 停止失败 (端口 $sport)"
        fi
    fi
}

start_all_quick() {
    echo ">>> 快速启动：仅补启动未运行的服务..."
    for svc in "${SERVICES[@]}"; do
        IFS='|' read -r sid _ _ _ _ _ <<< "$svc"
        start_service "$sid"
    done
}

stop_all() {
    for svc in "${SERVICES[@]}"; do
        IFS='|' read -r sid _ _ _ _ _ <<< "$svc"
        stop_service "$sid"
    done
}

start_all_full() {
    echo ">>> 正在执行完整启动流程..."
    check_install() {
        local pkg_name=$1
        local cmd_name=$2
        if ! command -v $cmd_name &> /dev/null; then
            echo "[安装] $pkg_name 不存在，正在自动安装..."
            pkg install $pkg_name -y > /dev/null 2>&1
            echo "[成功] $pkg_name 安装完成。"
        fi
    }
    check_install "php" "php"
    check_install "nodejs" "node"
    check_install "python" "python"
    check_install "golang" "go"
    check_install "ttyd" "ttyd"
    check_install "psmisc" "killall"
    check_install "net-tools" "netstat"
    check_install "proot-distro" "proot-distro"

    if [ -d ~/lxserver/cache ] && [ ! -L ~/lxserver/cache ]; then
        mkdir -p /storage/emulated/0/lz/lx_cache
        cp -rn ~/lxserver/cache/* /storage/emulated/0/lz/lx_cache/ 2>/dev/null
        rm -rf ~/lxserver/cache
        ln -s /storage/emulated/0/lz/lx_cache ~/lxserver/cache
    fi

    mkdir -p /storage/emulated/0/lz/lx_source/admin
    SRC_LINK="$HOME/lxserver/data/users/source"
    if [ -L "$SRC_LINK" ] && [ ! -d "$SRC_LINK" ]; then
        rm -f "$SRC_LINK"; ln -s /storage/emulated/0/lz/lx_source "$SRC_LINK"
    elif [ -d "$SRC_LINK" ] && [ ! -L "$SRC_LINK" ]; then
        cp -rn "$SRC_LINK"/* /storage/emulated/0/lz/lx_source/ 2>/dev/null
        rm -rf "$SRC_LINK"; ln -s /storage/emulated/0/lz/lx_source "$SRC_LINK"
    elif [ ! -e "$SRC_LINK" ]; then
        mkdir -p "$(dirname "$SRC_LINK")"; ln -s /storage/emulated/0/lz/lx_source "$SRC_LINK"
    fi

    [ ! -f ~/juku ] && cp /storage/emulated/0/lz/juku ~/ && chmod +x ~/juku
    [ ! -f ~/duoju-ting-android ] && cp /storage/emulated/0/lz/duoju-ting-android ~/ && chmod +x ~/duoju-ting-android
    [ ! -f ~/duoju-manhua-android ] && cp /storage/emulated/0/lz/duoju-manhua-android ~/ && chmod +x ~/duoju-manhua-android
    [ ! -f ~/yt001 ] && cp /storage/emulated/0/lz/yt001 ~/ && chmod +x ~/yt001
    if [ ! -f ~/mihomo/mihomo ]; then
        mkdir -p ~/mihomo
        cp /storage/emulated/0/lz/mihomo/mihomo ~/mihomo/ && chmod +x ~/mihomo/mihomo
    fi

    killall -9 ttyd 2>/dev/null
    killall -9 node 2>/dev/null
    killall -9 php 2>/dev/null
    killall -9 python 2>/dev/null
    killall -9 juku 2>/dev/null
    killall -9 duoju-ting-android 2>/dev/null
    killall -9 duoju-manhua-android 2>/dev/null
    killall -9 yt001 2>/dev/null
    killall -9 mihomo 2>/dev/null
    pkill -f manage.py 2>/dev/null
    sleep 1

    for svc in "${SERVICES[@]}"; do
        IFS='|' read -r sid _ _ _ _ _ <<< "$svc"
        start_service "$sid"
    done
    echo ">>> 完整启动流程执行完毕。"
}

start_specific() { read -p "输入要启动的编号(空格分隔): " nums; for n in $nums; do start_service "$n"; done; }
stop_specific() { read -p "输入要停止的编号(空格分隔): " nums; for n in $nums; do stop_service "$n"; done; }
restart_specific() { read -p "输入要重启的编号(空格分隔): " nums; for n in $nums; do stop_service "$n"; done; sleep 1; for n in $nums; do start_service "$n"; done; }

view_log() {
    read -p "输入要查看日志的编号 (1-11): " vid
    local svc=$(get_service "$vid")
    [ -z "$svc" ] && { echo "无效编号"; sleep 1; return; }
    IFS='|' read -r sid sname sport spattern slog scmd <<< "$svc"
    local logfile="$LOGDIR/$slog"
    [ ! -f "$logfile" ] && { echo "日志不存在: $logfile"; sleep 2; return; }
    echo "========= $sname 日志 ($slog) ========="
    echo "按 Ctrl+C 返回菜单"
    sleep 1
    tail -f "$logfile"
    echo ""
    read -p "按回车返回菜单..."
}

clear_logs() {
    read -p "确认清空全部日志? (y/N): " c
    [[ "$c" == "y" || "$c" == "Y" ]] && rm -f "$LOGDIR"/*.log && echo "[完成] 日志已清空" || echo "[取消]"
}

fix_links() {
    echo ">>> 正在修复软链接..."
    mkdir -p /storage/emulated/0/lz/lx_cache /storage/emulated/0/lz/lx_source/admin
    if [ -d ~/lxserver/cache ] && [ ! -L ~/lxserver/cache ]; then
        cp -rn ~/lxserver/cache/* /storage/emulated/0/lz/lx_cache/ 2>/dev/null
        rm -rf ~/lxserver/cache; ln -s /storage/emulated/0/lz/lx_cache ~/lxserver/cache
    fi
    local SRC_LINK="$HOME/lxserver/data/users/source"
    if [ -L "$SRC_LINK" ] && [ ! -d "$SRC_LINK" ]; then
        rm -f "$SRC_LINK"; ln -s /storage/emulated/0/lz/lx_source "$SRC_LINK"
    elif [ -d "$SRC_LINK" ] && [ ! -L "$SRC_LINK" ]; then
        cp -rn "$SRC_LINK"/* /storage/emulated/0/lz/lx_source/ 2>/dev/null
        rm -rf "$SRC_LINK"; ln -s /storage/emulated/0/lz/lx_source "$SRC_LINK"
    elif [ ! -e "$SRC_LINK" ]; then
        mkdir -p "$(dirname "$SRC_LINK")"; ln -s /storage/emulated/0/lz/lx_source "$SRC_LINK"
    fi
    echo "[完成]"
}

sync_bins() {
    echo ">>> 正在重新同步二进制到私有目录..."
    cp -f /storage/emulated/0/lz/juku ~/ && chmod +x ~/juku && echo "[同步] juku"
    cp -f /storage/emulated/0/lz/duoju-ting-android ~/ && chmod +x ~/duoju-ting-android && echo "[同步] duoju-ting-android"
    cp -f /storage/emulated/0/lz/duoju-manhua-android ~/ && chmod +x ~/duoju-manhua-android && echo "[同步] duoju-manhua-android"
    cp -f /storage/emulated/0/lz/yt001 ~/ && chmod +x ~/yt001 && echo "[同步] yt001"
    mkdir -p ~/mihomo
    cp -f /storage/emulated/0/lz/mihomo/mihomo ~/mihomo/mihomo && chmod +x ~/mihomo/mihomo && echo "[同步] mihomo"
    echo "[完成]"
}

# ============ GitHub 更新 ============
update_script() {
    echo ">>> 当前来源: $GITHUB_URL"
    echo ">>> 正在从 GitHub 拉取最新脚本..."
    local tmpfile="/tmp/lz-menu-new.sh"
    if curl -fsSL "$GITHUB_URL" -o "$tmpfile"; then
        if [ -s "$tmpfile" ] && head -1 "$tmpfile" | grep -q "^#!/bin/bash"; then
            cp ~/lz-menu.sh ~/lz-menu.sh.bak
            mv "$tmpfile" ~/lz-menu.sh
            chmod +x ~/lz-menu.sh
            ln -sf ~/lz-menu.sh $PREFIX/bin/lz
            echo "[✔ 成功] 脚本已更新，旧版备份: ~/lz-menu.sh.bak"
            echo "         下次重进菜单或重敲 lz 生效。"
        else
            echo "[✘ 失败] 下载内容异常，未覆盖。"
            rm -f "$tmpfile"
        fi
    else
        echo "[✘ 失败] 无法连接 GitHub，请检查网络或代理。"
    fi
    read -p "按回车返回菜单..."
}

# ============ 菜单 ============
show_menu_header() {
    echo "========================================="
    echo "        LZ 服务管理控制台 v2.1"
    echo "========================================="
    echo "  当前状态:"
    show_status
    echo "========================================="
    echo "  A. 启动全部(快速)     B. 停止全部"
    echo "  C. 重启全部           D. 启动单个"
    echo "  E. 停止单个           F. 重启单个"
    echo "  G. 查看日志           H. 清空日志"
    echo "  I. 修复软链接         J. 同步二进制"
    echo "  K. 完整启动(全套自检) R. 刷新状态"
    echo "  U. 更新脚本(GitHub)   Q. 退出菜单"
    echo "========================================="
}

handle_choice() {
    case "$1" in
        A|a) start_all_quick; return 0;;
        B|b) stop_all; return 0;;
        C|c) stop_all; sleep 1; start_all_quick; return 0;;
        D|d) start_specific; return 0;;
        E|e) stop_specific; return 0;;
        F|f) restart_specific; return 0;;
        G|g) view_log; return 0;;
        H|h) clear_logs; return 0;;
        I|i) fix_links; return 0;;
        J|j) sync_bins; return 0;;
        K|k) start_all_full; return 0;;
        U|u) update_script; return 0;;
        Q|q) exit 0;;
        *) return 1;;
    esac
}

# ============ 主入口 ============
if [ "$1" == "--boot" ]; then
    clear
    show_menu_header
    echo ""
    echo "  ⏰ 15 秒后自动完整启动全部服务..."
    echo "     直接输入选项即可跳过自动启动"
    echo ""
    read -t 15 -p ">>> 15 秒内选择 [回车=立即完整启动]: " CHOICE
    echo ""
    if [ -z "$CHOICE" ]; then
        echo ">>> 未做选择，自动完整启动全部服务..."
        start_all_full
        read -p "按回车进入菜单..."
    else
        handle_choice "$CHOICE"
    fi
fi

while true; do
    clear
    show_menu_header
    read -p ">>> 请选择: " CHOICE
    [ "$CHOICE" == "R" ] || [ "$CHOICE" == "r" ] && continue
    if ! handle_choice "$CHOICE"; then
        echo "无效输入"
        sleep 1
        continue
    fi
    read -p "按回车返回菜单..."
done
