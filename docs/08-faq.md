# 08 — 踩坑指南 & FAQ

在 Termux 上跑 Claude Code 会踩不少坑。以下是实际踩过的。

## /tmp 权限问题

**现象**：Claude Code 启动报错 `EACCES: permission denied, mkdir '/tmp/...'`

**原因**：Android 禁止 Termux 写入系统 `/tmp`

**解决**：

```bash
# 方案 A：proot 映射（推荐）
proot -b $TMPDIR:/tmp claude

# 方案 B：termux-chroot
termux-chroot
claude

# 建议写成 alias
echo 'alias claude="proot -b \$TMPDIR:/tmp claude"' >> ~/.bashrc
```

## Termux:API 超时无响应

**现象**：`termux-battery-status`、`termux-notification` 等命令执行后一直卡住

**原因**：Termux:API Android 应用没有运行

**解决**：
1. 确保从 F-Droid 安装了 Termux:API app
2. **手动打开一次** Termux:API app
3. 在系统设置中给 Termux:API 授权通知权限

验证：

```bash
# 应该在 1-2 秒内返回结果
timeout 5 termux-battery-status
```

## Cron 任务不执行

**排查清单**：

```bash
# 1. crond 是否在运行？
pgrep crond || crond

# 2. 脚本是否有执行权限？
chmod +x ~/scripts/*.sh

# 3. shebang 是否正确？
# 应该是: #!/data/data/com.termux/files/usr/bin/bash
# 不是:   #!/bin/bash（Termux 里不存在）

# 4. 手动执行是否有错？
bash ~/scripts/morning-coach.sh

# 5. PATH 是否可用？
# 在脚本开头加：
export PATH="/data/data/com.termux/files/usr/bin:$PATH"
```

## Termux 被系统杀死

**现象**：过一段时间发现 cron 任务没执行，Termux 被后台清理了

**解决**：

1. **关闭电池优化**：系统设置 → 电池 → Termux → 不限制
2. **允许自启动**：应用管理 → Termux → 自启动 → 开启
3. **锁定任务**：最近任务列表 → Termux 卡片下拉/长按 → 锁定
4. **Termux 获取唤醒锁**：`termux-wake-lock`（在 Termux 通知栏点击 Acquire wakelock）

不同品牌的设置路径见 [01-termux-setup.md](01-termux-setup.md)。

## Claude API 调用失败

**现象**：`claude --print` 返回空或报错

**可能原因**：
1. 网络问题 → 检查网络连接
2. API key 无效 → 检查 `echo $ANTHROPIC_API_KEY`
3. 余额不足 → 检查 [console.anthropic.com](https://console.anthropic.com/)
4. 超时 → 增大 timeout 值

**这就是为什么需要 claude-relay 模式** — API 出问题时自动降级。

## Git 提交失败

**现象**：`git commit` 报错 `Author identity unknown`

**解决**：

```bash
git config --global user.email "you@example.com"
git config --global user.name "Your Name"
```

## Python 编码问题

**现象**：Python 处理中文 JSON 时报 UnicodeDecodeError

**解决**：在脚本中设置：

```bash
export PYTHONIOENCODING=utf-8
```

或在 Python 中：

```python
with open('data.json', encoding='utf-8') as f:
    data = json.load(f)
```

## 通知不显示

**排查**：

1. Termux 有通知权限？系统设置检查
2. 勿扰模式是否开启？
3. 通知频道是否被关闭？长按 Termux 通知 → 检查通知类别

## 存储空间

日志文件会越来越大。建议定期清理：

```bash
# 在 crontab 中添加日志轮转（每周清理超过 7 天的日志）
0 4 * * 0 find ~/lifecoach.log -size +10M -exec truncate -s 0 {} \;
```

## 电量消耗

| 模块 | 耗电 | 建议 |
|------|------|------|
| crond 守护进程 | 极低 | 保持 |
| 每小时 1-2 次 API 调用 | 低 | 保持 |
| 屏幕监控守护进程 | 中低 | 只在需要时开启 |
| 每 30 分钟 API 健康检查 | 低 | 可选 |

总体来说，每天额外耗电 < 5%。

## 还有问题？

- 开 Issue：[GitHub Issues](https://github.com/Osgood001/termux-claude-setup/issues)
- Termux Wiki：[wiki.termux.com](https://wiki.termux.com/)
- Claude Code 文档：[docs.anthropic.com](https://docs.anthropic.com/)
