# 🚀 Deploy Hub · 一键部署工具箱
## 📱 前置准备

1. **安装 Termux**  
   务必从 [F-Droid](https://f-droid.org/packages/com.termux/) 或 [GitHub Releases](https://github.com/termux/termux-app/releases) 下载安装，**不要用 Google Play 商店的旧版本**。

2. **确保网络畅通**  
   由于脚本需要从 GitHub 拉取代码，请确保手机已连接网络，必要时开启 VPN。  
   脚本会自动尝试使用加速代理，失败后再直连，所以大多数国内网络都能顺利执行。

3. **安装 curl（如果缺少）**  
   如果执行时提示 `curl: command not found`，请先运行：

```bash
pkg install curl -y
```

---

## 🎵 部署 LX Music Server（菜单式）

在 Termux 中粘贴以下命令即可进入交互式菜单，按数字选择对应操作。

### ✅ 方式一：带加速头（推荐，国内网络友好）

```bash
bash <(curl -sL "https://proxy.lalifeier.eu.org/https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lxserver/lxmusic_deploy.sh")
```

### ✅ 方式二：直连 GitHub（需能正常访问 GitHub）

```bash
bash <(curl -sL "https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lxserver/lxmusic_deploy.sh")
```

---

## 📋 菜单功能说明

执行上述命令后，会显示如下菜单：

```
=========================================
       🎵 LX Music Server 工具箱
=========================================
  [1] 安装 / 更新
  [2] 启动服务
  [3] 停止服务
  [4] 重启服务
  [5] 查看状态
  [6] 查看日志
  [7] 卸载服务
  [0] 退出
=========================================
请输入选项数字:
```

- 输入 `1` 即可安装或更新到官方最新版。
- 输入 `5` 查看服务是否正在运行。
- 输入 `6` 实时滚动查看运行日志（按 `Ctrl+C` 退出）。
- 输入 `7` 卸载服务（会二次确认，防止误删）。
- 输入 `0` 退出菜单。

> 💡 脚本内置 **智能版本检测**：如果当前已经是最新版，会提示你是否强制重装，避免浪费流量。

---

## ⚡ 静默极速模式（进阶）

如果你希望完全跳过菜单，直接执行安装/更新，可以在命令末尾加上 `install` 参数：

```bash
bash <(curl -sL "https://proxy.lalifeier.eu.org/https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lxserver/lxmusic_deploy.sh") install
```

同样支持直连：

```bash
bash <(curl -sL "https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lxserver/lxmusic_deploy.sh") install
```

---

## 🔧 脚本特性

- **自动获取最新版本**：无需手动修改版本号，永远部署官方最新版。
- **自动处理嵌套目录**：解决解压后目录“套娃”导致 `npm install` 找不到文件的问题。
- **加速代理自动切换**：优先走加速代理，失败后自动直连。
- **旧数据安全备份**：升级时会先把旧目录备份为 `lxserver_old_temp`，确认无误后再替换。
- **Termux 自启**：自动向 `~/.bashrc` 写入检测逻辑，打开 Termux 即自动拉起服务（无需手动敲命令）。

---

## 📝 注意事项

- 部署完成后，服务默认运行在 **端口 9527**。
- 日志文件位于 `~/lxserver/node.log`，可用菜单选项 `6` 查看。
- 为保障后台长期运行，建议在手机系统设置中把 **Termux 的电池优化设为“不受限制”**。
- 本仓库脚本仅用于个人学习与便捷部署，请遵守相关开源协议。

---

## 🔗 相关链接

- [LX Music Server 官方仓库](https://github.com/XCQ0607/lxserver)
- [Termux 官网](https://termux.dev/)

---

*欢迎自取*
