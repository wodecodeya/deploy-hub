#!/bin/bash
# ============================================================
# LZ 服务管理控制台 - 一键安装脚本
# ============================================================

set -e

echo ">>> 正在下载 LZ 主脚本..."
curl -fsSL "https://proxy.lalifeier.eu.org/https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh" -o ~/lz-menu.sh

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
