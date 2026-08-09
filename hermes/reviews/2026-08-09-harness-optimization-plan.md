# Harness 优化方案评审 — 基于 Matt Pocock skills 模式

**日期**：2026-08-09
**评审对象**：`.claude/` Harness 4 步优化提案
**评审视角**：工程师实操（小团队，KA 节奏）

---

## 一句话总结

**三个改动是仪式感重于实际价值，一个改动的目标工具找错了。** 真正的痛点（规则全局加载导致的上下文膨胀）方案完全没碰。整体需要重排优先级，砍掉 1-2 项，剩下 2 项做轻量化改造。

---

## 评审基线

在评审前先核实了 4 个事实，避免基于方案文本的假设做判断：

| 事实 | 数据 |
|---|---|
| skills 数量 | `find .claude/skills -name SKILL.md \| wc -l` = **62 个**（用户文中"50+" 属实） |
| rules 数量 | 16 个 `.md` 文件，**3506 行**（与提案一致） |
| 规则加载机制 | 13/16 rules 使用 `glob: "**/*"` 或等价万能匹配 → **每次会话全部加载** |
| `/deep-inspect` 实际定义 | 性能基准 + 视觉证据 + 无障碍审计，**不是架构扫描**。架构分析在 `architecture-report` 技能（3 层：总览 / 热点债务 / 结构债务） |
| 现有"领域词汇"基础设施 | `.claude/memory/MEMORY.md` + `learnings/` 50+ 条 + `methodology-index.md` 分索引 |

---

## 提案 A：新建 CONTEXT.md — 评审：**不通过（需重做）**

### 问题诊断的偏差

提案说"15 rules 术语分散，AI 每次重新推理"。但 `debugging.md` 里已经有完整的 JeecgBoot 报错速查、Vue warn 三板斧、MySQL 端口冲突、@TableLogic 模式——165 行业务知识，**不是每次重新推理**。

真正的问题不是"分散"，而是：

1. **MEMORY.md 已经存在并履行词汇表职能**：41 行的索引文件，链向 50+ 条 learnings，按主题分类。"术语→代码映射"已经在 learnings 里（如 `2026-07-06-password-encrypt.md`、`2026-07-21-table-dict-bypasses-tablelogic.md`）。
2. **规则加载机制是真正的瓶颈**：13/16 rules 走 `glob: "**/*"`，3506 行规则**全文注入每次会话**。新增一个会自动加载的 CONTEXT.md 只会让这个问题更糟。
3. **提案列的 4 个字段有 3 个已有覆盖**：
   - 术语→代码映射 → learnings/ 散落但可索引
   - 状态机表 → 当前**没有**集中位置（这是真缺口）
   - 模块缩写表 → 当前**没有**集中位置（这是真缺口）
   - UI 交互模式 → `frontend.md` rules 已覆盖

### 维护成本

新增一个被 `/learn` 自动维护的全局文件 = 第 17 个需要保持同步的源。如果 MEMORY.md 已经在履行这个职责，再造一个要么并行（双重维护风险），要么覆盖（推翻已有 50+ 条 learnings 的索引价值）。

### 修改建议

**不要新建文件。** 做两件事：

1. **在 MEMORY.md 增加 2 个段落**：
   - "模块缩写表"（MES-xxx → 全称 → 主文件路径），由 `/learn` 触发增量补充
   - "状态机表"（订单状态/盘点状态/审批状态 → 字段 + 转移条件）

2. **（更高优先级，先做）拆分高频规则的低频部分**：把 `debugging.md` 中"`mvn -q install` 静默失败"这种一次性案例下沉到 learnings，让 `debugging.md` 只保留会**频繁重新触发**的诊断流程。`code-style.md` (506 行) 同理。这是减法，不是加法。

### 触发问题 1 的回答

> CONTEXT.md 与现有 15 rules 是互补还是替代？

**替代，且是糟糕的替代。** 现有的 MEMORY.md + learnings 体系是真正起作用的；CONTEXT.md 提案是另一套并行机制，会增加维护负担而不解决核心问题（规则加载过重）。

---

## 提案 B：/to-spec — 评审：**有合理内核，但执行过度**

