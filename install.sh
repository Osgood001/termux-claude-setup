#!/bin/bash
# ============================================================
# Termux + Claude Code AI 助手一键安装脚本
# 支持: curl -fsSL <url> | bash
# ============================================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BLUE}"
echo "+--------------------------------------------+"
echo "|  Termux + Claude Code AI 助手一键安装       |"
echo "|  把 AI 装进你的口袋                         |"
echo "|  github.com/Osgood001/termux-claude-setup  |"
echo "+--------------------------------------------+"
echo -e "${NC}"

# ---- 检测环境 ----

detect_env() {
    if [ -d "/data/data/com.termux" ]; then
        echo "termux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif grep -q Microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "linux"
    fi
}

ENV=$(detect_env)
echo -e "${GREEN}检测到环境: ${ENV}${NC}"

if [ "$ENV" != "termux" ]; then
    echo -e "${YELLOW}[!] 本脚本针对 Termux 优化。非 Termux 环境请参考 docs/ 手动配置。${NC}"
    echo -e "${YELLOW}    继续安装基础组件...${NC}"
    echo ""
fi

# ---- Step 1: 安装基础依赖 ----

echo -e "${BLUE}[1/5] 安装基础依赖...${NC}"

check_and_install() {
    local cmd="$1"
    local pkg="$2"
    if command -v "$cmd" &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} $pkg"
    else
        echo -e "  ${YELLOW}→${NC} 安装 $pkg..."
        if [ "$ENV" = "termux" ]; then
            pkg install -y "$pkg" 2>/dev/null
        elif [ "$ENV" = "macos" ]; then
            brew install "$pkg" 2>/dev/null || true
        else
            sudo apt-get install -y "$pkg" 2>/dev/null || true
        fi
    fi
}

if [ "$ENV" = "termux" ]; then
    pkg update -y 2>/dev/null
    check_and_install git git
    check_and_install node nodejs
    check_and_install python3 python
    check_and_install crond cronie
    check_and_install curl curl
    check_and_install proot proot
    check_and_install termux-notification termux-api
    pip install requests -q 2>/dev/null && echo -e "  ${GREEN}✓${NC} python-requests"
else
    # 非 Termux：检查 Node.js，不够就用 nvm 装
    install_node_via_nvm() {
        echo -e "  ${YELLOW}→${NC} 使用 nvm 安装 Node.js（无需 sudo）..."
        export NVM_DIR="$HOME/.nvm"
        if [ ! -d "$NVM_DIR" ]; then
            echo -e "  ${YELLOW}→${NC} 安装 nvm（Gitee 镜像）..."
            curl -fsSL https://gitee.com/mirrors/nvm/raw/v0.40.1/install.sh | bash || true
        fi
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        if ! command -v nvm &>/dev/null; then
            echo -e "  ${RED}✗${NC} nvm 安装失败"
            return 1
        fi
        export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
        echo -e "  ${YELLOW}→${NC} 通过国内镜像安装 Node.js v20..."
        nvm install 20
        nvm use 20
        nvm alias default 20
        echo -e "  ${GREEN}✓${NC} Node.js $(node -v) 安装完成"
    }

    if command -v node &>/dev/null; then
        NODE_VER=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VER" -ge 18 ]; then
            echo -e "  ${GREEN}✓${NC} Node.js $(node -v)"
        else
            echo -e "  ${YELLOW}[!] Node.js 版本过低 ($(node -v)，需要 v18+)${NC}"
            install_node_via_nvm
        fi
    else
        echo -e "  ${YELLOW}[!] 未检测到 Node.js${NC}"
        if [ "$ENV" = "macos" ] && command -v brew &>/dev/null; then
            echo -e "  ${YELLOW}→${NC} 通过 Homebrew 安装 Node.js..."
            brew install node
        else
            install_node_via_nvm
        fi
    fi
fi

# ---- Step 2: 安装 Claude Code ----

echo -e "${BLUE}[2/5] 安装 Claude Code...${NC}"

# 配置 npm 国内镜像加速
echo -e "  ${YELLOW}→${NC} 配置 npm 国内镜像加速..."
npm config set registry https://registry.npmmirror.com
echo -e "  ${GREEN}✓${NC} 已切换到淘宝 npm 镜像"

if command -v claude &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} Claude Code 已安装 ($(claude --version 2>/dev/null || echo '?'))"
else
    echo -e "  ${YELLOW}→${NC} 安装 Claude Code..."
    npm install -g @anthropic-ai/claude-code
    echo -e "  ${GREEN}✓${NC} Claude Code 安装完成"
fi

