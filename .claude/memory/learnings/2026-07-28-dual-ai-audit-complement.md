# [2026-07-28] [Harness] Orca+Pi 双 AI 评审互补模式 — Claude 审内容，pi 审引用

## 触发条件
对大规模 Harness 工程变更（规则合并/归档/learnings 消化）同时提交 Orca(Claude) 和 pi 两个独立终端审计。

## 发现
两个 AI 的审计视角天然互补：
- **Orca (Claude)**: 审内容正确性——发现 `@Select` vs `JdbcTemplate` 技术矛盾 (P0)、MEMORY.md 断链 (P0)、learnings 等效覆盖缺失 (P1)
- **pi**: 审引用完整性——发现 CLAUDE.md 入口文件旧规则名断链 (P1)、nul 文件泄漏 (P1)、.gitignore 漏洞 (P1)

Claude 深层分析强（追踪跨文件的规则矛盾），pi 系统性扫描强（38 modified + 20 untracked 逐文件核对、跨仓库引用闭包扫描）。

## 处理方式
- 大规模工程变更（≥20 文件）→ 双 AI 并行审计：Orca 审内容，pi 审引用
- 小改动（≤10 文件）→ 单 AI 审计即可
- 两个报告的 P0/P1 取并集，P2 取交集
- 互补不是互替——两种 AI 的审计结论不重复，各自覆盖对方盲区

## 关联
- [[2026-07-24-multi-ai-orchestration]] — pi 开发+Claude 评审的最优组合
- [[2026-07-24-orca-review-fake-safety]] — 单终端自审=100% 通过率
