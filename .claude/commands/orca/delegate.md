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
6. **回报到达后自动关闭工人终端**：`orca terminal close --terminal <handle>`
7. 下一任务重复步骤 2-6

## 派发内容必需模块

```markdown
<记忆卡片>

## ⚙️ 必须遵守的工作流（工人端）

⚠️ 你不是"直接写代码"的工具——你必须按以下流程执行，不得跳过任何步骤：

1. /brainstorm：分析问题→根因→影响面→方案选项（输出到报告，不直接动手）
2. /plan：文件清单+步骤+验证命令
   → 如果 ≥3 文件且跨模块：暂停，先派 Claude orca-review，吸收意见后再输出最终计划
3. 实现：按 /plan 逐文件修改
4. /verify：compile + curl 实测（本地 8080 在跑时必须 curl，禁止只 compile 就 commit）
5. 完成后按 preamble 回报 worker_done

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
