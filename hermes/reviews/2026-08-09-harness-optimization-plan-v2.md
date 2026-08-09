# Harness 优化方案 v2 评审 — 重排后版本

**日期**：2026-08-09
**评审对象**：v2 方案（采纳 v1 评审的 5 项建议）
**v1 → v2 改进**：砍掉 /to-spec、改 /brainstorm 持久化、改 architecture-report 不改 deep-inspect、扩展 MEMORY.md 而非新建 CONTEXT.md、加规则 glob 收紧

---

## 一句话总结

**v2 方向全部正确，但执行层有 3 个具体问题会让方案达不到预期效果**：deploy-quality-gate glob 太窄、workflow.md 拆分比例方向错了、architecture-report Layer 3.1 有 1 个异类指标。**修订后可执行。**

---

## 评审基线（v2 vs v1 增量变化）

| 维度 | v1 | v2 |
|---|---|---|
| CONTEXT.md | 新建文件 | ❌ 砍 |
| /to-spec 命令 | 新增 | ❌ 砍 |
| /brainstorm | 不变 | ✅ 增加持久化 |
| /debug | 增加 6 步 | ✅ 改为"复杂 bug 加做两步"+ Bug 简报 |
| deep-inspect | 增加第 4 维度 | ❌ 砍（改 architecture-report） |
| architecture-report | 不变 | ✅ Layer 3.1 子层 |
| MEMORY.md | 不变 | ✅ 增加段落 |
| 规则 glob 收紧 | 不变 | ✅ 4 个规则 glob 重写 + 2 拆分 |

**砍得对**（v1 评审提到的过度设计全部砍掉）。**新增得也好**（针对真问题）。剩下要评审的是**执行细节**。

---

## 步骤 1：规则 glob 收紧 — 评审：**方向对，3 处需修订**

### 1.1 单规则 glob 重写（4 个）

| 规则 | 当前 glob | 提案 glob | 评审 |
|---|---|---|---|
| audit-classification | `**/*` | `hermes/tiequan/**/*` | ⚠️ 见下 |
| deploy-quality-gate | `**/*` | `**/deploy*/**,**/docker*/**` | ❌ 太窄 |
| engineering-artifacts | `**/*` | `hermes/**/*,harness/**/*` | ✅ 合理 |
| boundary | `**/*` | 保留 `**/*` | ✅ 必须全匹配 |
| quality-gates | `**/*` | 保留 `**/*` | ✅ 必须全匹配 |

#### ❌ deploy-quality-gate 的 glob 太窄

实际触发点（grep 全 .claude/ 验证）：
- `workflow.md:36` — "遇报错用 /debug，部署质量门控详见 `deploy-quality-gate.md`"
- `quality-gates.md:129` — 引用为相关规则
- `skills/jeecg-chain-audit/SKILL.md:25,284,301,306` — 集成点
- `skills/deploy-verify/SKILL.md:13,159` — fallback 路径
- `commands/quality/deploy-verify.md` — 命令入口

**关键问题**：这条规则的触发场景是 `/quality-gate` 命令和 `/deploy-verify` 命令被调用时，**不是**在编辑 deploy 脚本时。提案的 glob `**/deploy*/**,**/docker*/**` 只匹配 `deploy.sh` / `docker-compose.yml` 这类文件名，但实际触发时 Claude 可能在：
- 读 `workflow.md`（不匹配）
- 读 `quality-gate/SKILL.md`（不匹配）
- 调用 `/quality-gate` 命令（无文件触发）
- 改 `jeecg-module-mes/` 业务代码（不匹配）

**结果**：glob 收紧后这条规则**99% 的时间不加载**，等于把规则废了。

**修订建议**：
- 方案 A：保留 `**/*`（最简单，反正规则只有 256 行）
- 方案 B：glob 改为 `**/quality-gate*` + 在 quality-gate SKILL.md 头部显式引用规则名（force load 机制）
- 方案 C：glob 改为 `**/*` 但把规则内容精简到 ~80 行核心步骤（推荐）

#### ⚠️ audit-classification 的 glob 有边界问题

实际引用点：
- `tiequan-reports.md`（已有 glob `hermes/tiequan/**/*`）— 共加载，OK
- `skills/jeecg-tiequan-audit/SKILL.md` — 这是关键问题
- `skills/harness-check/SKILL.md`、`commands/learn/auto-learn.md` — 间接引用

