---
description: 自有命令 — 任务委派：在当前会话上下文膨胀时，一键生成记忆卡片 + 开新终端派发给干净上下文的 pi 工人
---

# /delegate <任务描述>

上下文膨胀时，委派任务给独立的 pi 工人终端。工人只携带压缩后的规则+状态，零历史负担。

## 流程

1. 运行 `/cleanup-context` 生成记忆卡片
2. 用 `orca terminal create` 创建新 pi 终端
3. 等待终端就绪（`orca terminal wait --for tui-idle`）
4. 用 `orca orchestration task-create` + `dispatch --inject` 派发任务
   - **preamble 必须包含完整工作流要求**（见下方模板），工人不是"直接写代码"，而是先 brainstorm→plan→（必要时 orca-review）→实现
5. 等待 worker_done 回报（TUI 自动投递）
6. **工人完成后强制校验（不可跳过）：**
   - 检查工作流阶段是否完整（brainstorm → plan → orca-review → implement → verify）
   - 检查 git diff 改动是否合理（不该改的文件改了？遗漏了文件？）
   - 检查 /verify 结果（编译通过？curl 返回正确？）
   - 任何异常立即报告用户，不要默默放行
7. **回报到达后自动关闭工人终端**：`orca terminal close --terminal <handle>`
7. 下一任务重复步骤 2-6

## 派发内容必需模块

```markdown
<记忆卡片>

## ⚙️ 必须遵守的工作流（工人端）

⚠️ 你不是"直接写代码"的工具——你必须按以下流程执行，不得跳过任何步骤：

1. /brainstorm：分析问题→根因→影响面→方案选项。**必须先输出分析结论，再进入下一步。禁止跳过。**
2. /plan：输出文件清单+步骤+验证命令。**必须列出每个文件的完整路径和改动内容。**
3. ⚠️ **orca-review（强制执行，不可跳过）**：除以下豁免外，任何代码改动都必须请求独立评审——
   - **免评（直接实现）：** 纯文本修改、注释修改、CSS/样式调整、列宽/标签修改
   - **必评（发 decision_gate 等评审结果）：** Java/Vue/TS/SQL 任何非免评改动，无论文件数量
   - 具体做法：
   - 用 `orca orchestration send --to <协调者handle> --subject "请求 orca-review" --body "<你的完整plan>" --type decision_gate` 发送评审请求
   - **只发一次 decision_gate**，不要重复发送。之后每30秒用 `orca orchestration check --terminal <你的handle>` 检查是否有该消息的回复
   - **主动轮询等待评审结果**：收到回复前禁止进入实现阶段
   - 等待协调者指派独立 Claude 评审 Agent 并返回结果
   - 吸收评审意见后调整 plan，再进入实现
   - **禁止跳过此步骤直接写代码**，即使你觉得"风险低"也不行
   - **禁止将 /plan 和 orca-review 合并成一个步骤**——必须先输出plan，再发decision_gate，收到回复后才能开始实现
4. 实现：按评审后的 /plan 逐文件修改
5. /verify：compile + curl 实测
   - 🚫 **禁止 mvn clean**——用 `mvn compile`，devtools 会自动热加载
   - ✅ curl 前先确认后端存活：`curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/jeecg-boot/sys/getEncryptedString`
   - ⚠️ **如果 curl 返回非200**：不要尝试重启后端。再试一次 `mvn compile`（不加clean），等5秒后再curl。如果还是失败，在 worker_done 中报告 verify 状态为 partial，不要无限重试
6. **无论如何必须发送 worker_done**：即使 verify 不完全通过，也要发送 worker_done 报告结果
   - 成功：worker_done + filesModified
   - 部分成功（代码改了但verify失败）：worker_done + filesModified + phase=verify_failed + 说明

## 📡 你必须发送的编排消息（每个阶段都要报告，缺一不可）
- 开始 brainstorm 时：发 heartbeat，phase="investigating"
- **输出 /plan 后**：发 heartbeat，phase="planning"
- 发出 orca-review 时：发 decision_gate，附完整 plan
- 等待评审时：发 heartbeat，phase="等待评审"
  - ⚠️ **每30秒主动轮询检查回复**：`orca orchestration check --terminal <你的handle>` 或 `orca orchestration inbox` 查找来自协调者的 Re: 消息
  - **收到回复前禁止进入实现阶段**，即使觉得"风险低"也不行
- 开始实现时：发 heartbeat，phase="implementing"
- 开始 verify 时：发 heartbeat，phase="verifying"
- **完成（或遇到无法恢复的错误）时：必须发 worker_done**，附 filesModified 列表
  - 成功：worker_done + phase=completed
  - verify失败但代码已改：worker_done + phase=verify_failed + 错误说明
  - 无论如何都要发，禁止不发消息就退出

## 当前任务
<用户输入的任务描述>
```

## 派发内容格式

```markdown
<记忆卡片>

---

## 当前任务
<用户输入的任务描述>

要求：
- 严格遵循上述硬规则
- 完成后按 preamble 回报 worker_done，payload 包含更新后的记忆卡片作为 body
- 如果 Memory Card 中有硬规则的 ID 字段，完成后更新状态信息
- 只读代码/规则，修改代码前先确认文件在允许的边界内
```

## 使用示例

```
用户：/delegate 修复采购订单审核按钮报错问题
AI  ：📋 生成记忆卡片... ✅
      🚀 创建工人终端... term_xxx ✅
      📤 派发任务... dispatched ✅
      等待工人完成 → 回报 worker_done → 汇总结果
```

## 降级

如果 Orca 不可用：退化为 `/cleanup-context`，输出卡片后提示用户手动开新终端粘贴。如果无空闲终端槽位：提示用户关闭不需要的终端后重试。
