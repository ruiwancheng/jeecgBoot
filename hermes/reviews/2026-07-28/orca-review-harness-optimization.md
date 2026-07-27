# Orca 外部评审 — wave 1c learnings 归档方案评审

**评审阶段**：code-review（代码完成后轻量审计）
**评审对象**：本次 Harness 优化的 wave 1c learnings 归档操作的安全性

## 背景

本次 Harness 优化分为 3 波执行，其中：
- Wave 1a: 6 个小规则合并到 code-style.md + boundary.md，归档 6 个旧规则文件至 .archived/
- Wave 1b: 归档 2 个未激活 skills (quality-orchestrator, experiment-tracker)
- Wave 1c: 批量归档 27 条 learnings，基于关键词匹配归档（非逐条审查）

Wave 1a 和 1b 已完成且安全（合并前读取了完整源文件内容，归档是可逆的 mv 操作）。

Wave 1c 的归档方式是**模式匹配而非逐条审查**——使用 `grep -E "hook|hard-constraint|rule|command-skill|anti-pattern|karpathy"` 等关键词批量筛选后 `mv` 到 .archived/。这种方式可能误归档了仍有参考价值的 learnings。

## 变更范围（所有活跃状态变更）

### 规则层面
- 已合并: backend-first, security, no-platform-modify, override-mechanism → code-style.md
- 已合并: data-scope + file-scope → boundary.md (新文件 48 行)
- 已归档: 上述 6 个旧规则文件 → .claude/rules/.archived/
- 活跃规则: 19 → 14 (含 gen-tests-rules.json)

### Skills 层面
- 已归档: quality-orchestrator + experiment-tracker → .claude/skills/.archived/
- 活跃 skills: 54 → 52

### Learnings 层面（最需要评审）
- 已归档 27 条 (3 个批次):
  1. Harness 规则类 (6 条): hook-testing, command-skill-split, drawer-modal-hooks, hard-constraint-layers, hook-trigger-chain-fragility, rule-condition-blind-spot
  2. Orca 协作类 (7 条): orca-coordinator-no-check-wait, delegate-orca-review-enforcement, delegate-verify-hang-fix, delegate-worker-no-mvn-clean, multi-ai-orchestration, orca-review-fake-safety, orca-review-false-sense
  3. 代码 bug 类 (14 条): docker-mysql-backtick, docker-mysql-charset, mysql-hex-encoding-check, new-project-sql-gap, mybatis-plus-tablelogic-raw-sql-conflict, mysql-57-add-column-no-if-not-exists, vue3-antdv-component-pitfalls, sql-default-dict-code, sql-migration-deploy-reliability, audit-operation-order, mysql-reserved-word-ddl, spring-ambiguous-mapping, antd-rowselection-checkbox, pinia-getter-not-method

- 剩余 54 条: 包含 calctotal-before-save, financial-concurrency-lock, synchronized-transactional-window, cross-module-lookup-fail-fast 等核心踩坑经验（已保留）

### 其他变更
- /debug 升级: 增加步骤 0 反馈回路
- /review 升级: 增加双轴审查模式
- deploy-verify: 增加安全检查清单交叉引用
- hermes/pipeline.md: 管道可视化 (105 行新文件)
- Harness 使用指南: D:/笔记空间/.../Harness使用指南.md (519 行)

## 已查证项

| 查证项 | 状态 |
|--------|:--:|
| 归档是 mv 操作（可逆） | ✅ |
| 源文件内容在合并前已完整读取 | ✅ (wave 1a) |
| 合并后的目标文件无内容丢失 | ✅ (逐个文件确认) |
| 知识图谱已增量更新 | ✅ |

## 待评审问题

1. wave 1c 的 learnings 归档方式（关键词批量匹配 + mv）是否安全？有没有误归档的关键 learnings？
2. 这 27 条 learnings 如果被错误归档，后续 AI 是否还能从 rules 中找到等效信息？
3. 有没有应该多停留一步、逐条人工审查，但我跳过了的地方？
4. 从"多客户端多 AI agent 场景"角度看，这次优化对 Harness 工程质量的净效应是正还是负？
5. 有没有遗漏的跨平台问题或 breakage？

## 评审提示词

你是一位 Harness 工程质量评审专家，请审计以上优化操作的安全性和正确性。

评审关注：
1. **数据丢失风险** — 归档的 learnings 中是否有核心信息未被 rules 等效覆盖？例如某个 learnings 中的具体命令/踩坑步骤只在 learnings 中有，合并后的 rules 中只写了结论没有写步骤
2. **可逆性** — 归档操作是否全部可逆（mv 到 .archived/），有没有 rm/删除操作？
3. **引用断裂** — 有没有规则/技能/命令引用了已归档的文件路径？例如 rule-condition-blind-spot 被 human-gate 的设计原则表引用——归档后 human-gate 中的引用是否仍然有效？
4. **合并质量** — code-style.md 和 boundary.md 的合并章节是否完整捕捉了源文件的全部要点？有没有遗漏的约束？
5. **learnings 剩余质量** — 剩余的 54 条 learnings 是否覆盖了代码风格/sql/并发/前端/审计分类的核心场景？

请输出结构化评审报告，格式：
```
✅ 通过项：
⚠️ 发现（P1 — 建议修复）：
💡 建议（P2 — 优化建议）：
```