#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# social-reminder.sh — 社交关系维护提醒
# ============================================================
# cron 建议: 3 20 * * 3,6  (每周三/六 20:03)
#
# 读取社交圈数据 (contacts.json)，计算上次联系距今天数，
# 超过目标频率则提醒。
#
# 数据格式见 templates/data/contacts.example.json
# ============================================================

LOG=~/lifecoach.log
DATA=~/data/contacts.json  # 修改为你的数据路径

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [social] $1" >> "$LOG"; }
log "社交圈提醒检查"

# 检查数据文件是否存在
if [ ! -f "$DATA" ]; then
    log "数据文件不存在: $DATA"
    exit 0
fi

REMINDER=$(python3 -c "
import json
from datetime import datetime

with open('$DATA') as f:
    data = json.load(f)

today = datetime.now()
reminders = []

freq_days = {'daily': 1, 'weekly': 7, 'biweekly': 14, 'monthly': 30}

for m in data.get('contacts', []):
    name = m['name']
    freq = m.get('frequency', 'monthly')
    last = m.get('lastContact')
    max_days = freq_days.get(freq, 30)

    if last:
        last_dt = datetime.strptime(last, '%Y-%m-%d')
        days_ago = (today - last_dt).days
        if days_ago > max_days:
            reminders.append(f'- {name}: {days_ago} days since last contact (target: {freq})')
    else:
        reminders.append(f'- {name}: never recorded (target: {freq})')

if reminders:
    print('Time to reach out:\n' + '\n'.join(reminders))
else:
    print('All contacts are up to date!')
")

if [ -n "$REMINDER" ]; then
    termux-notification --title "Social Circle" --content "$REMINDER" --id social-remind --priority low
    log "提醒: $REMINDER"
fi
