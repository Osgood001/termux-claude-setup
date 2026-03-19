# 04 — Cron 定时任务体系

## 安装 cronie

```bash
pkg install cronie
crond  # 启动 cron 守护进程
```

确保 crond 在 Termux 启动时自动运行：

```bash
echo "crond" >> ~/.bashrc
```

## Cron 基础语法

```
分钟 小时 日 月 星期  命令
 │    │   │ │  │
 │    │   │ │  └── 0-7 (0和7都是周日)
 │    │   │ └───── 1-12
 │    │   └─────── 1-31
 │    └─────────── 0-23
 └──────────────── 0-59
```

常用示例：

```cron
# 每天早上 8:03
3 8 * * * ~/scripts/morning.sh

# 每 2 小时（在第 11 分钟）
11 */2 * * * ~/scripts/check.sh

# 每 30 分钟
*/30 * * * * ~/scripts/health.sh

# 每周三和周六晚上 8:03
3 20 * * 3,6 ~/scripts/social.sh

# 每周日 22:33
33 22 * * 0 ~/scripts/weekly.sh

# 工作日 9:00
0 9 * * 1-5 ~/scripts/workday.sh
```

## 时区设置

在 crontab 第一行设置时区，所有任务按这个时区执行：

```cron
TZ=Asia/Shanghai
```

## 编辑 crontab

```bash
# 编辑
crontab -e

# 查看
crontab -l

# 从文件导入
crontab < templates/crontab.example
```

## 任务编排建议

### 错开执行时间

不要把所有任务都放在整点。每个任务错开几分钟，避免同时执行导致资源竞争：

```cron
# 好的做法：每个任务错开几分钟
3 8 * * * ~/scripts/morning.sh
7 14 * * * ~/scripts/afternoon.sh
3 22 * * * ~/scripts/evening.sh

# 不好的做法：全在整点
0 8 * * * ~/scripts/morning.sh
0 14 * * * ~/scripts/afternoon.sh
0 22 * * * ~/scripts/evening.sh
```

### 按优先级分类

```cron
# === 核心（必装）===
3 8 * * * ~/scripts/morning-coach.sh
3 22 * * * ~/scripts/evening-review.sh
11 */2 * * * ~/scripts/battery-monitor.sh

# === 健康（推荐）===
23 21 * * * ~/scripts/breathe-remind.sh
*/30 * * * * ~/scripts/start-screen-monitor.sh >/dev/null 2>&1

# === 信息（可选）===
33 9 * * * ~/scripts/news-digest.sh

# === 数据（可选）===
33 23 * * * ~/scripts/daily-report.sh
```

### 输出重定向

cron 任务的输出默认发到邮件（Termux 没有邮件系统），建议重定向到日志：

```cron
# 标准做法：输出到日志，错误也到日志
3 8 * * * ~/scripts/morning.sh >> ~/lifecoach.log 2>&1

# 或者静默（不关心输出的任务）
*/30 * * * * ~/scripts/start-screen-monitor.sh >/dev/null 2>&1
```

## 调试 cron

```bash
# 查看 cron 日志
grep CRON ~/lifecoach.log

# 手动执行测试
bash ~/scripts/morning-coach.sh

# 确认 crond 在运行
pgrep crond
```

## 常见问题

**Q: cron 任务不执行？**
- 检查 `crond` 是否在运行：`pgrep crond`
- 检查脚本权限：`chmod +x ~/scripts/*.sh`
- 检查脚本 shebang：第一行是 `#!/data/data/com.termux/files/usr/bin/bash`
- 手动执行脚本看是否报错

**Q: 环境变量在 cron 中不可用？**
- cron 运行的环境和你的终端不同
- 在脚本开头显式设置 PATH：`export PATH="$HOME/.local/bin:$PATH"`
- 或者在 crontab 中设置：`PATH=/data/data/com.termux/files/usr/bin`

→ 下一步：[通知与传感器](05-notifications.md)
