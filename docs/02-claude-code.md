# 02 — Claude Code 安装与配置

## 安装 Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

## API Key 配置

你需要一个 Anthropic API key：

1. 访问 [console.anthropic.com](https://console.anthropic.com/)
2. 创建 API key
3. 设置环境变量：

```bash
# 添加到 ~/.bashrc 或 ~/.zshrc
echo 'export ANTHROPIC_API_KEY="sk-ant-xxxxx"' >> ~/.bashrc
source ~/.bashrc
```

## 启动 Claude Code

由于 Termux 的 /tmp 限制，需要通过 proot 启动：

```bash
# 交互模式
proot -b $TMPDIR:/tmp claude

# 单次执行（用于脚本）
proot -b $TMPDIR:/tmp claude --print "your prompt here"

# 或者先进入 chroot 环境
termux-chroot
claude
```

### 创建启动别名（推荐）

```bash
echo 'alias claude="proot -b \$TMPDIR:/tmp claude"' >> ~/.bashrc
source ~/.bashrc

# 之后直接用
claude
claude --print "hello"
```

## 配置 CLAUDE.md

Claude Code 会读取 `~/.claude/CLAUDE.md` 作为全局系统指令：

```bash
mkdir -p ~/.claude
cp templates/CLAUDE.md ~/.claude/CLAUDE.md
nano ~/.claude/CLAUDE.md  # 编辑你的 AI 人格
```

这个文件决定了 Claude 在**所有对话**中的行为方式。详见 [人格配置指南](06-soul-config.md)。

## 项目级配置

除了全局 `~/.claude/CLAUDE.md`，你还可以在任何目录下创建项目级 `CLAUDE.md`：

```bash
# 比如在你的工作目录
cd ~/my-project
echo "# 这个项目的专属指令" > CLAUDE.md
```

项目级配置会叠加在全局配置之上。

## 验证

```bash
# 测试 Claude 是否能正常响应
claude --print "说一句话证明你活着"

# 测试超时机制（用于脚本）
timeout 30 claude --print "hello" && echo "OK" || echo "TIMEOUT"
```

## 费用控制

Claude Code 按 API 用量收费。控制费用的几个技巧：

1. **合理设置 cron 频率**：不需要每分钟调用，大多数场景每小时甚至每天一次就够
2. **使用 claude-relay 模式**：API 失败时回退到免费的纯 shell 通知
3. **Prompt 要简洁**：短 prompt + 限制输出字数 = 更少 token
4. **timeout 设置**：避免 API 卡住导致不必要的费用

合理配置后，月费用通常 < $5。

→ 下一步：[Claude-Relay 模式](03-relay-pattern.md)
