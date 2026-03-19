# 07 — 进阶玩法

基础搭好之后，这里是一些进阶玩法。

## 深夜亮屏检测（不需要 root）

### 问题

你想在凌晨检测到自己还在玩手机时收到提醒。但 Android 非 root 环境**不允许**：
- 读取屏幕状态（`dumpsys display` 需要 shell 权限）
- 读取背光亮度（`/sys/class/backlight` 不可访问）
- 监听用户输入事件（需要 INPUT 权限）

### 解决方案：电池电流作为代理指标

`termux-battery-status` 返回的 `current` 字段（单位 μA）可以间接反映屏幕状态：

- **屏幕亮**：放电电流绝对值大，通常 > 150mA（即 current < -150000 μA）
- **屏幕灭**：放电电流绝对值小，通常 < 100mA

### 实现

```bash
# 读取电流
CURRENT=$(termux-battery-status | python3 -c "
import json, sys
print(json.load(sys.stdin).get('current', 0))
")

# 判断屏幕状态
if [ "$CURRENT" -lt -150000 ]; then
  echo "屏幕可能亮着"
fi
```

完整的守护进程实现见 `examples/screen-monitor.sh`，包含：
- 每 60 秒检查一次
- 连续 5 次检测到 = 确认亮屏 5 分钟
- 发送通知提醒
- 30 分钟冷却期（避免轰炸）
- 只在 00:00-05:59 运行

### 校准

不同手机的电流阈值不同。建议先手动测几次：

```bash
# 亮屏时执行
termux-battery-status | python3 -c "import json,sys;print(json.load(sys.stdin)['current'])"

# 灭屏时执行（用 cron 或 sleep 延迟）
echo "sleep 10 && termux-battery-status > ~/screen-off-battery.json" | bash &
# 然后立刻关屏，10秒后查看结果
```

根据结果调整 `screen-monitor.sh` 中的 `THRESHOLD` 值。

## 自动日报系统

### 架构

```
日志收集 → Claude 分析 → Markdown 日报 → Git 版本管理
```

每天 23:30，自动：
1. 收集当天的 lifecoach.log 日志
2. 读取电池状态
3. 让 Claude 生成日报 markdown
4. 保存到 `~/daily/YYYY-MM-DD.md`
5. 可选：git commit

### 周报

每周日汇总本周所有日报，生成周报：
1. 读取本周 7 份日报
2. Claude 分析趋势
3. 输出周报 markdown
4. 保存到 `~/weekly/YYYY-WXX.md`

实现见 `examples/daily-report.sh`。

## 数据追踪系统

用 JSON 文件追踪任何你想追踪的东西。基本模式：

```
JSON 数据文件 → Python 脚本分析 → Claude 生成建议 → termux-notification
```

### 社交关系追踪

`contacts.json` 记录每个人的联系频率和上次联系时间。脚本定期检查是否有超期未联系的朋友。

### 任务/交付物追踪

`tasks.json` 记录每个任务的截止日期和进度。脚本定期检查临近截止的任务。

### 健康数据

`health.json` 记录每日的睡眠、精力、运动等指标。脚本生成趋势分析。

模板见 `templates/data/`。

## 多模态通知策略

不只是发通知，可以组合多种输出方式：

```bash
# 普通提醒：纯通知
termux-notification --title "..." --content "..."

# 重要提醒：通知 + 震动
termux-notification --title "..." --content "..." --priority high
termux-vibrate -d 500

# 紧急提醒：通知 + 震动 + 语音
termux-notification --title "..." --content "..." --priority max
termux-vibrate -d 200,100,200,100,200
termux-tts-speak "..."

# 屏幕提示：toast（用户正在看屏幕时）
termux-toast -b white -c black "..."
```

## 跨设备同步

如果你有多台设备或想备份：

```bash
# 初始化 git
cd ~/lifecoach-data
git init
git remote add origin git@github.com:you/lifecoach-data.git

# 在 cron 中定期同步
# 0 3 */2 * * cd ~/lifecoach-data && git add -A && git commit -m "sync $(date +%Y-%m-%d)" && git push
```

→ 下一步：[踩坑指南](08-faq.md)
