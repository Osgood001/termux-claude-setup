#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# install.sh — Termux + Claude Code AI 助手一键配置
# ============================================================
# 运行方式：bash install.sh
# ============================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BOLD}"
echo "╔══════════════════════════════════════════════╗"
echo "║  Termux + Claude Code AI 助手配置            ║"
echo "║  把 AI 装进你的口袋                          ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "${NC}"

# ---- Step 1: 检查环境 ----
echo -e "${YELLOW}[1/6] 检查环境...${NC}"

if [ ! -d "/data/data/com.termux" ]; then
  echo -e "${RED}错误：不在 Termux 环境中。请在 Termux 中运行此脚本。${NC}"
  exit 1
fi

echo -e "  ${GREEN}✓${NC} Termux 环境"

# 检查 termux-api
if command -v termux-notification &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} termux-api 已安装"
else
  echo -e "  ${YELLOW}!${NC} termux-api 未安装，正在安装..."
  pkg install -y termux-api
fi

# ---- Step 2: 安装依赖 ----
echo -e "${YELLOW}[2/6] 安装依赖包...${NC}"

PACKAGES="git nodejs python cronie curl proot"
for pkg_name in $PACKAGES; do
  if dpkg -s "$pkg_name" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $pkg_name"
  else
    echo -e "  ${YELLOW}→${NC} 安装 $pkg_name..."
    pkg install -y "$pkg_name" 2>/dev/null
  fi
done

# 安装 Python requests（新闻抓取用）
pip install requests -q 2>/dev/null && echo -e "  ${GREEN}✓${NC} python requests"

# ---- Step 3: 安装 Claude Code ----
echo -e "${YELLOW}[3/6] 检查 Claude Code...${NC}"

if command -v claude &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} Claude Code 已安装"
else
  echo -e "  ${YELLOW}→${NC} 安装 Claude Code..."
  npm install -g @anthropic-ai/claude-code
fi

# 设置 alias（proot 包装）
if ! grep -q 'alias claude=' ~/.bashrc 2>/dev/null; then
  echo 'alias claude="proot -b $TMPDIR:/tmp claude"' >> ~/.bashrc
  echo -e "  ${GREEN}✓${NC} 已添加 proot alias 到 ~/.bashrc"
fi

# ---- Step 4: 复制脚本 ----
echo -e "${YELLOW}[4/6] 配置脚本...${NC}"

SCRIPT_DIR="$HOME/scripts"
mkdir -p "$SCRIPT_DIR"

# 获取本仓库的路径
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# 复制示例脚本
for script in "$REPO_DIR"/examples/*.sh; do
  BASENAME=$(basename "$script")
  cp "$script" "$SCRIPT_DIR/$BASENAME"
  chmod +x "$SCRIPT_DIR/$BASENAME"
  echo -e "  ${GREEN}✓${NC} $BASENAME"
done

# 修正 start-screen-monitor.sh 中的路径
sed -i "s|~/scripts/|$SCRIPT_DIR/|g" "$SCRIPT_DIR/start-screen-monitor.sh" 2>/dev/null

# ---- Step 5: CLAUDE.md ----
echo -e "${YELLOW}[5/6] 配置 AI 人格...${NC}"

mkdir -p ~/.claude

if [ -f ~/.claude/CLAUDE.md ]; then
  echo -e "  ${YELLOW}!${NC} ~/.claude/CLAUDE.md 已存在，跳过（不覆盖）"
  echo -e "  ${YELLOW}!${NC} 模板在: $REPO_DIR/templates/CLAUDE.md"
else
  cp "$REPO_DIR/templates/CLAUDE.md" ~/.claude/CLAUDE.md
  echo -e "  ${GREEN}✓${NC} 已复制 CLAUDE.md 模板到 ~/.claude/"
  echo -e "  ${YELLOW}!${NC} 请编辑 ~/.claude/CLAUDE.md 定义你的 AI 人格"
fi

# ---- Step 6: Cron ----
echo -e "${YELLOW}[6/6] 配置定时任务...${NC}"

# 确保 crond 运行
pgrep crond >/dev/null || crond

echo ""
echo -e "  是否安装示例 crontab？"
echo -e "  这会设置基础的早晚提醒 + 电池监控。"
echo -e "  ${YELLOW}注意：会覆盖你现有的 crontab。${NC}"
echo ""
read -p "  安装示例 crontab? [y/N] " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  # 用实际路径替换模板中的 ~
  sed "s|~/scripts/|$SCRIPT_DIR/|g" "$REPO_DIR/templates/crontab.example" | crontab -
  echo -e "  ${GREEN}✓${NC} Crontab 已安装"
  echo -e "  ${YELLOW}!${NC} 用 'crontab -l' 查看, 'crontab -e' 编辑"
else
  echo -e "  ${YELLOW}→${NC} 跳过。你可以之后手动安装："
  echo -e "    crontab < $REPO_DIR/templates/crontab.example"
fi

# ---- 完成 ----
echo ""
echo -e "${GREEN}${BOLD}安装完成！${NC}"
echo ""
echo -e "  脚本目录: ${BOLD}$SCRIPT_DIR/${NC}"
echo -e "  AI 人格:  ${BOLD}~/.claude/CLAUDE.md${NC}"
echo -e "  日志文件: ${BOLD}~/lifecoach.log${NC}"
echo ""
echo -e "${BOLD}下一步：${NC}"
echo -e "  1. 设置 API key: ${YELLOW}export ANTHROPIC_API_KEY=\"sk-ant-xxx\"${NC}"
echo -e "     (添加到 ~/.bashrc 持久化)"
echo -e "  2. 编辑 AI 人格: ${YELLOW}nano ~/.claude/CLAUDE.md${NC}"
echo -e "  3. 测试通知:     ${YELLOW}bash $SCRIPT_DIR/claude-relay.sh \"说你好\" \"测试\" \"Hello!\"${NC}"
echo -e "  4. 编辑定时任务: ${YELLOW}crontab -e${NC}"
echo ""
echo -e "  详细教程: ${YELLOW}$REPO_DIR/docs/${NC}"
echo ""
echo -e "${BOLD}记得在系统设置中给 Termux 开启后台运行权限！${NC}"
