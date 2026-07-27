# [2026-07-24] [Harness] orca-review "降级手工评审" 是虚假安全感——单终端自审永远通过

## 触发条件
delegate 模式下 orca-review 降级为"手工评审"，worker 自己审自己的方案。

## 根因
单终端 AI 无法创建第二个独立终端来审查自己。"手工评审"就是同一个 AI 从"评审视角重新审视"——它不会质疑自己的假设，不会发现自己没注意到的遗漏。100% 通过率，等于没审。

验证：delegate 测试中连续 5 次单终端任务，orca-review 全部"通过"，0 个发现。第一次真正双终端派审，立即发现 P0 字段名错误（`applicationDept` vs `deptId`）。

## 处理方式
- 彻底移除"降级手工评审"策略，改为"Orca 不可用 → 标注未评审 → 用户决策"
- orca-review 评审方固定为 Claude（审查细致度最高）
- 开发方可用 pi/claude/hermes/kimi/codex
- 涉及文件：orca-review/SKILL.md、plan.md、debug.md
