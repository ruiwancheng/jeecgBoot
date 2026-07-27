# Orca 外部评审 — Wave 1c Learnings 归档方案

> **评审日期**：2026-07-27
> **评审人**：Claude Code (Opus 4.8) — Harness 工程质量评审
> **评审范围**：Wave 1a (6 rules merge) + 1b (2 skills archive) + 1c (27 learnings archive) + 其他变更

---

## 📊 评审总览

| 统计项 | 数值 |
|--------|:--:|
| 审计文件数 | 71+（27 归档 learnings + 54 活跃 learnings + 7 归档 rules + 14 活跃 rules + MEMORY.md + 交叉引用） |
| **P0 阻断** | **2** |
| **P1 发现** | **5** |
| **P2 建议** | **5** |

---

## 🔴 P0 阻断项（必须修复后再继续归档 — 已有真实数据风险）

### P0-1: MEMORY.md 含 6 条断链 — 已归档 learnings 仍被索引引用

**严重度**: 🔴 数据丢失风险 — AI 在会话中读到断链时获取不到信息

**文件**: `.claude/memory/MEMORY.md`

MEMORY.md 是**每个会话启动时加载的索引**。以下 6 行指向的 learnings 已移动到 `.archived/`，文件不存在，无法读取：

| 行号 | 链接 | 归档路径 |
|:--:|------|------|
| 2 | `learnings/2026-07-06-docker-mysql-backtick.md` | `.archived/2026-07-06-docker-mysql-backtick.md` |
| 3 | `learnings/2026-07-06-new-project-sql-gap.md` | `.archived/2026-07-06-new-project-sql-gap.md` |
| 4 | `learnings/2026-07-06-mysql-hex-encoding-check.md` | `.archived/2026-07-06-mysql-hex-encoding-check.md` |
| 6 | `learnings/2026-07-06-drawer-modal-hooks.md` | `.archived/2026-07-06-drawer-modal-hooks.md` |
| 22 | `learnings/2026-07-21-mysql-reserved-word-ddl.md` | `.archived/2026-07-21-mysql-reserved-word-ddl.md` |
| 29 | `learnings/2026-07-21-orca-coordinator-no-check-wait.md` | `.archived/2026-07-21-orca-coordinator-no-check-wait.md` |

**风险分析**：

| learning | rules 等效覆盖？ | 等效质量 |
|----------|:--:|------|
| docker-mysql-backtick | ❌ 未覆盖 | 无规则提到 Docker MySQL 反引号转义 |
| new-project-sql-gap | ❌ 未覆盖 | 无规则覆盖 `/new-project` 后 SQL 未自动执行的缺口 |
| mysql-hex-encoding-check | ❌ 未覆盖 | 无规则覆盖 `HEX()` 诊断双重编码的方法 |
| drawer-modal-hooks | ✅ `frontend.md:14` | 等效——Hook 配对规则已写入 |
| mysql-reserved-word-ddl | ✅ `code-style.md:40-43` | 等效——保留字禁止规则已写入 |
| orca-coordinator-no-check-wait | ⚠️ 部分 | delegate.md 有 preamble 模板但缺少"TUI 截胡邮件"根因说明 |

**结论**：6 条断链中，3 条（backtick, sql-gap, hex-encoding）在 rules 中**完全无等效覆盖**。如果这 3 条内容确实有价值，归档操作造成了信息丢失。如果这 3 条因价值低而归档，MEMORY.md 索引必须更新。

**修复建议**：
1. 从 MEMORY.md 删除这 6 行（如果内容已无价值）
2. 或者从 `.archived/` 恢复这 3 条无等效覆盖的 learnings（如果仍有参考价值）
3. 或者将 backtick/hex-encoding/sql-gap 的精简内容合并到 `debugging.md` 的"常见报错"表

---

### P0-2: code-style.md 与已归档 learning 存在技术矛盾 — `@Select` 是否绕过 `@TableLogic`

**严重度**: 🔴 核心代码模式正确性受影响 — "借尸还魂"是高危操作

**矛盾源**：

| 来源 | 说法 | 位置 |
|------|------|------|
| **code-style.md** (活跃) | "用 Mapper `@Select` 注解原生 SQL **绕过** `@TableLogic` 拦截器" + "`selectDeletedByCode` 用 `@Select` 注解原生 SQL" | line 16, 119 |
| **已归档 learning** `mybatis-plus-tablelogic-raw-sql-conflict.md` | "`@Select("SELECT * FROM t WHERE code=? AND del_flag=1")` 查不到已删除记录，MyBatis-Plus 的 `@TableLogic` 拦截器给 SQL 追加了 `AND del_flag=0`" + **"查删+复活操作统一用 JdbcTemplate，不要依赖 @Select/@Update 注解"** | 全文 |

