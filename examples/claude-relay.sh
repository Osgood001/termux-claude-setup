#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# claude-relay.sh — 核心中继脚本
# ============================================================
# 整个系统的基石。所有定时任务都通过这个脚本执行。
#
# 工作原理：
#   1. 尝试调用 Claude API 生成智能回复
#   2. 成功 → 用 AI 回复的内容发通知
#   3. 失败 → 用预设的静态文案发通知（保底）
#
# 用法：
#   claude-relay.sh <prompt> <fallback-title> <fallback-msg>
#
# 参数：
#   $1 - 发给 Claude 的 prompt（指令）
#   $2 - 通知标题（同时用于成功和失败场景）
#   $3 - 回退消息（API 失败时使用的静态文案）
#
# 示例：
#   ./claude-relay.sh \
#     "你是一个温柔的早间助手。用50字提醒用户今天要做什么。" \
#     "早安" \
#     "新的一天开始了，想想今天最重要的三件事。"
# ============================================================

PROMPT="$1"
FALLBACK_TITLE="$2"
FALLBACK_MSG="$3"
LOGFILE="$HOME/lifecoach.log"
TIMEOUT=120  # 超时时间（秒），防止 API 卡住

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOGFILE"
}

log "=== 尝试执行: $FALLBACK_TITLE ==="

# 尝试用 Claude 执行
if command -v claude &>/dev/null; then
  RESULT=$(timeout "$TIMEOUT" claude --print "$PROMPT" 2>>"$LOGFILE")
  EXIT_CODE=$?

  if [ $EXIT_CODE -eq 0 ] && [ -n "$RESULT" ]; then
    log "Claude 执行成功"
    # 用 AI 生成的内容发通知（截断到 500 字符，通知栏有长度限制）
    termux-notification \
      --title "$FALLBACK_TITLE" \
      --content "$(echo "$RESULT" | head -c 500)" \
      --id "relay-$(date +%H%M)" \
      --priority low
    exit 0
  else
    log "Claude 执行失败 (exit: $EXIT_CODE)，回退到纯通知"
  fi
else
  log "Claude 命令不可用，回退到纯通知"
fi

# 回退：纯 shell 通知（保证 100% 送达）
termux-notification \
  --title "$FALLBACK_TITLE" \
  --content "$FALLBACK_MSG" \
  --id "relay-$(date +%H%M)" \
  --priority low

log "回退通知已发送"
