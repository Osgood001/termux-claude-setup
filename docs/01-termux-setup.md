# 01 — Termux 环境搭建

## 安装 Termux

**必须从 F-Droid 安装**，不要用 Google Play Store 版本（已停止更新，很多包装不上）。

1. 安装 [F-Droid](https://f-droid.org/)
2. 在 F-Droid 中搜索安装：
   - **Termux** — 终端模拟器
   - **Termux:API** — 让脚本访问手机硬件（通知、传感器等）

## 基础环境配置

```bash
# 更新包管理器
pkg update && pkg upgrade -y

# 安装核心工具
pkg install -y \
  git \
  nodejs-lts \
  python \
  cronie \
  termux-api \
  curl \
  jq \
  proot

# 启动 cron 服务
crond

# 安装 Python 依赖（可选，新闻抓取用）
pip install requests
```

## 存储权限

```bash
# 让 Termux 访问手机存储
termux-setup-storage
```

执行后会弹出权限请求，点击允许。之后可以通过 `~/storage/` 访问手机文件。

## /tmp 目录问题

Android 不允许 Termux 使用系统 `/tmp` 目录。Claude Code 启动时需要 `/tmp`，有两种解决方案：

### 方案 A: proot（推荐）

```bash
pkg install proot
# 之后用 proot 启动需要 /tmp 的程序
proot -b $TMPDIR:/tmp claude
```

### 方案 B: termux-chroot

```bash
pkg install proot
termux-chroot
# 在 chroot 环境中 /tmp 可用
claude
```

## 后台运行设置

**防止系统杀掉 Termux**（非常重要）：

1. **电池优化**：系统设置 → 电池 → 找到 Termux → 选择「不限制」
2. **自启动**：系统设置 → 应用管理 → Termux → 允许自启动
3. **后台运行**：系统设置 → 应用管理 → Termux → 允许后台活动
4. **锁定任务**：在最近任务列表中，下拉 Termux 卡片锁定

不同品牌设置路径不同：
- **小米/红米**：设置 → 应用设置 → 应用管理 → Termux → 省电策略 → 无限制
- **华为/荣耀**：设置 → 电池 → 启动管理 → Termux → 手动管理（全部打开）
- **vivo/OPPO**：设置 → 电池 → 后台高耗电 → 允许 Termux
- **三星**：设置 → 电池 → 后台使用限制 → 移除 Termux

## 验证安装

```bash
# 测试通知
termux-notification --title "Test" --content "Hello from Termux!"

# 测试电池读取
termux-battery-status

# 测试 cron
echo "* * * * * echo 'cron works' >> ~/cron-test.log" | crontab -
# 等1分钟后检查
cat ~/cron-test.log
# 确认后清除测试任务
crontab -r
```

如果 `termux-notification` 或 `termux-battery-status` 超时无响应，确保：
1. Termux:API app 已安装且**已打开过至少一次**
2. 在手机设置中给 Termux:API 授权了通知权限

→ 下一步：[安装 Claude Code](02-claude-code.md)
