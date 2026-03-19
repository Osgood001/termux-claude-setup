#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# daily-report.sh — 自动日报生成
# ============================================================
# cron 建议: 33 23 * * *  (每天 23:33)
#
# 收集当天的日志数据，让 Claude 生成一份 markdown 日报。
# 日报保存到 ~/daily/ 目录，可选 git 版本管理。
# ============================================================

LOG=~/lifecoach.log
DIR=~/daily
TODAY=$(TZ=Asia/Shanghai date +%Y-%m-%d)
FILE="$DIR/$TODAY.md"

mkdir -p "$DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [daily-report] $1" >> "$LOG"; }
log "生成日报 $TODAY"

# 如果今天的日报已存在，跳过
if [ -f "$FILE" ]; then
    log "日报已存在，跳过"
    exit 0
fi

# 收集今天的数据
BATTERY=$(timeout 5 termux-battery-status 2>/dev/null | \
  python3 -c "import json,sys;d=json.load(sys.stdin);print(f\"Battery: {d['percentage']}%\")" 2>/dev/null || echo "Unknown")
TODAY_LOG=$(grep "\[$TODAY\]" ~/lifecoach.log 2>/dev/null | tail -20)

# 尝试用 Claude 生成日报
RESULT=$(timeout 120 claude --print "Today is $TODAY. Here is the system log for today:

$TODAY_LOG

Phone status: $BATTERY

Generate a concise daily report in markdown:
# Daily Report — $TODAY

## Activities
(extract from logs)

## Phone Status
(battery info)

## Notes
(if logs are sparse, note that)

---
_Auto-generated at $(date '+%Y-%m-%d %H:%M')_

Output markdown directly." 2>>"$LOG")

if [ -n "$RESULT" ]; then
    echo "$RESULT" > "$FILE"
    log "日报生成成功"
else
    cat > "$FILE" << FALLBACK
# Daily Report — $TODAY

Today's logs were sparse.

Phone: $BATTERY

---
_Auto-generated at $(date '+%Y-%m-%d %H:%M')_
FALLBACK
    log "使用回退模板"
fi

# 可选：Git 版本管理
# cd ~/daily && git add "$FILE" && git commit -m "daily: $TODAY"

termux-notification --title "Daily Report" --content "Report for $TODAY generated" --id daily-report --priority low
