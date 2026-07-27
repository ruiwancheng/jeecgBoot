# [2026-07-24] [Harness] Hook 触发链单点脆弱性——跳过入口=全线崩溃

## 触发条件
设计多阶段门控链（plan→review→write→verify）时，每个阶段的 hook 依赖前序阶段的 Skill 调用作为触发条件。

## 根因
`pre-plan-check.sh` 依赖 `PreToolUse(Skill=plan)` 触发。当 AI 内联输出 plan 而非调用 Skill 工具时，hook 完全不执行 → delegate 判定跳过 → orca-review 跳过 → 写代码不受任何约束。**一个入口点失效，下游全线失守。**

## 解决方案
- **防御纵深：** 不在入口处设唯一防线。`pre-write-check.sh` 作为第二道防线——写入代码文件前检查 `/tmp/claude-plan-executed` 标记
- **标记文件跨 hook 传递状态：** `pre-plan-check` 写入标记 → `pre-write-check` 读取标记 → `session-end` 清理标记
- **每道防线独立触发条件：** 入口防线靠 Skill 事件，写入防线靠 Edit/Write 事件——AI 很难同时绕过两个不相关的事件

## 处理方式
- 检查所有门控链：是否每个阶段都有独立触发条件的 backup 防线
- 优先加固"写代码"阶段的防线——这是最终落地动作，AI 无法跳过
- 标记文件模式可复用到 orca-review（`.last-orca-review`）、verify（`.last-verify` 已存在）等阶段

## 关联
- [[2026-07-24-hard-constraint-layers]] — L4 exit 1 是唯一硬约束
- [[2026-07-24-orca-review-false-sense]] — 依赖 AI 自觉=设计上等于没规则