### 真实缺口

`/decompose` 技能（不是命令）已经有完整的 6 要素：
1. 业务名 + 用户操作路径
2. 验收标准（UI 上能看到什么）
3. 依赖关系
4. 风险等级
5. 工作量估算
6. Rollback 策略

还差什么？`/decompose` 在 `/plan` 之后跑。而 `/brainstorm` 输出口头验收标准（命令文件里说"用业务语言列出完成标准"），但**没有持久化**——下次会话就丢了。

**真正的缺口** = 在 `/brainstorm` 和 `/plan` 之间，把口头验收标准落到一个**可追溯文件**，而不是发明一个新命令。

### 仪式感风险

提案说"可选步骤"。但"可选"在 Harness 里很容易变成"总是开"。/plan 已经会把需求、验收标准写到 plan 文件（`.claude/.last-plan.json`），再插一层 spec 就是双重 artifact：
- `.claude/specs/<req-id>.md`（to-spec 输出）
- `.claude/.last-plan.json`（plan 输出）
- `.claude/.decompose-state.json`（decompose 输出）

三层中间产物，每个都要维护。

### 修改建议

**不新增 /to-spec 命令。** 改 /brainstorm：

1. `/brainstorm` 输出时落盘到 `.claude/specs/YYYY-MM-DD-<req>.md`（含验收标准、数据流、边界条件）
2. `/plan` 自动读取最新的 spec，作为输入
3. **触发条件硬编码进 workflow.md**：
   - 触发：跨模块 / 涉及状态机 / 涉及主子表 / 用户主动说"复杂需求"
   - 跳过：单文件文案修改 / ≤3 个文件 / 用户已给明确验收标准

这样既有"spec"，又不增加新命令。`/decompose` 的 6 要素作为后续 /plan 的细化输入，不重复。

### 触发问题 2 的回答

> /to-spec 简单需求是否过度设计？

**是的，过度设计。** 简单需求（<3 文件、纯文案、有明确验收）走 spec = 仪式感 > 价值。关键不是要不要 spec，而是 spec **什么时候必需**。建议用判定条件内嵌到 workflow 而非独立命令。

---

## 提案 C：/debug 六步诊断循环 — 评审：**改动方向对，但命名冗余**

### 现状评估

`.claude/skills/debug/SKILL.md`（2026-07-28 已借鉴 mattpocock）已经有：

- 步骤 0：建立可复现反馈回路（5 种构造方法）
- 步骤 1-5：标准诊断（读错→找行→上下文→git diff→最小修复）
- 步骤 6：验证修复
- 步骤 7：停止条件（2 次无效）

实际上**已经有 7 步**（含 reproduce 反馈回路 + 停止条件）。提案说"补全 minimise→hypothesise→instrument"——但：

- **minimise** 在"最小修复，修一处验证一处"中已经隐含
- **hypothesise** 在"提出修复方案 + 解释影响范围，等待用户确认"中已经隐含
- **instrument** 在"读完整报错 + Read 上下文（前后 20 行）"中已经隐含

**问题是这些阶段没有命名**。AI 在执行时确实在做，但没显式说"我现在在 hypothesise 阶段"。

### 仪式感风险

把 6 步变成强制流程（reproduce→minimise→hypothesise→instrument→fix→regression-test）在快速修复场景下很重——比如改一个 `@TableLogic` 误用、调整 SQL 字段长度，根本不需要 hypothesise 和 instrument 步骤。

### 修改建议

**不增加步骤。** 做两件更轻的事：

1. **在 SKILL.md 现有 step 4（git diff）之后插入"复杂 bug 加做的两步"小节**：
   ```markdown
   ## 复杂 bug 加做的两步（非强制）

   **Hypothesise**：写一句"我猜原因是 X，证据是 Y"，不猜就停
   **Instrument**：如果 1 次修复失败，加日志或断点确认假设
   ```
   短，不破坏现有流程。