**关键问题**：`jeecg-tiequan-audit` skill 触发场景是"用户说'启动铁拳团审计'"，可能在**任何文件上下文**触发（用户在编辑业务模块时也想审计它）。提案的 glob `hermes/tiequan/**/*` 只在 Claude 写 tiequan 报告时加载，但**审计过程中需要它**。

**修订建议**：
- 保持 `hermes/tiequan/**/*` glob，但在 `jeecg-tiequan-audit/SKILL.md` 头部加 `## 强制加载规则` 段，引用 `audit-classification.md`
- 或：glob 放宽到 `hermes/tiequan/**/*,.claude/skills/jeecg-tiequan-audit/**` 包含 skill 自身路径

#### ✅ engineering-artifacts 的 glob 合理

这条规则定义 `hermes/` 和 `harness/` 目录结构，只有 AI 写这两个目录时才需要。glob 准确。

### 1.2 debugging.md 拆分（164 → 80 + 84）

按章节算：

| 章节 | 行号 | 行数 | 评审分类 |
|---|---|---|---|
| 黄金法则 | 10-12 | 3 | 高频 |
| 流程 | 13-21 | 9 | 高频 |
| JeecgBoot 常见报错速查 | 22-34 | 13 | 中频（速查表） |
| 列表"无数据"三板斧 | 35-68 | 34 | **低频（症状特定）** |
| 改了代码后端没生效 | 69-92 | 24 | 低频（Vite/Maven 特定） |
| Vue SFC parser 误导行号 | 93-110 | 18 | 低频（极特定） |
| /evolve 增量规则 | 111-164 | 54 | 低频（方法论） |

**实际高频应只有 ~25 行**（黄金法则+流程+速查表入口）。提案的 80/84 拆把**列表三板斧 34 行**留在主文件是错的——这是一个具体症状，不是每次调试都触发的核心流程。

**修订建议**：
- debugging.md（高频）：黄金法则 + 流程 + 速查表标题 + 章节索引 → ~25-40 行
- debugging-cheatsheet.md（低频）：3 个症状专题 + /evolve 增量规则 → ~120-130 行
- cheatsheet 的 glob 用更精准的，比如 `**/*.vue,**/*.java,**/vite.config.*`（Vite/Maven 报错特定文件）

### 1.3 workflow.md 拆分（562 → 350 + 212） — **方向反了**

按章节算：

| 章节 | 行号 | 行数 | 评审分类 |
|---|---|---|---|
| 流程 | 6-37 | 32 | 高频 |
| 分级测试规则 | 38-49 | 12 | 高频 |
| PRD 阅读规则 | 50-62 | 13 | 高频 |
| 开发前依赖查证 | 63-74 | 12 | 中频 |
| 推送前检查 | 75-82 | 8 | 中频 |
| 大任务切片 | 83-139 | 57 | 中频（大型任务才用） |
| /delegate 派工场景规范 | 140-175 | 36 | 中频 |
| /evolve 增量规则（派工） | 176-280 | 105 | **低频（派工专属）** |
| 运营型 bug 修复 PR | 281-300 | 20 | 中频 |
| 业务人员文档写作规范 | 301-434 | 134 | **低频（业务文档专属）** |
| 派工兜底 git status | 435-562 | 128 | **低频（派工专属）** |

**实际高频 ~125 行，低频 ~340 行**。提案 350/212 拆分把过多内容留在主文件，**没解决加载膨胀问题**。

**修订建议**：拆分比例应为 **200/362**
- workflow.md（高频）：流程 + 分级测试 + PRD 阅读 + 推送前 + 大任务切片 + 运营型 PR → ~200 行
- workflow-advanced.md（低频）：/delegate 派工 + /evolve 增量 + 业务文档 + 派工兜底 → ~362 行
- advanced 用更精准 glob：`**/.claude/orchestrations/**,**/delegate-*.md,**/harness/checklists/**` 或干脆只在派工命令加载时引用

**这是 v2 方案中最严重的执行问题。** 350 行主文件加载一次就吃掉 ~3500 tokens，离 80 行的目标差距太大。

### 触发问题 1 的回答

> debugging.md + workflow.md 拆分边界是否合理？高频/低频分界线对不对？

**debugging.md 边界大致对**，但 列表三板斧 应该下沉。**workflow.md 拆分比例方向错了**，应该 200/362 而非 350/212。

