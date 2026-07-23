---
description: 自有命令 — 开启新会话：在当前终端上下文膨胀时，一键生成记忆卡片 + 打开同类型 AI 新终端作为控制中心（Claude 调起 Claude，pi 调起 pi）
---

# /new-terminal

上下文膨胀时，打开一个同类型 AI 的新终端作为控制中心——Claude 调用就新建 Claude 终端，pi 调用就新建 pi 终端。带齐所有规则和状态，但没有历史噪音。

## 与 /delegate 的区别

| | /delegate | /new-terminal |
|------|:--:|:--:|
| 用途 | 派一个具体任务给工人 | 新终端自动续接当前工作 |
| 终端 | 工人干完自动销毁 | 长期存活 |
| 卡片 | 卡片+工作流+任务 | 卡片+恢复指令+自动继续 |

## 流程

1. 运行 `/cleanup-context` 生成记忆卡片（含会话上下文——最重要的增量信息）
   - **卡片质量门控：** "下一步"必须含具体文件路径或接口路径，不满足则重写再输出
2. **自检测调用者身份**，创建同类型 AI 终端：
	   - 你是 Claude → `orca terminal create --worktree active --command "claude" --json`
	   - 你是 pi (Codex) → `orca terminal create --worktree active --command "pi" --json`
	   - 判断方法：检查系统提示中是否含 "Claude" 品牌标识，有则为 Claude；含 "Codex"/"pi" 则为 pi
3. 等待终端就绪：`orca terminal wait --terminal <handle> --for tui-idle --timeout-ms 120000 --json`
4. 用 `orca terminal send` 把记忆卡片 + 执行指令发送给新终端：
   ```
   orca terminal send --terminal <handle> --text "<卡片内容 + 恢复指令>" --enter --json
   ```
5. 紧跟发送一条"执行信号"，强制 agent 立即动手：
   ```
   orca terminal send --terminal <handle> --text "执行上述卡片中'下一步'的动作。直接操作，不要复述、不要问问题。" --enter --json
   ```
6. 提示用户："新控制中心已就绪，切换到那个终端即可开始工作"

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

## 使用示例

```
用户（在当前膨胀终端里）：/new-terminal
AI：📋 生成记忆卡片... ✅（下一步含具体文件路径）
    🔍 自检测：Claude → 创建 Claude 终端
    🚀 创建新终端 term_xxx ✅
    ⏳ 等待就绪... ✅
    📤 注入记忆卡片 ✅
    ⚡ 发送执行信号 ✅
    
    ✅ 新控制中心已就绪：切换到 term_xxx 继续工作
```

## 降级

如果 Orca 不可用：退化为 `/cleanup-context` + 提示用户手动开终端粘贴记忆卡片。
