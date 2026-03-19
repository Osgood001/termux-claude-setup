# 05 — Termux-API 通知与传感器

Termux:API 让你的 shell 脚本能访问 Android 手机的硬件能力。这是整个系统的「身体」。

## 安装

确保安装了两部分：
1. **Termux 包**：`pkg install termux-api`
2. **Android App**：从 F-Droid 安装 Termux:API app，**并至少打开一次**

## 通知 — termux-notification

这是最核心的输出方式。所有 AI 推送都通过它。

```bash
# 基础通知
termux-notification --title "标题" --content "内容"

# 完整参数
termux-notification \
  --title "标题" \
  --content "通知内容（支持较长文本）" \
  --id "unique-id" \          # 相同 id 的通知会覆盖，不会叠加
  --priority "high" \          # min/low/default/high/max
  --vibrate "200,100,200" \    # 震动模式（ms）
  --led-color "FF0000" \       # LED 颜色
  --sound                       # 播放提示音
```

### 通知 ID 的妙用

设置 `--id` 后，同 ID 的通知会**替换**而不是叠加。适合频繁更新的场景：

```bash
# 这两条通知只会显示最后一条
termux-notification --title "Status" --content "Checking..." --id status
sleep 5
termux-notification --title "Status" --content "All good!" --id status
```

## 震动 — termux-vibrate

```bash
# 震动 500ms
termux-vibrate -d 500

# 短震
termux-vibrate -d 100
```

## 语音 — termux-tts-speak

```bash
# 文字转语音
termux-tts-speak "Good morning, time to start your day"

# 中文
termux-tts-speak "早上好，新的一天开始了"
```

## Toast 提示 — termux-toast

```bash
# 屏幕上显示短暂浮动提示
termux-toast "Hello!"

# 自定义颜色
termux-toast -b white -c black "Important message"
```

## 电池状态 — termux-battery-status

```bash
termux-battery-status
# 返回 JSON:
# {
#   "health": "GOOD",
#   "percentage": 85,
#   "plugged": "UNPLUGGED",
#   "status": "DISCHARGING",
#   "temperature": 28.5,
#   "current": -234567
# }
```

**隐藏用法**：`current` 字段可以用来判断屏幕亮灭状态（详见 [进阶玩法](07-advanced.md)）。

## 剪贴板 — termux-clipboard

```bash
# 写入剪贴板
termux-clipboard-set "some text"

# 读取剪贴板
termux-clipboard-get
```

## 定位 — termux-location

```bash
# GPS 定位
termux-location
# 返回 JSON: {"latitude": ..., "longitude": ..., "altitude": ...}
```

## 其他有用的 API

| 命令 | 功能 |
|------|------|
| `termux-camera-photo -c 0 photo.jpg` | 前置摄像头拍照 |
| `termux-wifi-connectioninfo` | 当前 WiFi 信息 |
| `termux-telephony-cellinfo` | 基站信息 |
| `termux-brightness 128` | 设置屏幕亮度 |
| `termux-volume music 8` | 设置音量 |
| `termux-dialog` | 弹出对话框 |
| `termux-download` | 下载文件 |
| `termux-open-url` | 打开 URL |
| `termux-share` | 分享文件 |

## 在脚本中组合使用

```bash
#!/data/data/com.termux/files/usr/bin/bash
# 一个综合示例：检查电池 + 发通知 + 震动

BAT=$(termux-battery-status)
PCT=$(echo "$BAT" | python3 -c "import json,sys;print(json.load(sys.stdin)['percentage'])")

if [ "$PCT" -lt 20 ]; then
  termux-notification --title "Low Battery" --content "${PCT}%" --priority high
  termux-vibrate -d 500
  termux-tts-speak "Battery low, ${PCT} percent remaining"
fi
```

→ 下一步：[CLAUDE.md 人格配置指南](06-soul-config.md)
