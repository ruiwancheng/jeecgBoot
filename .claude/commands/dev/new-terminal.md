---
description: 自有命令 — 开启新会话：在当前终端上下文膨胀时，一键生成记忆卡片 + 打开新终端作为控制中心。自动检测当前 agent 类型（claude/pi/codex）并创建对应类型的新终端。
---

# /new-terminal

上下文膨胀时，打开一个同类型新终端作为控制中心。带齐所有规则和状态，但没有历史噪音。

## 与 /delegate 的区别

| | /delegate | /new-terminal |
|------|:--:|:--:|
| 用途 | 派一个具体任务给工人 | 新终端自动续接当前工作 |
| 终端 | 工人干完自动销毁 | 长期存活 |
| 卡片 | 卡片+工作流+任务 | 卡片+恢复指令+自动继续 |

## 流程

### 0. 自检测当前 agent 类型

```bash
# agent 是 shell 的子进程，$$ 是 shell 自身，shell 的父进程才是 agent
AGENT=$(ps -p $(ps -p $$ -o ppid=) -o comm= 2>/dev/null)
```

根据 `$AGENT` 确定要创建的终端类型：

| 祖父进程（AGENT） | 创建命令 |
|------------------|---------|
| `Claude` | `orca terminal create --worktree active --command "claude" --json` |
| `pi` | `orca terminal create --worktree active --command "pi" --json` |
| `codex` | `orca terminal create --worktree active --command "codex" --json` |
| 其他 | 提示用户手动开终端 |

> **注意**：`ps -p $$ -o comm=` 返回的是 `/bin/zsh`（shell），不是 agent。必须查父进程的父进程（祖父进程）才能拿到 agent 名称。

### 1. 生成记忆卡片

运行 `/cleanup-context` 生成记忆卡片（含会话上下文——最重要的增量信息）。
**卡片质量门控：** "下一步"必须含具体文件路径或接口路径，不满足则重写再输出。

### 2. 创建新终端

```bash
orca terminal create --worktree active --command "<agent>" --json
```

### 3. 等待就绪

```bash
orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 120000 --json
```

### 4. 注入记忆卡片

```
orca terminal send --terminal <handle> --text "<卡片内容 + 恢复指令>" --enter --json
```

### 5. 发送执行信号

```
orca terminal send --terminal <handle> --text "执行上述卡片中'下一步'的动作。直接操作，不要复述、不要问问题。" --enter --json
```

### 6. 提示用户

"新控制中心已就绪：切换到 `<handle>` 继续工作"

---

## 注入内容格式（terminal send 发送的完整文本）

```
## 🤖 你是上一个会话的延续

上下文已重置，无历史噪音。消化以下记忆卡片后 **立即执行"下一步"中的动作**。

**硬约束：**
- 直接动手操作（read文件、edit代码、跑命令）
- 禁止回复"收到卡片""明白了"等确认性摘要
- 禁止问"需要我做什么"——卡片中"下一步"已写明
- implement/verify 阶段必须执行到编译/curl验证
- brainstorm/plan 阶段继续分析，不跳到写代码

<记忆卡片——含当前会话上下文+关键提醒+项目状态>

---
执行卡片中"下一步"的动作。直接操作。
```

---

## 使用示例

```
用户（在当前膨胀终端里）：/new-terminal
AI：🔍 自检测当前 agent: claude
    📋 生成记忆卡片... ✅（下一步含具体文件路径）
    🚀 创建 claude 新终端 term_xxx ✅
    ⏳ 等待就绪... ✅
    📤 注入记忆卡片 ✅
    ⚡ 发送执行信号 ✅

    ✅ 新控制中心已就绪：切换到 term_xxx 继续工作
```

---

## 降级

- Orca 不可用 → 退化为 `/cleanup-context` + 提示用户手动开终端粘贴记忆卡片
- 未知 agent 类型 → 提示"无法识别当前 agent，请在目标终端手动执行以下操作"
