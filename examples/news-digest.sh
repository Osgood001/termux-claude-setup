#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# news-digest.sh — 新闻/论文摘要推送
# ============================================================
# cron 建议: 33 9 * * *  (每天 9:33)
#
# 抓取 Hacker News 热门文章，让 Claude 生成中文摘要。
# 失败则直接推送标题列表。
#
# 依赖: pip install requests
# ============================================================

LOG=~/lifecoach.log

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] [news] $1" >> "$LOG"; }
log "开始抓取 HN"

# 抓取 HN Top 10 标题
TITLES=$(python3 -c "
import requests, json

try:
    ids = requests.get('https://hacker-news.firebaseio.com/v0/topstories.json', timeout=15).json()[:10]
    titles = []
    for i in ids:
        item = requests.get(f'https://hacker-news.firebaseio.com/v0/item/{i}.json', timeout=10).json()
        titles.append(item.get('title', ''))
    print('\n'.join(f'{j+1}. {t}' for j,t in enumerate(titles)))
except Exception as e:
    print(f'ERROR: {e}')
" 2>/dev/null)

if echo "$TITLES" | grep -q "^ERROR"; then
    log "HN 抓取失败: $TITLES"
    termux-notification --title "HN 日报" --content "今日抓取失败，请检查网络" --id hn-daily --priority low
    exit 1
fi

# 尝试用 Claude 生成中文摘要
if command -v claude &>/dev/null; then
    RESULT=$(timeout 120 claude --print "以下是今天的 Hacker News Top 10：

$TITLES

请生成一个简洁的中文摘要通知（200字内）：
- 标出最值得关注的 2-3 条
- 简要说明为什么值得看
- 语气简洁有信息量

直接输出内容，不要额外说明。" 2>>"$LOG")

    if [ -n "$RESULT" ]; then
        termux-notification --title "HN 日报" --content "$(echo "$RESULT" | head -c 500)" --id hn-daily --priority low
        log "HN 日报推送成功（AI 摘要）"
        exit 0
    fi
fi

# 回退：直接推送标题
termux-notification --title "HN 日报" --content "$TITLES" --id hn-daily --priority low
log "HN 日报推送成功（原始标题）"
