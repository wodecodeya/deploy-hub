# 🚀 Deploy Hub · 一键部署工具箱

本仓库用于存放各类项目的一键部署脚本，目前包含：

- **LX Music Server**（洛雪音乐服务器）

所有脚本均支持 **加速代理** 和 **直连 GitHub** 两种拉取方式，并内置了 Termux 自启逻辑，真正做到“一次部署，零命令启动”。

---

## 📱 前置准备

1. **安装 Termux**  
   务必从 [F-Droid](https://f-droid.org/packages/com.termux/) 或 [GitHub Releases](https://github.com/termux/termux-app/releases) 下载安装，**不要用 Google Play 商店的旧版本**。

2. **确保网络畅通**  
   由于脚本需要从 GitHub 拉取代码，请确保手机已连接网络，必要时开启 VPN。  
   脚本会自动尝试使用加速代理，失败后再直连，所以大多数国内网络都能顺利执行。

3. **安装 wget（如果缺少）**  
   如果执行时提示 `wget: command not found`，请先运行：

```bash
pkg install wget -y
```

---

## 🎵 部署 LX Music Server（菜单式）

在 Termux 中粘贴以下命令即可完成一键部署，并自动配置好开机自启和快捷命令。

### ✅ 方式一：带加速头（推荐，国内网络友好）

```bash
wget -O lxmusic_deploy.sh "https://proxy.lalifeier.eu.org/https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lxserver/lxmusic_deploy.sh" && bash lxmusic_deploy.sh && rm -f lxmusic_deploy.sh
```

### ✅ 方式二：直连 GitHub（需能正常访问 GitHub）

```bash
wget -O lxmusic_deploy.sh "https://raw.githubusercontent.com/wodecodeya/deploy-hub/main/lxserver/lxmusic_deploy.sh" && bash lxmusic_deploy.sh && rm -f lxmusic_deploy.sh
```

---

## 📋 菜单功能说明

执行上述命令后，脚本会自动完成安装并弹出交互式菜单。

以后每次重开 Termux，只需输入 `lx` 回车即可随时进入菜单：

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
  [8] 备份数据
  [9] 恢复数据
  [10] 一键自毁 (删除所有文件与配置)
  [0] 退出
=========================================
💡 提示：10 秒内无操作，将自动启动服务
=========================================
```

- 输入 `1` 即可安装或更新到官方最新版。
- 输入 `5` 查看服务是否正在运行。
- 输入 `6` 实时滚动查看运行日志（按 `Ctrl+C` 退出）。
- 输入 `8` 可将服务数据和配置打包备份。
- 输入 `9` 可从备份列表中选择还原数据。
- 输入 `10` 可彻底清除服务、备份、别名和自启配置。
- 输入 `0` 退出菜单。

> 💡 脚本内置 **智能版本检测**：如果当前已经是最新版，会提示你是否强制重装，避免浪费流量。

---

## 🔧 脚本特性

- **自动获取最新版本**：无需手动修改版本号，永远部署官方最新版。
- **自动处理嵌套目录**：解决解压后目录“套娃”导致 `npm install` 找不到文件的问题。
- **加速代理自动切换**：优先走加速代理，失败后自动直连。
- **旧数据安全备份**：升级时会先把旧目录备份为 `lxserver_old_temp`，确认无误后再替换。
- **Termux 自启**：自动向 `~/.bashrc` 写入检测逻辑，打开 Termux 即自动拉起服务（无需手动敲命令）。
- **快捷别名**：自动注入 `lx` 命令，以后管理服务只需要输入 `lx` 回车即可进入菜单。

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