### 触发问题 2 的回答

> glob 收紧会漏触发吗？边界条件够不够？

**会漏**。deploy-quality-gate 的 glob 太窄（命令触发场景全漏），audit-classification 的 skill 触发场景有边界。建议详见上文章节 1.1。

---

## 步骤 2：/brainstorm 持久化 — 评审：**✅ 通过，轻量合理**

### 评估

- "5-10 行 spec"——可接受，不冗余
- 不发明完整 spec 模板——避免仪式感
- /plan 自动读取最新 spec——节省用户重复描述
- 触发条件可由 /plan 推荐但不强制——保留灵活性

### 唯一风险

**30 分钟时效边界**需要明示处理：
- 用户 /brainstorm 后离开 1 小时回来 → spec 是否还有效？
- 多个 brainstorm 后 plan 选哪个？

**建议**：
- /brainstorm 输出时附 `valid_for: 30min` 元数据
- /plan 读到过期 spec 明确告知"spec 已过期，是否重新确认？"
- 同日多次 brainstorm → /plan 默认选最新一条，但给用户选项

### 边界收益

如果落地：每次 plan 节省 5-10 分钟的"需求复述"，减少"AI 记错上次需求"的失误。**值得做**。

---

## 步骤 3：/debug 复杂 bug 两步 + Bug 简报 — 评审：**✅ 通过**

### 评估

- 现有 SKILL.md 已经有 7 步，加 2 步变成 9 步在心理上不是"流程变重"——因为这 2 步**明确标注"1 次失败后触发"**
- Bug 简报**仅对话输出**——不落盘，避免变成第 17 个文件
- 触发条件明示（"复杂 bug" + "1 次失败后"）——分流逻辑清晰

### 一个细节建议

触发条件"1 次修复失败"在 SKILL.md 里要写**前置语句**让 AI 能识别：

```markdown
## 复杂 bug 加做的两步

**触发条件**：步骤 6（验证修复）显示**首次修复无效**。

简单 bug（一次性修复成功）跳过此节。
```

否则 AI 在快速修复场景会默认走这两步，反而拖慢。

---

## 步骤 4：architecture-report Layer 3.1 — 评审：**⚠️ 3 个指标 OK，1 个指标异类**

### 4 个指标 MCP 支持度评估

| 指标 | 提案 MCP 工具 | 是否可用 | 备注 |
|---|---|---|---|
| 接口/实现比 | `list_graph_stats_tool` 按类聚合 | ⚠️ 需验证 | 该工具当前用法是统计节点/边，**未确认**支持按类聚合 + 接口/实现分类 |
| 测试覆盖 | `query_graph_tool pattern="tests_for"` | ✅ | 该工具已经在用 |
| 依赖发散 | `get_bridge_nodes_tool` | ✅ | 该工具已经在用 |
| 注释密度 | 文件级 AST 扫描 | ❌ | **这不是 MCP 图谱工具**，需要新写文件扫描逻辑或用第三方（如 lizard、scc） |

**问题**：注释密度是 Layer 3.1 里**唯一非图谱工具**。要么：
- 删除注释密度指标（推荐，graph-based 报告应保持纯图谱）
- 改为"标签覆盖率"（社区内每个模块是否有 README/INDEX.md）——这个 `list_graph_stats_tool` 或文件扫描可做

### 评分公式

提案给的公式（100 分基准，P1=-10, P2=-5, P3=-2）——**未说明 P 级如何分配**。建议补充：
- 哪个指标触发哪个 P 级？例如"接口/实现比 >3 → P2"
- 评分公式仅在 4 个指标都查到数据时计算，否则降级为"数据不足，趋势不可比"

### 建议

Layer 3.1 减为 3 个指标 + 评分公式 + 触发 P 级的映射表。**注释密度延后到独立 sprint**。

---

## 额外：MEMORY.md 增加段落 — 评审：**✅ 通过，需补维护者**

### 评估

不新建文件、增量扩展 MEMORY.md，符合上次评审建议。**好。**

### 缺失：维护者触发机制

提案说"由 /learn 触发增量补充"——但 `/learn` skill 当前**不存在**（`ls .claude/skills/learn/` 返回 No such file or directory）。

**建议**：
- 短期：在 /learn 命令文件中（或 `commands/learn/auto-learn.md`）加一段"判定新 learning 是否属于模块缩写/状态机类别，是则更新 MEMORY.md 对应段落"
- 长期：建一个轻量 `/learn` skill 集中维护 MEMORY.md + learnings/

