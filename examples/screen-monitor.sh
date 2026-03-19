#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# screen-monitor.sh — 深夜亮屏检测守护进程
# ============================================================
# 不直接放 cron，而是通过 start-screen-monitor.sh 保活。
#
# 原理：
#   Android 非 root 环境无法直接读取屏幕状态。
#   但可以通过电池放电电流间接判断：
#     - 屏幕亮：放电电流绝对值 > 150mA (current < -150000 μA)
#     - 屏幕灭：放电电流绝对值 < 100mA
#
#   每 60 秒检查一次，连续 5 次检测到屏幕亮（= 5 分钟）
#   → 发送通知提醒睡觉，30 分钟冷却期。
#
# 工作时段：00:00 - 05:59（只在深夜运行）
# ============================================================

LOGFILE="$HOME/lifecoach.log"
STATEFILE="$HOME/.screen-on-count"
THRESHOLD=-150000    # 电流阈值（μA），小于此值 = 屏幕亮
CHECK_INTERVAL=60    # 检查间隔（秒）
CONSECUTIVE_NEEDED=5 # 连续检测次数（5次 = 5分钟）
COOLDOWN=1800        # 冷却时间（秒）
COOLDOWN_FILE="$HOME/.sleep-nag-cooldown"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [screen-monitor] $1" >> "$LOGFILE"
}

# 通过 termux-battery-status 读取电流
get_current() {
  timeout 5 termux-battery-status 2>/dev/null | \
    python3 -c "import json,sys;print(json.load(sys.stdin).get('current',0))" 2>/dev/null
}

# 发送睡觉提醒
send_reminder() {
  local MSGS=(
    "凌晨了还在看手机。放下来，做几轮深呼吸，闭眼睡觉。充足的睡眠比什么都重要。"
    "都这个点了，屏幕亮了5分钟了。放下手机，休息吧。"
    "检测到你还醒着。明天的事明天再说。现在：放下手机 → 深呼吸 → 睡。"
    "手机已经亮了一阵了，别刷了。关屏，睡觉。"
  )
  local MSG="${MSGS[$((RANDOM % ${#MSGS[@]}))]}"

  termux-notification \
    --title "该睡了" \
    --content "$MSG" \
    --id sleep-nag \
    --priority high 2>/dev/null

  log "已发送深夜提醒: $MSG"
  date +%s > "$COOLDOWN_FILE"
}

# 检查是否在冷却期
is_in_cooldown() {
  if [ -f "$COOLDOWN_FILE" ]; then
    local LAST=$(cat "$COOLDOWN_FILE" 2>/dev/null)
    local NOW=$(date +%s)
    if [ $((NOW - LAST)) -lt "$COOLDOWN" ]; then
      return 0  # 在冷却中
    fi
  fi
  return 1
}

# 初始化
echo 0 > "$STATEFILE"
log "深夜屏幕监控启动"

while true; do
  HOUR=$(date +%H)

  # 只在 00:00 - 05:59 运行
  if [ "$HOUR" -ge 0 ] && [ "$HOUR" -le 5 ]; then
    CURRENT=$(get_current)

    if [ -n "$CURRENT" ] && [ "$CURRENT" -lt "$THRESHOLD" ] 2>/dev/null; then
      # 屏幕可能亮着
      COUNT=$(cat "$STATEFILE" 2>/dev/null || echo 0)
      COUNT=$((COUNT + 1))
      echo "$COUNT" > "$STATEFILE"

      if [ "$COUNT" -ge "$CONSECUTIVE_NEEDED" ]; then
        if ! is_in_cooldown; then
          send_reminder
        fi
        echo 0 > "$STATEFILE"
      fi
    else
      echo 0 > "$STATEFILE"
    fi
  else
    echo 0 > "$STATEFILE"
    rm -f "$COOLDOWN_FILE" 2>/dev/null
  fi

  sleep "$CHECK_INTERVAL"
done
