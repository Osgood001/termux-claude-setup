# 03 — Claude-Relay 模式详解

## 为什么需要 Relay？

你在手机上跑 cron 任务调用 Claude API，可能遇到：
- API 超时（网络不好）
- API 服务临时不可用
- API key 余额不足
- Claude Code CLI 出 bug

**但你的提醒不能断。** 早上 8 点的规划提醒、深夜的睡觉提醒——这些不能因为 API 挂了就没了。

## Relay 模式工作原理

```
┌──────────────────────────────────────┐
│          claude-relay.sh             │
│                                      │
│  输入: prompt + fallback_title +     │
│        fallback_msg                  │
│                                      │
│  ┌────────────────────────┐          │
│  │ claude --print $prompt │          │
│  │     (timeout 120s)     │          │
│  └───────────┬────────────┘          │
│              │                       │
│      ┌───────┴───────┐              │
│      ▼               ▼              │
│  [成功+有内容]    [失败/超时/空]     │
│      │               │              │
│      ▼               ▼              │
│  AI 生成的通知    静态回退通知       │
│  (智能内容)      (预设文案)          │
│                                      │
│  → 100% 送达率，只是智能程度不同     │
└──────────────────────────────────────┘
```

## 脚本解读

```bash
#!/data/data/com.termux/files/usr/bin/bash
PROMPT="$1"           # 发给 Claude 的指令
FALLBACK_TITLE="$2"   # 通知标题
FALLBACK_MSG="$3"     # API 失败时的保底文案
TIMEOUT=120           # 超时 2 分钟

# 尝试调用 Claude
RESULT=$(timeout "$TIMEOUT" claude --print "$PROMPT" 2>>"$LOGFILE")

if [ $? -eq 0 ] && [ -n "$RESULT" ]; then
  # 成功：用 AI 内容发通知
  termux-notification --title "$FALLBACK_TITLE" \
    --content "$(echo "$RESULT" | head -c 500)"
else
  # 失败：用保底文案发通知
  termux-notification --title "$FALLBACK_TITLE" \
    --content "$FALLBACK_MSG"
fi
```

## 使用方法

任何定时任务都可以通过一行调用 relay：

```bash
~/claude-relay.sh \
  "你是一个早间助手。用50字提醒用户开始新的一天。" \
  "早安" \
  "新的一天开始了，想想今天最重要的三件事。"
```

三个参数：
1. **Prompt** — AI 模式下的完整指令
2. **Title** — 通知标题
3. **Fallback** — 降级模式下的静态文案

## 写好 Fallback 的技巧

Fallback 文案是 API 全挂时用户唯一能看到的内容，要写好：

- **包含核心信息**：不是"提醒失败"，而是把提醒内容本身写进去
- **可执行**：用户看了知道该做什么
- **简洁**：通知栏空间有限，50-100 字最佳

```bash
# 差的 fallback
"API 调用失败，请稍后重试"

# 好的 fallback
"早安。新的一天，写下今天三件一定要做的事，然后开干。别久坐，每小时动一下。"
```

## 进阶：Relay + 数据

relay 模式也可以结合本地数据。在调用 Claude 之前先收集数据，成功时传给 AI 做分析，失败时直接展示原始数据：

```bash
# 收集数据
BATTERY=$(termux-battery-status | jq .percentage)

# Relay 调用
~/claude-relay.sh \
  "电量 ${BATTERY}%，分析一下用户的使用情况并给建议。" \
  "电池状态" \
  "当前电量 ${BATTERY}%"
```

→ 下一步：[Cron 定时任务](04-cron-system.md)
