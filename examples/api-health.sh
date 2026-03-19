#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# api-health.sh — API 健康检查
# ============================================================
# cron 建议: */30 * * * *  (每30分钟)
#
# 检查你常用的 API 端点是否可达。
# 状态码 401/403/405 = 活着（需要认证而已）
# 状态码 5xx 或 000 = 挂了
# 只在发现异常时发通知。
#
# 自定义：修改 ENDPOINTS 变量添加你自己的 API。
# ============================================================

LOG=~/lifecoach.log

# 格式: 名称:URL（空格分隔）
ENDPOINTS="OpenAI:https://api.openai.com/v1/models Anthropic:https://api.anthropic.com/v1/messages"

HAS_FAILURE=false
RESULTS=""
FAILURES=""

for ep in $ENDPOINTS; do
    NAME="${ep%%:*}"
    URL="${ep#*:}"

    CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 --max-time 15 "$URL" 2>/dev/null) || CODE="000"

    # 5xx 或无响应 = 异常
    if echo "$CODE" | grep -qE "^(000|5[0-9]{2})$"; then
        HAS_FAILURE=true
        FAILURES="$FAILURES $NAME($CODE)"
    fi
    RESULTS="$RESULTS $NAME:$CODE"
done

TIMESTAMP=$(date '+%Y-%m-%d %H:%M')
echo "[$TIMESTAMP] [api-health]$RESULTS" >> "$LOG"

# 只在发现问题时发通知
if [ "$HAS_FAILURE" = "true" ]; then
    termux-notification \
        --title "API Alert" \
        --content "[$TIMESTAMP] Down:$FAILURES" \
        --id api-health \
        --priority high
fi
