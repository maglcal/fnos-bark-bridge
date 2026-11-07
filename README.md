# fnos-bark-bridge

把飞牛OS（fnOS）的系统通知转发到 iPhone 的 [Bark](https://github.com/Finb/bark) 推送。

利用 fnOS 1.2.1000+ 内置的「系统通知 → Webhook 机器人」（选**「其他机器人」**类型）作为通知来源，经本桥接服务解析后推送到任意 Bark 服务器（自建或官方）。

不读取 fnOS 数据库、不挂载系统目录、不需要 SSH——全部走官方 Webhook 配置界面，系统升级不受影响。

## 特性

- **零依赖**：纯 Python 标准库，单文件（~10KB），基于 `python:3.12-alpine`，镜像轻量
- **多格式解析**：fnOS 通用格式 / 企业微信（text、markdown）/ 钉钉（text、markdown）/ 飞书（text、markdown、post、interactive 卡片）payload 自动识别
- **令牌鉴权**：`/hook/<token>` 路径、`?token=` 查询、`X-Bark-Token` 请求头三种传法
- **DRY_RUN 调试模式**：只打印不推送，便于验证 payload 解析
- **markdown 清理**：自动剥离 `**`、`__`、反引号、`#`、`>` 等标记，推送纯文本

## 快速开始

```yaml
# docker-compose.yml
services:
  fnos-bark-bridge:
    image: maglcal/fnos-bark-bridge:1.0.1      # 推荐固定版本号；latest 跟随最新发布
    container_name: fnos-bark-bridge
    restart: unless-stopped
    ports:
      - "8081:8081"
    environment:
      - BARK_SERVER=https://api.day.app        # Bark 服务器（官方公共；自建 bark-server 亦可）
      - BARK_KEY=your-device-key               # Bark 设备 Key
      - BARK_GROUP=飞牛NAS                     # 通知分组（可选）
      - BARK_LEVEL=timeSensitive               # passive/active/timeSensitive/critical（可选）
      - BARK_ICON=https://example.com/icon.png # 推送图标，需公网可达（可选）
      - TOKEN=change-me                        # Webhook 令牌（可选但强烈建议）
      - DEFAULT_TITLE=飞牛NAS通知              # 标题兜底（可选）
```

fnOS 侧配置：**系统设置 → 系统通知 → 通知设置 → 新增 Webhook 机器人**，类型选**「其他机器人」**，地址填：

```
http://<NAS内网IP>:8081/hook/<TOKEN>
```

## fnOS 侧配置要点（踩坑必读）

- **令牌必须拼在 URL 路径里**（`/hook/<TOKEN>`）。fnOS 弹窗里的**「密钥」字段是给钉钉/飞书/企业微信加签用的，本服务不需要填**——如果只把令牌填进「密钥」而 URL 用 `/hook/`，点「测试发送」会报「测试消息发送失败」（服务端实际返回 401）。
- **端口可自定义**：如宿主机想用 9932，compose 写 `9932:8081`，Webhook 地址相应写 `http://<NAS内网IP>:9932/hook/<TOKEN>`。
- **测试失败排查**：① `curl http://<NAS内网IP>:<端口>/health` 确认服务在线；② `curl -X POST "http://<NAS内网IP>:<端口>/hook/<TOKEN>" -d '{}'` 确认令牌正确；③ 确认地址是 `http://` 而非 `https://`（本服务是纯 HTTP，用 https 会在日志里看到 TLS 垃圾字节和 400）。
- 机器人配好后，还要在 **告警类型** 勾选推送项、**推送规则** 里把机器人选为接收对象，系统告警才会真正推送。

## 环境变量

| 变量 | 必填 | 说明 |
|---|---|---|
| `BARK_SERVER` | 是 | Bark 服务器地址，如 `https://api.day.app`（官方公共服务器） |
| `BARK_KEY` | 是 | Bark 设备 Key |
| `BARK_GROUP` | 否 | 通知分组 |
| `BARK_SOUND` | 否 | 铃声，如 `birdsong` |
| `BARK_LEVEL` | 否 | 推送等级 |
| `BARK_ICON` | 否 | 图标 URL（iPhone 端拉取，必须公网可达） |
| `TOKEN` | 否 | Webhook 鉴权令牌 |
| `DEFAULT_TITLE` | 否 | payload 无标题时的兜底标题 |
| `PORT` | 否 | 监听端口，默认 8081 |
| `DRY_RUN` | 否 | `1` 开启调试模式 |

## 关于推送图标的小知识

Bark 的 `icon` 在 iOS 端会作为 `INSendMessageIntent` 的发件人头像渲染，**iOS 会把它圆形裁切**。如果你的图标主体顶满画布四角（比如带角的 logo），圆裁会切掉边角。解决办法：把图标放进一个带 ~18% 边距的正方形画布再使用。

## 版本历史

- **1.0.1**：修复二进制探测流量（TLS 握手等）造成的日志乱码（不可打印字符统一转义）；兼容 `HEAD` 探测（原 501 改为正常应答）
- **1.0**：首个版本

## 许可证

[MIT](LICENSE) © 2026 许诺

> 飞牛OS / fnOS 为飞牛公司的商标，Bark 为 Finb 的项目。本项目与其均为非官方合作关系，商标归各自所有者。

> 很庆幸曾经遇见你，遗憾的是只是遇见你——许诺
