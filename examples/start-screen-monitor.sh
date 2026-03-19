#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# start-screen-monitor.sh — 守护进程保活
# ============================================================
# cron 建议: */30 * * * *  (每30分钟检查一次)
#
# 确保 screen-monitor.sh 只有一个实例在运行。
# 如果进程死了，重新启动。
# ============================================================

PIDFILE="$HOME/.screen-monitor.pid"
SCRIPT="$HOME/scripts/screen-monitor.sh"

# 检查是否已有实例在运行
if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    exit 0  # 已在运行
  fi
fi

# 启动新实例
nohup "$SCRIPT" > /dev/null 2>&1 &
echo $! > "$PIDFILE"