2. **新增 Bug 简报模板**（提案 C 也提到了，**这是真正有用的部分**）：
   - 现象：用户报"列表没数据"
   - 最小复现：3 步
   - 假设：useListTable tuple 未解构（基于 Vue warn）
   - 验证：grep `registerTable` in inventory/index.vue
   - 修复：1 行代码
   - 回归测试：等

   模板放 `.claude/templates/bug-brief.md`，由 `/debug` 命令在生成报告时引用。

### 触发问题 3 的回答

> 六步诊断循环在快速修复场景是否过重？

**是的，会过重。** 简单 bug 走全 6 步 = 1 分钟能修的事拖到 5 分钟。**关键是分流条件**：1 次修复成功 → 不走完整流程；2 次失败 → 进入 hypothesise+instrument。这正是现有 step 7 的精神，只是没有显式区分"简单 vs 复杂"。

---

## 提案 D：/deep-inspect 第 4 维度 — 评审：**目标工具找错**

### 事实错误

提案原文："当前 3 维度，增加第 4 维度：模块深度评估"。

但 `deep-inspect/SKILL.md` 的 3 步是：

1. 性能基准（k6/curl p95）
2. 视觉证据（Playwright 截图）
3. 无障碍审计（axe-core WCAG 2.2 AA）

这是**运行时质量审计**，不是**架构扫描**。

架构扫描**已经存在**：`skills/architecture-report/SKILL.md`，3 层：
- 第 1 层：架构总览（社区地图、跨社区耦合）
- 第 2 层：热点风险（Hub/Bridge/连接异常）
- 第 3 层：结构债务（知识缺口、大函数、图统计）

并且 `architecture-report` 已经在用 code-review-graph MCP 工具做数据驱动分析。

### 提案想要的东西

提案说的"接口/实现比、测试覆盖、依赖发散、注释密度"——这是**架构结构指标**，加到 deep-inspect 里既不解决 deep-inspect 的问题（运行时质量），也不解决 architecture-report 的盲点（架构指标覆盖不全）。

### 修改建议

**不修改 deep-inspect。** 修改 `architecture-report`：

在第 3 层"结构债务"下增加一个子节：

```markdown
### 第 4 子层：模块深度评估

| 指标 | MCP 工具 | 判定阈值 |
|---|---|---|
| 接口/实现比 | list_graph_stats_tool 按类聚合 | >3 警告 |
| 测试覆盖 | query_graph_tool pattern="tests_for" | 热点节点无测试 = P1 |
| 依赖发散 | get_bridge_nodes_tool | bridge_score > 0.7 = 瓶颈 |
| 注释密度 | 文件级 AST 扫描 | <5% 警告（JeecgBoot 业务代码基线） |
```

让 `architecture-report` 输出从 3 层变 4 层，而不是 `deep-inspect` 变 4 维度。这才是改对了地方。

---

## 遗漏的关键改进（用户问题 4 的回答）

> 整体优先级是否合理？有无遗漏的更关键改进？

提案漏了三个我认为更值得做的问题：

### 遗漏 1：规则全局加载导致上下文膨胀（优先级：最高）

**这是真问题，方案完全没碰。**

```
13/16 rules 用 glob "**/*" 或 "**/*.{java,vue,ts,sql,xml}"
= 每次新会话注入 ~3000 行规则
= 每次新会话消耗 ~3-5k tokens 仅用于"加载规则"
```

新增 CONTEXT.md 自动加载 = 让这个问题从 3500 行变 4500 行。新增 /to-spec 命令不会加重（命令按需触发），但 /debug 复杂步骤改造可能让调试技能体量上升。

**改进**：

1. 审计 16 个规则，给每个加最严格的 glob。例如：
   - `debugging.md` → 保留 `**/*`（通用，但 165 行偏长）
   - `code-style.md` (506 行) → 拆分为 core（基础，所有项目） + platform-specific（JeecgBoot 模式，加更严 glob）
   - `engineering-artifacts.md` (365 行) → 只在涉及 PRD/plan 文件时加载
   - `deploy-quality-gate.md` → 只在 Bash 涉及 docker/deploy 时加载
2. 引入"规则使用率"统计（hooks 记录哪个规则文件被实际引用过）

### 遗漏 2：技能使用率黑盒

