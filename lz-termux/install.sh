#!/bin/bash
set -e

URLS=(
    "https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh"
    "https://tvv.tw/raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh"
    "https://proxy.lalifeier.eu.org/https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh"
)

echo ">>> 正在下载 LZ 主脚本..."
SUCCESS=0
for url in "${URLS[@]}"; do
    echo "    尝试: $url"
    if curl -fsSL --connect-timeout 10 "$url" -o ~/lz-menu.sh; then
        SUCCESS=1
        echo "    [✔] 下载成功"
        break
    else
        echo "    [✘] 该节点失败，换下一个..."
    fi
done

if [ "$SUCCESS" -eq 0 ]; then
    echo ">>> [失败] 所有节点都无法连接，请检查网络。"
    exit 1
fi

# 后面的授权、自启动逻辑保持不变
chmod +x ~/lz-menu.sh
ln -sf ~/lz-menu.sh $PREFIX/bin/lz
sed -i '/LZ_MENU_STARTED/d' ~/.bashrc 2>/dev/null || true
sed -i '/lz-menu.sh/d' ~/.bashrc 2>/dev/null || true
printf '\n# LZ 服务管理控制台自动启动\nif [ -n "$PS1" ] && [ -z "$LZ_MENU_STARTED" ]; then\n    export LZ_MENU_STARTED=1\n    bash ~/lz-menu.sh --boot\nfi\n' >> ~/.bashrc

echo "✅ 部署完成！输入 lz 即可测试。"