**为什么这是 P0**：

1. **两种说法互斥** — 一个说 `@Select` 可以绕过，一个说不行
2. **这是高频操作** — "借尸还魂"是 MES 项目的核心编码模式（每个带唯一索引的表都要用）
3. **后果严重** — 如果 code-style.md 错了，AI 在生成新 Mapper 时会用 `@Select` 取不到软删除记录 → 重复插入 → 唯一索引冲突 → 数据错误
4. **学习被归档是因为"已覆盖"** — 归档前没有验证等效覆盖是否精确

**根因**：MyBatis-Plus 不同版本的 `@TableLogic` 行为不同。`@Select` 标注的方法在**某些版本**会被拦截器追加 `AND del_flag=0`，在**某些版本**不会被拦截。JeecgBoot 3.9.5 使用的 MyBatis-Plus 版本中，`@Select` **是否被拦截需要实测验证**——但两种矛盾的规则同时存在于"知识体系"中。

**修复建议**：
1. **实测验证** — 在运行中的 JeecgBoot 实例上，调一个已有 Mapper 的 `@Select selectDeletedByCode` 方法，确认 `@TableLogic` 是否追加了 `AND del_flag=0`
2. **根据实测结果统一规则** — 如果 `@Select` 确实被拦截，修正 code-style.md 为 "用 JdbcTemplate 绕过"；如果不被拦截，确认归档 learning 是版本差异导致的误判
3. **在调试规范中加诊断方法** — 遇到 `selectDeletedByCode` 返回 null 时的排查步骤

---

## ⚠️ P1 发现（建议修复）

### P1-1: deep-inspect-schedule.md 被归档但 3 个活跃文件仍引用

**文件**: `.claude/rules/.archived/deep-inspect-schedule.md`
**引用者**:
| 文件 | 行 | 引用方式 |
|------|:--:|------|
| `.claude/rules/deploy-quality-gate.md` | 195 | "`deep-inspect-schedule.md` \| 互补..." |
| `.claude/skills/harness-check/SKILL.md` | 20 | 检查清单中列为活跃规则 |
| `.claude/skills/deep-inspect/SKILL.md` | 163 | "巡检调度规则（频率、模块优先级）" |

**分析**：deep-inspect-schedule 是 wave 1a 中**不在合并清单**里的——它未被合并到 code-style.md 或 boundary.md，而是被直接归档。但 deploy-quality-gate 和 deep-inspect 技能仍依赖它的调度逻辑（"7 天提醒""模块优先级"等）。如果这些引用只是为了文档完整性而不是运行时加载，风险较低。但在 `harness-check` 的规则完整性检查中，它仍被列为活跃规则——这会在下次 harness 巡检时造成误报。

**修复建议**：
1. 从 `harness-check/SKILL.md` 的规则列表中移除 `deep-inspect-schedule`
2. `deploy-quality-gate.md` line 195 改为引用 `deep-inspect/SKILL.md`（该技能已包含调度逻辑）
3. 或者——如果该规则仍有调度价值——从 `.archived/` 恢复为活跃规则

### P1-2: 6 条 Harness 规则 learnings 的核心实现细节未全量迁移

**归档的 Harness learnings**: hook-testing, command-skill-split, drawer-modal-hooks, hard-constraint-layers, hook-trigger-chain-fragility, rule-condition-blind-spot

**等效覆盖分析**：

| Learning | 核心知识 | rules 是否等效覆盖 | 缺失什么 |
|----------|---------|:--:|------|
| hard-constraint-layers | 四层约束模型（L1-L4 执行力递减） | ⚠️ 部分 | human-gate 只有结论"L4 exit 1 是硬约束"，缺少四层分析框架——后续设计新门控时缺少参考模型 |
| hook-trigger-chain-fragility | 防御纵深：多道防线各自独立触发条件，标记文件跨 hook 传递状态 | ❌ 未覆盖 | 这是设计 multi-hook 门控链的核心方法论，human-gate 框架未纳入 |
| rule-condition-blind-spot | "模式级豁免"模式的系统性脆弱，改为"操作级豁免" | ⚠️ 部分 | human-gate 引用了结论但未展开模式→操作级的转换方法 |
| orca-review-false-sense | "提示用户确认"档位在设计上等于没规则 | ✅ 等效 | human-gate 设计原则表完整捕捉 |
| orca-review-fake-safety | 单终端自审=100% 通过率，需双终端真·第二意见 | ✅ 等效 | human-gate 设计原则表完整捕捉 |
| multi-ai-orchestration | pi 开发+Claude 评审的最优组合及验证数据 | ❌ 未覆盖 | delegate.md 有 preamble 但缺少"为什么 Claude 是评审方"的论证和 P0 字段名错误案例 |