56 个 skills + 9 个 commands 子目录 = **大量候选**。但：

- 哪些 skill 被实际调用过？（无遥测）
- 哪些 skill 是死代码？
- 哪些 skill 描述过长，触发匹配率低？

**改进**：

1. 在 hooks 里加 Skill 调用计数（PostToolUse matcher=Skill）
2. 跑 1 个月后输出技能使用热力图，砍掉调用率 <5% 的技能

这比新加 1 个技能更有价值。

### 遗漏 3：MEMORY.md / learnings 无过期机制

MEMORY.md 50+ 条 learnings，最早 2026-07-04。**没有标记"过期"或"仅适用某版本"**的机制。JeecgBoot 升级到 V3.7 后，一些 learnings 可能失效但仍被引用。

**改进**：

1. 给 learnings 加 frontmatter `valid_until: YYYY-MM-DD` 或 `jeecg_version: <=X.Y`
2. `/learn` 时如果 learnings 引用过时接口/API，自动标记 `stale: true`
3. `/plan` 时如果引用的 learning 已 stale，提示重新验证

---

## 优先级重排建议

| 原优先级 | 重排后 | 改动 | 工期估计 |
|---|---|---|---|
| A. CONTEXT.md（不通过） | **删** | — | — |
| B. /to-spec（不通过） | **改造为 /brainstorm 持久化**（建议 1） | 1 命令 + 1 workflow 段 | 2h |
| C. /debug 六步（不通过原方案） | **改造为"复杂 bug 加做两步"+ Bug 简报模板**（建议 2） | 1 技能段 + 1 模板 | 1h |
| D. /deep-inspect 第 4 维度（找错工具） | **改造为 architecture-report 第 4 子层** | 1 技能扩展 | 1h |
| （提案外）遗漏 1：规则全局加载 | **优先级最高，先做** | 规则审计 + glob 重写 | 4-6h |
| （提案外）遗漏 2：技能使用率 | 建议下个迭代 | 1 hook + 1 dashboard | 3h |
| （提案外）遗漏 3：learnings 过期机制 | 后续迭代 | frontmatter + /learn 改造 | 4h |

**推荐顺序**：规则审计 → /brainstorm 持久化 → /debug Bug 模板 → architecture-report 第 4 子层 → learnings 过期机制 → 技能使用率统计。

总投入 ~13-16h，覆盖 6 件事，**比原方案（4 件，预计 ~12h）差不多**，但消除了 2 个高仪式感改动。

---

## 决策建议

| 行动 | 推荐度 |
|---|---|
| 直接通过原 4 步方案 | 不推荐。仪式感 > 实际价值，且 D 项工具错位 |
| 重排后做规则审计 + 3 个轻量化改造 | **推荐**。前 4-6h 立刻见效 |
| 全做（含技能统计 + 过期机制） | 中期迭代。当前阶段不必 |
| 维持现状不优化 | 不推荐。规则加载过重是真实成本 |

---

## 评审附记

- **有效信号**：方案识别了三个真实痛点（Harness 内上下文传递、断点到修复的追踪、AI 在大需求前的派工模糊）。方向没错。
- **风险信号**：每个改动都在**加法**（加文件、加命令、加步骤），没人提**减法**。50+ skills + 16 rules + 9 commands 的 Harness 已经有积压症状，新增的边际收益递减。
- **个人直觉**：原方案如果落地，6 个月内会出现 `audit-classification.md` 提到的"第 17 个待维护文件"问题，`/to-spec` 会被 /decompose 取代变成僵尸命令，`/debug` 的 6 步在 80% 的小修场景下被绕过。**真正可持续的优化是减法优先，加法看边际收益。**

---

## 元数据

- **关联文件**：`.claude/rules/*.md`, `.claude/skills/{debug,deep-inspect,architecture-report,decompose}/SKILL.md`, `.claude/memory/MEMORY.md`, `.claude/commands/dev/brainstorm.md`, `.claude/skills/plan/SKILL.md`
- **建议落地人**：Harness 维护者（建议先做规则审计 4-6h，再讨论其余 3 项）
- **下次评审触发**：规则审计完成 + 1 周使用数据后
