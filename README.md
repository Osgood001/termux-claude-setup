# Termux + Claude Code: 把 AI 装进你的口袋

> 不需要服务器，不需要 root，一部 Android 手机 = 一个 24 小时运行的 AI 助手。

你的手机不只是刷短视频的工具。装上 Termux 和 Claude Code，它就变成了一个有感知能力的智能体——能读取电池状态、发送通知、定时执行任务、甚至在凌晨检测到你还在玩手机时来骂你。

**这不是 App，是一套配置方法。** 你来定义 AI 的灵魂。

---

## 它能干什么

```
┌─────────────────────────────────────────────────────┐
│                   你的 Android 手机                    │
│                                                       │
│  ┌─────────┐    ┌──────────┐    ┌─────────────────┐  │
│  │ Termux  │───▶│  crond   │───▶│ claude-relay.sh │  │
│  │ (终端)  │    │ (定时器) │    │   (核心中继)    │  │
│  └─────────┘    └──────────┘    └────────┬────────┘  │
│                                          │            │
│                              ┌───────────┴──────┐    │
│                              ▼                   ▼    │
│                     ┌──────────────┐   ┌───────────┐ │
│                     │  Claude API  │   │ 纯Shell   │ │
│                     │  (智能回复)  │   │ (回退通知)│ │
│                     └──────┬───────┘   └─────┬─────┘ │
│                            └───────┬─────────┘       │
│                                    ▼                  │
│                          ┌─────────────────┐         │
│                          │ termux-notification │      │
│                          │   (手机通知栏)    │         │
│                          └─────────────────┘         │
│                                                       │
│  传感器能力：电池 │ 温度 │ GPS │ 光线 │ 震动 │ TTS   │
└─────────────────────────────────────────────────────┘
```

| 场景 | 说明 |
|------|------|
| **早间规划** | 每天早上推送通知，帮你规划今天要做的事 |
| **深夜守护** | 检测到凌晨还在玩手机？AI 发通知提醒你睡觉 |
| **新闻/论文推送** | 自动抓取 HN/arXiv，生成中文摘要发到通知栏 |
| **社交关系管理** | 追踪你上次联系朋友的时间，超时提醒 |
| **电量温度监控** | 电量低、温度高时自动告警 |
| **呼吸/运动提醒** | 定时提醒做呼吸练习、颈椎运动 |
| **自动日报/周报** | 每天自动生成当日总结，每周汇总 |
| **API 健康检查** | 监控你常用 API 的可用性 |
| **任何你能想到的** | Claude Code + cron + termux-api = 无限可能 |

---

## 快速开始

### 1. 安装 Termux 环境

```bash
# 从 F-Droid 安装 Termux 和 Termux:API（不要用 Play Store 版本）
# https://f-droid.org/packages/com.termux/
# https://f-droid.org/packages/com.termux.api/

# 安装基础包
pkg update && pkg upgrade -y
pkg install -y git nodejs python cronie termux-api

# 启动 cron 服务
crond
```

### 2. 安装 Claude Code

```bash
npm install -g @anthropic-ai/claude-code

# 修复 /tmp 权限问题（Termux 特有）
pkg install -y proot
# 之后用 proot 启动 Claude Code：
proot -b $TMPDIR:/tmp claude
# 或者安装 termux-chroot 包
```

### 3. 定义你的 AI

```bash
# 克隆本仓库
git clone https://github.com/Osgood001/termux-claude-setup.git
cd termux-claude-setup

# 运行安装脚本
bash install.sh

# 编辑 AI 人格配置
nano ~/.claude/CLAUDE.md
```

**就这样，你的口袋 AI 开始工作了。**

---

## 核心概念

### 1. Claude-Relay 模式

这是整个系统的核心创新。所有定时任务都通过 `claude-relay.sh` 执行：

```
尝试调用 Claude API（智能回复）
        │
        ├── 成功 → 用 AI 生成的内容发通知
        │
        └── 失败 → 用预设的静态文案发通知（永远不会错过提醒）
```

**为什么需要这个？** API 可能超时、断网、欠费——但你的提醒不能断。relay 模式保证了 100% 的通知送达率，只是「智能程度」会降级。

→ 详见 [claude-relay 模式详解](docs/03-relay-pattern.md)

### 2. CLAUDE.md 人格系统

Claude Code 会读取 `~/.claude/CLAUDE.md` 作为系统指令。这就是你的 AI 的「灵魂文件」——你在里面定义：

- **它是谁**：助手？教练？管家？毒舌损友？
- **你是谁**：你的职业、习惯、偏好
- **交互风格**：温柔体贴 or 坚定直接 or 犀利毒舌
- **主动干预规则**：什么时候它应该主动找你
- **自定义指令**：你的专属快捷命令

→ 详见 [CLAUDE.md 人格配置指南](docs/06-soul-config.md)

### 3. Cron 定时任务

用 cronie 调度所有自动化任务。一个典型的配置可能长这样：