**修复建议**：
1. `hook-trigger-chain-fragility` 的防御纵深设计模式建议作为 human-gate 技能的附录，因为它直接影响门控链的可靠性设计
2. `hard-constraint-layers` 的四层模型可合并到 human-gate 的"设计原则"节
3. 其余等效覆盖充分的可保持归档

### P1-3: 3 条代码 bug learnings 的关键诊断方法未迁移

**归档 learnings** 中的诊断方法论：

| Learning | 诊断方法 | rules 是否覆盖 | 
|----------|---------|:--:|
| docker-mysql-backtick | 反引号包裹连字符库名，shell 中转义 | ❌ 未覆盖 |
| docker-mysql-charset | `--default-character-set=utf8mb4` 管道传文件 | ❌ 未覆盖 |
| mysql-hex-encoding-check | `SELECT HEX(column)` 判断双重编码（字节数≈字符数×3=正常） | ❌ 未覆盖 |
| mysql-57-add-column-no-if-not-exists | Docker 重建容器后 SQL 需重新执行 | ✅ `debugging.md:29` |
| spring-ambiguous-mapping | `mvn compile` 无法检测 Spring 映射冲突，需启动后验证 | ✅ `code-style.md:20` |
| sql-migration-deploy-reliability | 部署校验码去重 + `INSERT IGNORE` 独立语句 | ✅ `code-style.md:55-60` |

**为什么重要**：这 3 条"未覆盖"的 learnings 包含的是**诊断方法**而非规则约束。rules 擅长描述"不要做什么"，但 learnings 擅长描述"出问题后怎么查"。规则和 learnings 是互补而非替代关系。

**修复建议**：
1. `mysql-hex-encoding-check` 的诊断方法合并到 `debugging.md` 的"常见报错"表（新增一行"中文乱码→HEX(column)诊断"）
2. `docker-mysql-backtick` 和 `docker-mysql-charset` 的方法合并到 `local-dev` 技能（因为那是 Docker 操作的主要场所）
3. 或者在 MEMORY.md 中保留指向 `.archived/` 的链接（标注 [ARCHIVED]），让 AI 知道"需要时可查归档"

### P1-4: Wave 1b 归档的 skills 引用链未完全清理

**归档 skills**: `quality-orchestrator`, `experiment-tracker`

检查引用链：

- `quality-orchestrator` → 被 `deploy-quality-gate.md` 和 `quality-gates.md` 引用？需验证是否有调用
- `experiment-tracker` → 被 `.claude/rules/gen-tests-rules.json` 是否引用？

这两个 skills 的归档是安全的（未被活跃命令引用），但没有留下"为什么归档"的记录（如 README 或 CHANGELOG），后续 AI 可能重新创建类似功能。

**建议**：在 `.claude/skills/.archived/README.md` 中记录归档原因（如 "quality-orchestrator: 被 deploy-verify 的 Orca 编排取代"）。

### P1-5: wave 1a 合并中 security.md 的 .env 保护规则丢失了"不改 .env"约束的来源文件路径

**背景**：原来的 `security.md` 是一个独立文件，CLAUDE.md 在"关键规则"表中引用它。合并到 `code-style.md` 后：
- `code-style.md` line 209-216 有精简后的安全规范
- 但原来 `security.md` 中可能有更详细的 `.env` 文件路径和示例

验证：`code-style.md:209-216` 包含 4 条安全规则（不改 .env、不写死密码、SQL 参数化、环境变量注入），与原始 `security.md` 对比。看起来精简后的版本保留了核心要点，**等效覆盖充分**。但原文件已被覆盖（mv），无法直接对比。

**建议**：可选——确认 `code-style.md` 的安全节与原 `security.md` 的差异无遗漏。

---

## 💡 P2 建议

### P2-1: 归档 learnings 缺少等效覆盖自查表

27 条 learnings 通过关键词匹配批量归档，没有逐条做"这条知识在哪个活跃 rule 中有等效覆盖"的检查。这导致 P0-2（`@Select` vs `JdbcTemplate` 矛盾）和 P1-2（诊断方法遗漏）无法在归档时被发现。

**建议**：为被归档的每条 learning 追加一行注释（如文件第一行 `# Archived: covered by code-style.md line 40-43`），方便未来查证。

### P2-2: `@TableLogic` + `@Select` 实测验证脚本

P0-2 的矛盾可以通过一个简单的 curl 调用来解决：