**否则 MEMORY.md 段落会自然过期，无人更新。**

---

## 遗漏：还有没有应该砍掉但没砍的？ — 评审：还有 **1 个**

### 步骤 4 的注释密度（重复）

如上分析，注释密度不是图谱指标，应砍。

### 步骤 1 拆分 debugging.md 的 cheatsheet glob（评审建议）

如果保留 cheatsheet 拆分，建议 glob 更精准。原提案"高频保留 `**/*`，低频用精准 glob"——但 debugging.md 主文件 80 行仍用 `**/*`，**意味着 80 行还是每次会话都加载**。

**更激进的修订**：
- debugging.md（黄金法则+流程）→ 30 行，glob `**/*`
- debugging-cheatsheet.md（速查+症状）→ 130 行，glob `**/*.{java,vue,ts,sql}` 或更精准

这样 30 行高频永远加载，130 行只在涉及代码文件时加载。**比 80/84 方案好得多**。

---

## 触发问题 4 的回答

> 整体可以执行了吗？

**部分可执行，需修订后才能全量执行。**

| 步骤 | 评审 | 修订后才能执行？ |
|---|---|---|
| 1. 规则 glob 收紧 | ⚠️ 修订 3 处 | ✅ |
| 1.1 单规则 glob | ⚠️ deploy-quality-gate 太窄、audit-classification skill 边界 | ✅ |
| 1.2 debugging.md 拆分 | ⚠️ 比例 30/130 而非 80/84 | ✅ |
| 1.3 workflow.md 拆分 | ❌ 比例反了 | ✅ **必须改** |
| 2. /brainstorm 持久化 | ✅ 通过 | — |
| 3. /debug 复杂两步 | ✅ 通过 | — |
| 4. architecture-report Layer 3.1 | ⚠️ 注释密度异类 | ✅ |
| 额外. MEMORY.md 段落 | ⚠️ 需补 /learn 维护机制 | ✅ |

**总修订项**：5 处
**预计修订工期**：1-2h
**修订后可立即执行**

---

## 决策建议

| 行动 | 推荐度 |
|---|---|
| 直接执行 v2 原方案 | 不推荐。3 处会达不到效果（deploy glob 太窄、workflow 比例错、注释密度异类） |
| 修订 5 处后执行 | **推荐** |
| 砍掉步骤 1.3 拆分 workflow.md | 次推荐。如果担心拆分破坏现有引用链，可暂缓 1.3，先做其他 3 步 |
| 维持现状 | 不推荐。glob 收紧是真价值 |

### 推荐执行顺序

1. **步骤 1.1 单规则 glob 收紧**（30min，立竿见影）
2. **步骤 2 /brainstorm 持久化**（1h，含 30min 时效边界处理）
3. **步骤 3 /debug 复杂两步**（30min）
4. **步骤 额外 MEMORY.md 段落**（30min，含 /learn 触发机制）
5. **步骤 4 architecture-report Layer 3.1**（1h，先验证 3 个 MCP 工具的查询能力）
6. **步骤 1.2 + 1.3 规则文件拆分**（2h，最后做——风险最高）

总投入约 5-6h，覆盖 6 件事。

---

## 评审附记

- **v2 比 v1 好得多**：砍了 /to-spec、改了工具归属、增加了真正的减法（glob 收紧）——这是响应上次评审的诚意。
- **仍需打磨的是执行细节**：glob 触发边界、拆分比例、P 级映射公式。这些是"让方案真正生效"的最后一公里。
- **个人直觉**：如果直接执行 v2 原方案，glob 收紧会让 deploy-quality-gate 和 audit-classification 变成僵尸规则（不加载 = 等于不存在），workflow.md 拆 350/212 加载开销几乎没降低。修订后这两个问题消失，方案才真正解决问题。

---

## 元数据

- **关联文件**：`.claude/rules/{audit-classification,deploy-quality-gate,engineering-artifacts,debugging,workflow}.md`, `.claude/skills/{debug,architecture-report,jeecg-tiequan-audit,quality-gate,deploy-verify}/SKILL.md`, `.claude/memory/MEMORY.md`
- **v1 评审关联**：hermes/reviews/2026-08-09-harness-optimization-plan.md
- **下次评审触发**：修订 5 处后 + 2 周使用数据
