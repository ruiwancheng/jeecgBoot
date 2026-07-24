# [2026-07-24] [Orca] 多AI agent编排——pi开发+Claude评审是最优组合

## 触发条件
Orca 支持 5 种 AI agent（pi/claude/hermes/kimi/codex），需要确定 delegate/orca-review 中的最佳分工。

## 发现
- `orca terminal create --command "pi"` 等全部可用
- 单终端 delegate = 开发+评审同一个人 = 自审漏洞
- 双终端 orca-review = 开发(任意AI) + 评审(Claude) = 真·第二意见

## 最佳组合

| 场景 | 开发 | 评审 | 
|------|:--:|:--:|
| 日常开发 | pi（快速产出） | Claude | 
| 高风险 | Claude | Claude（不同实例） | 
| 纯文档 | pi | 免 | 

**为什么评审方固定 Claude：** Claude 的审查细致度最高。真实测试中 Claude 评审发现了 pi 不会注意的 P0 字段名错误（`applicationDept` vs `deptId`）。

## 处理方式
- delegate.md：按任务类型自动选开发 agent
- orca-review/SKILL.md：评审方固定 Claude
- 禁止单终端自审（已移除降级手工评审）