# Termux: 设置 proot alias 解决 /tmp 问题
if [ "$ENV" = "termux" ]; then
    if ! grep -q 'proot.*claude' ~/.bashrc 2>/dev/null; then
        echo '' >> ~/.bashrc
        echo '# Claude Code (proot wrap for /tmp)' >> ~/.bashrc
        echo 'alias claude="proot -b \$TMPDIR:/tmp claude"' >> ~/.bashrc
        echo -e "  ${GREEN}✓${NC} 已添加 proot alias (修复 Termux /tmp 问题)"
    fi
fi

# ---- Step 3: 配置 API ----

echo -e "${BLUE}[3/5] 配置 API...${NC}"
echo ""
echo -e "  你有两种方式使用 Claude API："
echo ""
echo -e "  ${BOLD}[1] Anthropic 官方${NC} — console.anthropic.com"
echo -e "  ${BOLD}[2] LuckyAPI 代理${NC} — cn.luckyapi.chat (官方价格 6%，国内直连)"
echo ""
read -p "  选择 API 来源 [1/2/跳过直接回车]: " API_CHOICE < /dev/tty
echo ""

# 检测 shell 配置文件
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
else
    SHELL_RC="$HOME/.bashrc"
    touch "$SHELL_RC"
fi

case "$API_CHOICE" in
    1)
        echo -e "  ${YELLOW}请输入 Anthropic 官方 API Key:${NC}"
        read -p "  API Key (sk-ant-xxx): " API_KEY < /dev/tty
        if [ -n "$API_KEY" ]; then
            echo '' >> "$SHELL_RC"
            echo '# Claude Code API (Anthropic Official)' >> "$SHELL_RC"
            echo "export ANTHROPIC_API_KEY=\"$API_KEY\"" >> "$SHELL_RC"
            echo -e "  ${GREEN}✓${NC} API Key 已写入 $SHELL_RC"
        fi
        ;;
    2)
        echo -e "  获取 Key: ${BLUE}https://cn.luckyapi.chat${NC}"
        echo ""
        read -p "  LuckyAPI Key (sk-xxx): " API_KEY < /dev/tty
        if [ -n "$API_KEY" ]; then
            echo '' >> "$SHELL_RC"
            echo '# Claude Code API (LuckyAPI Proxy - cn.luckyapi.chat)' >> "$SHELL_RC"
            echo "export ANTHROPIC_BASE_URL=\"https://cn.luckyapi.chat\"" >> "$SHELL_RC"
            echo "export ANTHROPIC_AUTH_TOKEN=\"$API_KEY\"" >> "$SHELL_RC"
            echo "export ANTHROPIC_API_KEY=\"\"" >> "$SHELL_RC"
            echo -e "  ${GREEN}✓${NC} LuckyAPI 配置已写入 $SHELL_RC"
            echo -e "  ${GREEN}✓${NC} 已设置国内代理，无需科学上网"
        fi
        ;;
    *)
        echo -e "  ${YELLOW}→${NC} 跳过 API 配置。稍后手动设置："
        echo -e "    官方: export ANTHROPIC_API_KEY=\"sk-ant-xxx\""
        echo -e "    代理: export ANTHROPIC_BASE_URL=\"https://cn.luckyapi.chat\""
        ;;
esac

# ---- Step 4: 下载脚本 & 模板 ----

echo -e "${BLUE}[4/5] 配置 AI 助手脚本...${NC}"

REPO_URL="https://github.com/Osgood001/termux-claude-setup.git"
REPO_DIR="$HOME/termux-claude-setup"
SCRIPT_DIR="$HOME/scripts"

# 如果不是从仓库目录运行的，先克隆
if [ ! -d "$REPO_DIR/examples" ]; then
    SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"
    if [ -d "$SELF_DIR/examples" ]; then
        REPO_DIR="$SELF_DIR"
    else
        echo -e "  ${YELLOW}→${NC} 下载脚本模板..."
        git clone --depth 1 "$REPO_URL" "$REPO_DIR" 2>/dev/null || {
            # SSH fallback
            git clone --depth 1 "git@github.com:Osgood001/termux-claude-setup.git" "$REPO_DIR" 2>/dev/null || {
                echo -e "  ${RED}✗${NC} 下载失败，请手动 clone："
                echo -e "    git clone $REPO_URL"
                echo -e "    cd termux-claude-setup && bash install.sh"
                exit 1
            }
        }
    fi
fi

mkdir -p "$SCRIPT_DIR"

