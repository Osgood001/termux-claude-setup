#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# battery-monitor.sh — 电池 + 温度监控
# ============================================================
# cron 建议: 11 */2 * * *  (每2小时)
#
# 读取电池状态，记录日志。
# 电量 < 20% 或温度 > 40°C 时发送告警通知。
# ============================================================

BATTERY=$(termux-battery-status 2>/dev/null)
LOGFILE="$HOME/lifecoach.log"

# 解析电池信息
PERCENT=$(echo "$BATTERY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('percentage','?'))" 2>/dev/null)
STATUS=$(echo "$BATTERY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('status','?'))" 2>/dev/null)
TEMP=$(echo "$BATTERY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('temperature','?'))" 2>/dev/null)

# 记录日志
echo "[$(date '+%Y-%m-%d %H:%M:%S')] [battery] ${PERCENT}% | ${STATUS} | ${TEMP}°C" >> "$LOGFILE"

# 低电量告警
if [ "$PERCENT" -lt 20 ] 2>/dev/null && [ "$STATUS" = "DISCHARGING" ]; then
  termux-notification \
    --title "电量提醒" \
    --content "电量 ${PERCENT}%，该充电了。" \
    --id battery-alert \
    --priority high
fi

# 高温告警
if python3 -c "exit(0 if float('$TEMP') > 40 else 1)" 2>/dev/null; then
  termux-notification \
    --title "温度警告" \
    --content "手机温度 ${TEMP}°C，过热了，让它休息一下。" \
    --id temp-alert \
    --priority high
fi