```bash
# 在 JeecgBoot 源码中找一个已有的 selectDeletedByCode Mapper 方法
# 手动调对应的 Controller endpoint，确认能否查到软删除记录
# 如果能查到 → code-style.md 正确，学习的担心不适用当前版本
# 如果查不到 → code-style.md 有误，需改为 JdbcTemplate
```

建议把验证结果写回 code-style.md 和 `.archived/` 中对应的 learning。

### P2-3: MEMORY.md 可加 [ARCHIVED] 锚点

与其删除 MEMORY.md 中断链的条目，可改为标注 `[ARCHIVED]`：

```markdown
- [Docker MySQL 连字符库名](learnings/.archived/2026-07-06-docker-mysql-backtick.md) [ARCHIVED] — 含连字符的库名必须用反引号包裹
```

好处：AI 仍能看到此知识点存在，需要时可到 `.archived/` 查找。

### P2-4: harness-check 技能规则列表过期

`harness-check/SKILL.md:20` 列出 22 个活跃规则文件，其中：
- `backend-first`、`no-platform-modify`、`security`、`data-scope`、`file-scope`、`override-mechanism` — 已合并到 code-style.md/boundary.md
- `deep-inspect-schedule`、`tiequan-report-scope`、`tiequan-report-retention` — 已合并到 tiequan-reports.md
- `quality-escalation`、`quality-gate-criteria`、`security-gate-checklist` — 已合并到 quality-gates.md

下次运行 harness-check 时会报告"规则文件缺失"。建议更新该列表。

### P2-5: 归档操作的 changelog 不完整

本次 3 波优化缺少统一的变更日志。虽然有 git 历史记录，但文件在 `.archived/` 中，git 跟踪的是"删除+新增"而非"移动"。建议在 `.claude/CHANGELOG.md` 或 `.claude/.archived/README.md` 中记录每次批量归档的时间、范围、原因。

---

## 🔍 各维度详细审计

### 1. 数据丢失风险评估

| 类别 | 风险 | 说明 |
|------|:--:|------|
| Rules 合并 (wave 1a) | 🟢 低 | 合并前读取了完整源文件，合并后逐个确认无丢失 |
| Skills 归档 (wave 1b) | 🟢 低 | 2 个未激活 skills，无活跃引用 |
| Learnings 归档 (wave 1c) | 🔴 中 | 关键词批量匹配→3 条诊断方法无等效覆盖 + 1 条存在矛盾 |
| MEMORY.md | 🔴 高 | 6 条断链，每次会话加载失败 |
| deep-inspect-schedule | 🟡 中 | 被归档但 3 个文件引用，影响部署提醒和巡检调度 |

### 2. 可逆性验证

| 操作 | 可逆？ | 验证 |
|------|:--:|------|
| `mv` 到 `.archived/` | ✅ | 全部使用 `mv`，可 `mv` 回去 |
| 文件合并 | ✅ | git 保留了原始内容（原始文件在 git 历史中） |
| MEMORY.md 更新 | ⚠️ | 未更新——这本身不是 mv 操作，而是遗漏 |

**没有 `rm`/删除操作** — 全部可逆。

### 3. 引用断裂分析

| 引用源 | 目标 | 断裂？ | 说明 |
|------|------|:--:|------|
| MEMORY.md | 6 条 learnings | 🔴 是 | 文件在 `.archived/`，索引指向原路径 |
| human-gate SKILL | `orca-review-false-sense` lesson name | ⚠️ 概念级 | learning 文件路径变了（加到 `.archived/`），但 human-gate 用的是名称引用非文件路径——概念层面仍有效，但如果 AI 想找原始 learning 会失败 |
| deploy-quality-gate.md | `deep-inspect-schedule.md` rule | ⚠️ 概念级 | 引用的是规则概念，不是文件 include——但规则已不可用 |
| harness-check SKILL | 多个已归档 rules | 🟡 是 | 下次巡检时会报告缺失 |

### 4. 合并质量评估

| 合并目标 | 来源 | 质量 |
|------|------|:--:|
| code-style.md — 后端优先节 | backend-first.md | ⭐⭐⭐⭐⭐ 完整 |
| code-style.md — 平台保护节 | no-platform-modify.md + override-mechanism.md | ⭐⭐⭐⭐⭐ 含 Bean 替换+路由覆盖+扩展表+manifest |
| code-style.md — 安全节 | security.md | ⭐⭐⭐⭐ 核心 4 条保留（可能丢失了 .env 示例） |
| boundary.md | data-scope.md + file-scope.md | ⭐⭐⭐⭐⭐ 48 行精简版，核心边界完整 |
| quality-gates.md | quality-gate-criteria.md + security-gate-checklist.md + quality-escalation.md | ⭐⭐⭐⭐ 三段合并，STRIDE 映射保留 |

