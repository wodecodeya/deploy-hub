#!/bin/bash
# ============================================================
# LZ 服务管理控制台 - 一键安装脚本 (wget 专版)
# ============================================================

echo ">>> 正在检查 wget 依赖..."
if ! command -v wget &> /dev/null; then
    echo "[安装] wget 不存在，正在自动安装..."
    pkg install wget -y > /dev/null 2>&1
fi

echo ">>> 正在下载 LZ 主脚本..."
# 尝试直连下载，如果失败会自动重试5次，每次超时15秒
wget -t 5 -T 15 -qO ~/lz-menu.sh "https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh"

# 如果直连失败，尝试代理下载
if [ $? -ne 0 ]; then
    echo ">>> 直连失败，正在切换代理..."
    wget -t 5 -T 15 -qO ~/lz-menu.sh "https://tvv.tw/raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh"
fi

# 检查文件是否下载成功
if [ ! -s ~/lz-menu.sh ]; then
    echo ">>> [失败] 下载失败，请检查网络。"
    exit 1
fi

echo ">>> 正在授权并创建 lz 快捷命令..."
chmod +x ~/lz-menu.sh
ln -sf ~/lz-menu.sh $PREFIX/bin/lz

echo ">>> 正在配置开机自启动..."
sed -i '/LZ_MENU_STARTED/d' ~/.bashrc 2>/dev/null
sed -i '/lz-menu.sh/d' ~/.bashrc 2>/dev/null
printf '\n# LZ 服务管理控制台自动启动\nif [ -n "$PS1" ] && [ -z "$LZ_MENU_STARTED" ]; then\n    export LZ_MENU_STARTED=1\n    bash ~/lz-menu.sh --boot\nfi\n' >> ~/.bashrc

echo ""
echo "========================================="
echo "✅ 部署完成！"
echo "   输入 lz 测试"
echo "========================================="