```cron
TZ=Asia/Shanghai

# 早间规划
3 8 * * * ~/scripts/morning-coach.sh

# 午后检查
7 14 * * * ~/scripts/afternoon-check.sh

# 晚间复盘
3 22 * * * ~/scripts/evening-review.sh

# 电池监控（每2小时）
11 */2 * * * ~/scripts/battery-monitor.sh

# 深夜亮屏检测（守护进程保活）
*/30 * * * * ~/scripts/start-screen-monitor.sh

# ...更多任务
```

→ 详见 [cron 定时任务体系](docs/04-cron-system.md)

### 4. Termux-API 传感器

Termux:API 让你的脚本能访问手机硬件：

| API | 用途 |
|-----|------|
| `termux-notification` | 发送通知到通知栏 |
| `termux-vibrate` | 震动 |
| `termux-tts-speak` | 文字转语音 |
| `termux-battery-status` | 电池状态（电量/温度/电流） |
| `termux-location` | GPS 定位 |
| `termux-toast` | 屏幕浮动提示 |
| `termux-clipboard-set` | 写入剪贴板 |
| `termux-camera-photo` | 拍照 |

→ 详见 [termux-api 通知与传感器](docs/05-notifications.md)

---

## 进阶玩法

### 深夜亮屏检测（不需要 root）

Android 不允许非 root 应用直接读取屏幕状态。但我们发现了一个 hack：

**通过电池放电电流判断屏幕是否亮着。**

- 屏幕亮：放电电流 > 150mA
- 屏幕灭：放电电流 < 100mA

凌晨连续检测 5 分钟屏幕亮着 → 发通知提醒睡觉。

→ 详见 [进阶玩法](docs/07-advanced.md)

### 自动日报/周报

每天 23:30 自动收集当天的日志、电池数据、任务完成情况，让 Claude 生成一份 markdown 日报。每周日汇总成周报。全部 git 版本管理。

### 数据追踪系统

用 JSON 文件追踪你想追踪的任何东西——社交关系、健康状态、任务进度、决策记录。脚本定期读取并生成智能提醒。

---

## 详细教程

| # | 文档 | 内容 |
|---|------|------|
| 01 | [Termux 环境搭建](docs/01-termux-setup.md) | 安装、权限、基础包、/tmp 修复 |
| 02 | [Claude Code 安装](docs/02-claude-code.md) | 安装、API key、proot 配置 |
| 03 | [Claude-Relay 模式](docs/03-relay-pattern.md) | 核心中继脚本详解 |
| 04 | [Cron 定时任务](docs/04-cron-system.md) | cronie 安装、任务编排、时间规划 |
| 05 | [通知与传感器](docs/05-notifications.md) | termux-api 全套能力 |
| 06 | [人格配置指南](docs/06-soul-config.md) | CLAUDE.md 调教方法 |
| 07 | [进阶玩法](docs/07-advanced.md) | 屏幕检测、日报、数据追踪 |
| 08 | [踩坑指南](docs/08-faq.md) | 常见问题与解决方案 |

---

## 示例脚本

`examples/` 目录下有完整的示例脚本，可直接复制使用：

```
examples/
├── claude-relay.sh       # 核心中继（必装）
├── morning-coach.sh      # 早间规划提醒
├── battery-monitor.sh    # 电池温度监控
├── breathe-remind.sh     # 呼吸练习提醒
├── screen-monitor.sh     # 深夜亮屏检测
├── news-digest.sh        # 新闻摘要推送
├── social-reminder.sh    # 社交关系提醒
├── daily-report.sh       # 自动日报生成
└── api-health.sh         # API 健康检查
```

---

## 环境要求

- Android 7.0+（推荐 Android 10+）
- [Termux](https://f-droid.org/packages/com.termux/)（从 F-Droid 安装）
- [Termux:API](https://f-droid.org/packages/com.termux.api/)（从 F-Droid 安装）
- Claude API key（[获取](https://console.anthropic.com/)）
- 不需要 root

## 已测试设备

- vivo (Android 16)
- 理论上支持所有能运行 Termux 的 Android 设备

---

## FAQ

**Q: 耗电吗？**
A: cron 任务按需唤醒，不常驻内存。实测每天额外耗电 < 3%。屏幕监控守护进程稍多一些但也在可接受范围。

**Q: 需要一直联网吗？**
A: claude-relay 模式在断网时自动降级为纯本地通知，不会错过任何提醒。联网时才调用 API 生成智能内容。

**Q: 和 ChatGPT App 有什么区别？**
A: ChatGPT App 是你去找它聊天。这个系统是 **AI 主动找你**——它有 cron 任务在后台跑，能感知你的手机状态，在合适的时间主动推送通知。它不是一个 App，是一个 agent。

**Q: Claude Code 收费吗？**
A: Claude Code 需要 Anthropic API key，按用量收费。纯通知回退模式不消耗 API 额度。合理配置 cron 频率后，月费用通常 < $5。

**Q: Termux 会被系统杀掉吗？**
A: 在系统设置中给 Termux 开启「后台运行」和「自启动」权限。不同品牌手机设置方式不同，详见 [踩坑指南](docs/08-faq.md)。

---

## Star 一下？

如果这个项目对你有用，点个 Star 让更多人看到。

有问题或建议？欢迎开 Issue。

---

## License

MIT