### 5. 剩余 Learnings (54 条) 覆盖度

抽样检查（核心场景）：
- SQL/DDL: `table-dict-bypasses-tablelogic`, `softdelete-unique-index-double-delete` ✅ 保留
- 并发安全: `calctotal-before-save`, `financial-concurrency-lock`, `stock-in-out-symmetry`, `synchronized-transactional-window`, `cross-module-lookup-fail-fast` ✅ 全部保留
- 前端: `vite-glob-cache-new-component`, `a-form-item-not-auto-import`, `defhttp-delete-joinparams` ✅ 保留
- 部署: `auto-generate-check-not-null`, `deploy-divergent-branches-rebase` ✅ 保留

**结论**：剩余 learnings 覆盖了核心风险场景，关键踩坑经验未丢失。

---

## 📋 回答评审问题

### Q1: wave 1c 的 learnings 归档方式是否安全？

**答**：关键词批量匹配在操作安全性上是安全的（mv 可逆），但在**信息安全性**上有 3 处遗漏：
1. **docker-mysql-backtick** / **docker-mysql-charset** / **mysql-hex-encoding-check** — 3 条诊断方法论无等效覆盖（P1-3）
2. **@Select vs JdbcTemplate** — 1 条存在技术矛盾被错误归档（P0-2）
3. **hook-trigger-chain-fragility** / **hard-constraint-layers** — 2 条核心设计模式未被全量迁移（P1-2）

### Q2: 等效信息是否可从 rules 获取？

**答**：大部分可以，但有例外。代码风格/前端组件/审计分类的 learnings 在 rules 中有等效覆盖。但 Docker 操作技巧、编码诊断方法、Harness 门控设计模式——这三类信息在 rules 中缺少等效覆盖，因为 rules 是"约束"而 learnings 是"故事+诊断"。

### Q3: 是否应该逐条人工审查？

**答**：批量关键词匹配效率高，但**应该在归档前做一步交叉验证**——对每条命中关键词的 learning，搜索活跃 rules 中是否有引用或等效覆盖。这一步如果做了，会发现 P0-2 的 `@Select` vs `JdbcTemplate` 矛盾。建议以后批量归档 learnings 时，对每条 learning 加一行 `# Equivalent coverage: <rule-file>:<line>` 注释。

### Q4: 多客户端多 AI agent 场景的净效应？

**答**：**净正面** — 但有一个前提条件：修复 P0-1 和 P0-2。
- 规则从 19→14 降低了每个会话的 token 消耗（每次会话加载所有活跃规则）
- 合并后的规则更易于维护（单一真相源）
- 但 MEMORY.md 断链意味着新客户端首次启动时 AI 会读到 6 条死链接——在"首次接入"场景下这是信息丢失
- `@Select` vs `JdbcTemplate` 矛盾意味着多 AI agent 可能对同一个代码模式产生不同的理解——A agent 读 code-style.md 用 `@Select`，B agent 读到归档 learning 用 `JdbcTemplate`

### Q5: 遗漏的跨平台问题？

**答**：本次优化未引入新的跨平台问题。但 `docker-mysql-backtick` 和 `docker-mysql-charset` learnings 的归档间接影响了 Docker 使用场景的故障排查——当 Docker 部署出错时，AI 缺少这些诊断知识。

---

## ✅ 通过项

1. **合并质量高** — code-style.md 和 boundary.md 的合并章节完整捕捉了源文件的核心要点，标注了"合并自 X"的来源追溯
2. **关键学习保留** — 54 条剩余 learnings 覆盖了并发安全（FOR UPDATE、synchronized 窗口期、审计操作顺序）、SQL 迁移、前端组件陷阱等核心场景
3. **操作可逆** — 全部使用 `mv` 到 `.archived/`，无 `rm` 操作。任何时候都可以 `mv` 回去
4. **human-gate 设计扎实** — 三条核心教训（false-sense、fake-safety、blind-spot）在设计原则表中被妥善捕捉
5. **deploy-quality-gate.md** — 与 deep-inspect-schedule 的关系声明清晰，交叉引用完整
6. **audit-classification.md** — 常见模式速查表保留了所有审计相关 learnings 的精简结论
7. **frontend.md** — 前端组件常见坑表覆盖了 drawer-modal-hooks、pinia-getter、antd-rowselection、vue3-antdv-pitfalls 的等效知识

---

*评审归档：`hermes/reviews/2026-07-27/orca-review-wave1c-learnings-archive.md`*
