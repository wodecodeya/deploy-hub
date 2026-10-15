# LZ 服务管理控制台 (Termux)

专为 Termux 打造的多服务一键启动与可视化管理面板。开箱即用，支持 11 个常用服务的启停、状态监控、日志查看、软链接修复、二进制同步，并内置 GitHub 热更新。

## ✨ 核心功能

- **开机自动弹菜单**：重启 App 后自动进入面板，15 秒无操作自动全量启动。
- **一键管理**：快速启动（仅补未运行）、停止全部、重启全部。
- **单服务操作**：可单独启动、停止、重启指定编号的服务。
- **实时状态**：菜单顶部实时显示所有服务的端口运行状态（绿色运行中 / 红色未运行）。
- **日志中心**：内置日志查看（`tail -f` 实时刷新）和一键清空日志。
- **环境自检**：完整启动时自动检查并安装缺失依赖（PHP、Node.js、Python、Go、ttyd 等）。
- **数据保护**：自动修复洛雪音乐缓存/音源软链接，自动桥接二进制文件到私有目录，防止安卓权限问题。
- **热更新**：菜单内按 `U` 即可从 GitHub 拉取最新脚本，旧版本自动备份到 `~/lz-menu.sh.bak`。

## 🚀 一键部署（Termux 终端直接执行）

**第一步：下载脚本、授权并建立 `lz` 快捷命令**

复制下面这整段命令到 Termux 回车（如 GitHub 直连不通，已将链接替换为当前可用的代理地址）：

```bash
curl -fsSL "https://tvv.tw/raw.githubusercontent.com/wodecodeya/deploy-hub/main/lz-termux/lz.sh" -o ~/lz-menu.sh && chmod +x ~/lz-menu.sh && ln -sf ~/lz-menu.sh $PREFIX/bin/lz && echo "✅ 核心脚本部署完成！输入 lz 可立即测试。"
```

**第二步：配置开机自动进入菜单（可选但强烈推荐）**

```bash
grep -q "LZ_MENU_STARTED" ~/.bashrc 2>/dev/null || (echo "" >> ~/.bashrc && echo "# LZ 服务管理控制台自动启动" >> ~/.bashrc && echo "if [ -n \"\$PS1\" ] && [ -z \"\$LZ_MENU_STARTED\" ]; then" >> ~/.bashrc && echo "    export LZ_MENU_STARTED=1" >> ~/.bashrc && echo "    bash ~/lz-menu.sh --boot" >> ~/.bashrc && echo "fi" >> ~/.bashrc) && echo "✅ 自启动配置完成！重启 App 或重新打开 Termux 即可自动进入菜单。"
```

## 🎮 使用说明

- **首次打开**：终端出现菜单，底部有 15 秒倒计时。
  - 等待 15 秒无操作 -> 自动执行完整启动（检查依赖、修复软链接、全量启动服务）。
  - 按任意键 -> 进入主菜单，不再自动启动。
- **手动呼出**：在任何终端输入 `lz` 回车，秒进菜单（不会倒计时，不会全量重启）。
- **常用操作**：
  - 按 `A`：快速启动（只补未运行的服务，最快）。
  - 按 `K`：完整启动（全套自检 + 全量重启）。
  - 按 `U`：从 GitHub 拉取最新脚本。
  - 按 `Q`：退出菜单，回到普通终端。

## 🛠 高级自定义

所有服务的定义都在脚本开头的 `SERVICES` 数组里，格式如下：

```bash
"编号|名称|端口|进程匹配|日志文件名|启动命令"
```

例如，如果你想新增一个名为 `myapp`、端口 `9090` 的服务，只需要在数组里加一行：

```bash
"12|我的应用|9090|myapp|myapp.log|cd ~/myapp && nohup ./myapp > $LOGDIR/myapp.log 2>&1 &"
```

修改后，按 `U` 更新脚本，或者重新下载覆盖即可生效。

## ⚠️ 注意事项

1. **需要存储权限**：首次使用需确保 Termux 已获取存储权限（`termux-setup-storage`）。
2. **防休眠**：脚本会自动执行 `termux-wake-lock`，防止系统休眠导致服务掉线。不建议手动 `termux-wake-unlock`。
3. **代理说明**：一键部署命令中使用了 `tvv.tw` 代理以加速 GitHub 访问。如该代理失效，请将 URL 替换为 `https://raw.githubusercontent.com/...` 或你常用的 GitHub 加速节点。
4. **兼容性**：仅支持 Termux 安卓环境，需要 `bash` 运行（不要用 `sh` 执行脚本）。

## 📄 License

MIT
```

---

### 📦 使用方式

1. 把上面的 `README.md` 内容保存到本地电脑，命名为 `README.md`。
2. 打开你的 GitHub 仓库 `deploy-hub`，进入 `lz-termux` 目录，点击 `Add file` → `Upload files`，把它传上去。
3. 以后别人访问你的仓库，就能看到说明，并且可以一键复制命令在 Termux 里部署了。

---

### 💡 提示

一键部署命令里用的还是你指定的 `tvv.tw` 代理链接，如果你后续更换了加速节点，记得把 `README.md` 里的 `curl` 链接和 `lz.sh` 里的 `GITHUB_URL` 同步修改一下，保持一致即可。