# 复制脚本
for script in "$REPO_DIR"/examples/*.sh; do
    [ -f "$script" ] || continue
    BASENAME=$(basename "$script")
    cp "$script" "$SCRIPT_DIR/$BASENAME"
    chmod +x "$SCRIPT_DIR/$BASENAME"
    echo -e "  ${GREEN}✓${NC} $BASENAME"
done

# 修正路径引用
sed -i "s|\~/scripts/|$SCRIPT_DIR/|g" "$SCRIPT_DIR/start-screen-monitor.sh" 2>/dev/null
sed -i "s|\~/claude-relay.sh|$SCRIPT_DIR/claude-relay.sh|g" "$SCRIPT_DIR/morning-coach.sh" 2>/dev/null

# CLAUDE.md 人格模板
mkdir -p ~/.claude
if [ -f ~/.claude/CLAUDE.md ]; then
    echo -e "  ${YELLOW}!${NC} ~/.claude/CLAUDE.md 已存在 (保留不覆盖)"
else
    cp "$REPO_DIR/templates/CLAUDE.md" ~/.claude/CLAUDE.md
    echo -e "  ${GREEN}✓${NC} AI 人格模板 → ~/.claude/CLAUDE.md"
fi

# 数据模板目录
mkdir -p ~/data
for tmpl in "$REPO_DIR"/templates/data/*.json; do
    [ -f "$tmpl" ] || continue
    BASENAME=$(basename "$tmpl")
    TARGET="$HOME/data/${BASENAME%.example.json}.json"
    if [ ! -f "$TARGET" ]; then
        cp "$tmpl" "$TARGET"
        echo -e "  ${GREEN}✓${NC} $BASENAME → ~/data/"
    fi
done

# ---- Step 5: 配置 Cron ----

echo -e "${BLUE}[5/5] 配置定时任务...${NC}"

if [ "$ENV" = "termux" ]; then
    pgrep crond >/dev/null 2>&1 || crond
    if ! grep -q 'crond' ~/.bashrc 2>/dev/null; then
        echo 'pgrep crond >/dev/null 2>&1 || crond' >> ~/.bashrc
    fi

    echo ""
    echo -e "  是否安装示例 crontab？(早晚提醒 + 电池监控 + 呼吸练习)"
    echo -e "  ${YELLOW}注意：会覆盖现有 crontab${NC}"
    echo ""
    read -p "  安装? [y/N] " -n 1 -r < /dev/tty
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sed "s|~/scripts/|$SCRIPT_DIR/|g" "$REPO_DIR/templates/crontab.example" | crontab -
        echo -e "  ${GREEN}✓${NC} Crontab 已安装 (crontab -l 查看)"
    else
        echo -e "  ${YELLOW}→${NC} 跳过。稍后: crontab -e"
    fi
else
    echo -e "  ${YELLOW}→${NC} 非 Termux 环境，跳过 cron 配置"
fi

# ---- 完成 ----

echo ""
echo -e "${GREEN}+--------------------------------------------+${NC}"
echo -e "${GREEN}|  ${BOLD}安装完成！${NC}${GREEN}                               |${NC}"
echo -e "${GREEN}+--------------------------------------------+${NC}"
echo ""
echo -e "  运行 ${BLUE}claude${NC} 启动 Claude Code"
echo ""
echo -e "  ${BOLD}文件位置:${NC}"
echo -e "    脚本:    ${BLUE}$SCRIPT_DIR/${NC}"
echo -e "    AI 人格: ${BLUE}~/.claude/CLAUDE.md${NC}"
echo -e "    数据:    ${BLUE}~/data/${NC}"
echo -e "    教程:    ${BLUE}$REPO_DIR/docs/${NC}"
echo ""
echo -e "  ${BOLD}下一步:${NC}"
echo -e "    1. ${YELLOW}source $SHELL_RC${NC}  ← 使配置生效"
echo -e "    2. ${YELLOW}nano ~/.claude/CLAUDE.md${NC}  ← 定义 AI 人格"
echo -e "    3. ${YELLOW}claude${NC}  ← 开始对话"
echo -e "    4. ${YELLOW}crontab -e${NC}  ← 自定义定时任务"
echo ""
echo -e "  ${BOLD}提示:${NC}"
echo -e "    按 ${BLUE}Shift+Tab${NC} 可在 Claude Code 中切换权限模式"

if [ "$ENV" = "termux" ]; then
echo -e "    ${RED}记得在系统设置中给 Termux 开启后台运行权限！${NC}"
fi

echo ""
echo -e "  ${BOLD}链接:${NC}"
echo -e "    获取 API Key: ${BLUE}https://cn.luckyapi.chat${NC} (官方价格 6%)"
echo -e "    使用教程:     ${BLUE}https://github.com/Osgood001/termux-claude-setup${NC}"
echo ""
