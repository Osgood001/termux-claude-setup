#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# breathe-remind.sh — 呼吸练习提醒
# ============================================================
# cron 建议: 睡前三轮
#   23 21 * * *   (21:23)
#   47 22 * * *   (22:47)
#   17 23 * * *   (23:17)
#
# 4-7-8 呼吸法：吸气4秒 → 屏息7秒 → 呼气8秒
# 每个时段发不同语气的提醒。
# ============================================================

HOUR=$(date +%H)

# 不同时段不同语气的提醒语
MSGS_EARLY=(
  "睡前呼吸时间。放下手机，4-7-8 呼吸三轮：吸气4秒，屏息7秒，呼气8秒。"
  "每天睡前的呼吸练习，比刷手机有用100倍。4-7-8，现在开始。"
)
MSGS_MID=(
  "夜深了，别碰别的。4-7-8 呼吸先做完，做完再决定干嘛。"
  "第二轮提醒：闭眼，4-7-8 开始。吸气4秒...屏息7秒...呼气8秒..."
)
MSGS_LATE=(
  "最后提醒：躺下，闭眼，4-7-8 呼吸，直接睡。别碰手机了。"
  "做完三轮呼吸，关屏，睡觉。晚安。"
)

# 随机选一条
pick_random() {
  local arr=("$@")
  echo "${arr[$((RANDOM % ${#arr[@]}))]}"
}

if [ "$HOUR" -le 21 ]; then
  MSG=$(pick_random "${MSGS_EARLY[@]}")
elif [ "$HOUR" -le 22 ]; then
  MSG=$(pick_random "${MSGS_MID[@]}")
else
  MSG=$(pick_random "${MSGS_LATE[@]}")
fi

termux-notification \
  --title "4-7-8 呼吸" \
  --content "$MSG" \
  --id breathe478 \
  --priority high \
  --vibrate 200,100,200

# 同时弹一个 toast
termux-toast -b white -c black "$MSG" 2>/dev/null
