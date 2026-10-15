# LZ 服务管理控制台 (Termux)

专为 Termux 打造的多服务一键启动与可视化管理面板。内置多节点容灾、双下载引擎、开机自启，开箱即用。

## ✨ 核心功能

- **开机自动弹菜单**：重启 App 后自动进入面板，15 秒无操作自动全量启动所有服务。
- **一键管理**：快速启动（仅补未运行）、停止全部、重启全部。
- **单服务操作**：可单独启动、停止、重启指定编号的服务。
- **实时状态**：菜单顶部实时显示所有服务的端口运行状态（绿色运行中 / 红色未运行）。
- **日志中心**：内置日志查看（`tail -f` 实时刷新）和一键清空日志。
- **环境自检**：完整启动时自动检查并安装缺失依赖（PHP、Node.js、Python、Go、ttyd 等）。
- **数据保护**：自动修复洛雪音乐缓存/音源软链接，自动桥接二进制文件到私有目录，防止安卓权限问题。
- **双下载引擎**：本地更新时，自动检测 `curl` 或 `wget`，哪个能用用哪个，互为备份。
- **多节点容灾**：内置多个公共代理节点，原站超时自动切换备用节点，彻底解决网络波动问题。

## 🚀 一键部署（Termux 终端直接执行）

**推荐使用 `curl` 版本（Termux 默认自带，能显示进度条，慢点不怕）：**

复制下面这整段命令到 Termux 回车，全自动完成（下载、授权、建立 `lz` 快捷命令、开机自启）：

```bash
curl -L --progress-bar "https://tvv.tw/raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/install.sh" -o ~/install.sh && bash ~/install.sh && rm -f ~/install.sh
```

> **说明**：这条命令会先显示下载进度，下载完后自动执行安装逻辑，最后删除临时安装文件。哪怕它慢慢下 3 分钟，你也能在屏幕上看到进度条，不会以为它卡死了。

**备用方案（使用 `wget`，需先安装它）：**

```bash
(command -v wget >/dev/null || pkg install wget -y) && wget --progress=bar:force --tries=3 "https://tvv.tw/raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/install.sh" -O ~/install.sh && bash ~/install.sh && rm -f ~/install.sh
```

部署完成后：
- 重启 App → 自动进入控制台（15 秒倒计时）
- 任意终端输入 `lz` → 秒进菜单
- 在菜单按 `U` → 自动尝试多个公共代理节点拉取更新

## 🎮 使用说明

- **首次打开**：终端出现菜单，底部有 15 秒倒计时。
  - 等待 15 秒无操作 -> 自动执行完整启动。
  - 按任意键 -> 进入主菜单，不再自动启动。
- **手动呼出**：在任何终端输入 `lz` 回车，秒进菜单。
- **常用操作**：
  - 按 `A`：快速启动（只补未运行的服务，最快）。
  - 按 `K`：完整启动（全套自检 + 全量重启）。
  - 按 `U`：从 GitHub 拉取最新脚本（带多节点容灾 + 重试 + 进度条）。
  - 按 `Q`：退出菜单，回到普通终端。

## ⚠️ 注意事项

1. **需要存储权限**：首次使用需确保 Termux 已获取存储权限（`termux-setup-storage`）。
2. **防休眠**：脚本会自动执行 `termux-wake-lock`，防止系统休眠导致服务掉线。
3. **代理说明**：内置多个公共代理（`tvv.tw`、`lalifeier` 等），网络波动时会自动按顺序尝试，请耐心等待进度条。
4. **兼容性**：仅支持 Termux 安卓环境，需要 `bash` 运行（不要用 `sh` 执行脚本）。

## 📄 License

MIT
```

---

### 3. 更新 `install.sh` 里的下载逻辑（让安装过程可见）

找到 `install.sh` 里的下载部分，确保使用的是 `--progress-bar`，并且加上了重试。修改后如下：

```bash
#!/bin/bash
set -e

GITHUB_URL="https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh"
PROXY_URL="https://tvv.tw/$GITHUB_URL"

echo ">>> 正在下载 LZ 主脚本..."

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
```

### 💡 总结一下变化：
1. **下载必有进度条**：去掉了 `-s` 和 `-q`，加上 `--progress-bar`，你以后不会再面对黑屏发呆。
2. **自动重试 3 次**：加了 `--retry 3` / `--tries=3`，偶尔断一下能自己连回来。
3. **部署改走文件**：不玩 `| bash` 了，老老实实下载成 `~/install.sh` 再运行，这样才能看到进度条。
4. **清理临时文件**：执行完自动 `rm -f ~/install.sh`，不留垃圾。
