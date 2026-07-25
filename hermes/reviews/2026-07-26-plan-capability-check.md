# 评审：MCP 能力检测 + 降级透明化方案

**评审日期：** 2026-07-26
**方案文件：** `/Users/ruisuyun/.claude/plans/abstract-spinning-dewdrop.md`
**评审人：** Claude Code (Harness 架构视角)

---

## 评审结论

**方案方向正确但覆盖盲区大——仅靠修改命令+技能中的 markdown 提示文字，能提升命令模式下的降级可见性，但覆盖不了占比更高的自由对话场景。且 16 个文件分散修改的维护成本与收益不成比例。建议：CLAUDE.md 加 1 行降级声明覆盖全局 + P0 两个技能加强阻断 + /capability-check 做诊断入口，砍掉其余 14 个文件的修改。**

---

## ✅ 思路对齐

### 1. P0/P1/P2 三级分类合理
- P0（architecture-report、dead-code-check）正确地识别了 100% 依赖 MCP 的命令。这两个技能的核心工具（`get_architecture_overview_tool`、`refactor_tool(dead_code)`）没有 Grep/Read 等效替代，阻断是正确的。
- P1（review、verify、debug）的"显著增强"定位准确——这些命令的核心逻辑在 7 类审查/变更映射/报错速查中，MCP 提供的是架构加权和调用链追踪的增量价值。
- P2（gen-tests、test-*、harness-check）的"锦上添花"定位符合实际——测试生成和运行的骨干不依赖图形。

### 2. /capability-check 作为独立诊断命令有价值
- 三阶段探测（基础设施→图谱状态→代表性工具）设计完整，能区分"未安装 MCP"和"已安装但图谱未构建"两种场景。
- 对新客户端接入时的故障排查有实际帮助。

### 3. 不新增 rule 文件的 token 考量方向正确
- Rules 常驻上下文，每个 rule 文件消耗每次会话的 token 预算。方案选择把降级声明嵌入按需加载的 skill/command 中，省常驻 token 的思路是对的。

### 4. 降级声明格式具体可操作
- `⚠️ 降级：{工具名} 不可用 → 改用 {替代方案}（影响：{具体影响}）` 格式清晰、信息完整。AI 能可靠地按模板输出。

---

## ⚠️ 遗漏或风险

### 1. 🔴 自由对话场景完全漏覆盖（最大盲区）

方案只覆盖了 5 个命令路径（/review、/verify、/debug、/architecture-report、/dead-code-check），但 CLAUDE.md 中的 MCP 指令是全局生效的：

```
ALWAYS use the code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore the codebase.
```

这条指令加载在**每次会话的系统提示中**。当用户不说 `/review` 而是直接问"帮我看下采购入库的 Service 逻辑"，AI 会：
1. 受 CLAUDE.md 驱动尝试调用 MCP 工具
2. 发现工具不在列表中（MCP 未配置）
3. 静默回退到 Grep/Read
4. **没有任何命令/skill 被加载 → 降级声明永远不会触发**

而这类自由对话在实际使用中占比远高于显式命令调用。方案覆盖了 20% 的场景（命令模式），漏了 80%（自由对话）。

**证据：** 当前 review.md 的命令中已经写了"如果图形不可用：跳过，使用标准严重度逻辑"——这条指令 AI 确实遵守了（它跳过了），但 AI **没有告诉用户它跳过了**。问题不在于 AI 不遵守指令，而在于指令没有要求它输出。

### 2. 🟡 "≥2 次重试才算不可用" 无法可靠实现

方案规定：
> 仅 ALL calls 失败（≥2 次重试）才算不可用，单次超时不触发

AI 在一个 skill 调用内没有可靠的计数器状态。如果第一次调用超时、第二次成功，AI 大概率不会记得"这是第二次尝试"。这个规则对 AI 来说是模糊的——它看到的是每次独立的 tool call 结果，没有"这是第几次重试"的上下文。

**建议：** 简化为"工具调用返回错误或不在工具列表中即视为不可用"。单次超时在 Claude Code 层面已有重试机制，不需要 AI 再做一层计数。

### 3. 🟡 命令文件中出现具体工具名称 → 违反 skill-command-boundary

方案在修改 review.md 时写了：
> 尝试 `get_minimal_context_tool` → 不可用时输出降级声明 → 跳过步骤 2

`get_minimal_context_tool` 是具体的 MCP 工具名。按 `skill-command-boundary.md` 的判断标准：
> "这行内容如果换一个项目（如从 JeecgBoot 换成 RuoYi），还需要改吗？"
> 需要改 → 属于技能/领域知识

MCP 工具名是 JeecgBoot 项目特有的（code-review-graph），换项目必然要改。按照现有规则，**工具名应放在 skill 文件中，命令文件只引用 skill**。

**对比现有写法（合规）：**
```markdown
### 2. 架构上下文获取（可选增强）
使用技能中的架构感知参数调用 MCP graph tools。
- 如果图形可用：...
- 如果图形不可用：跳过
```
工具名在 skill 中，命令只说"调用 MCP graph tools"。

**方案写法（违规）：**
```markdown
### 1.5. MCP 可用性检查
尝试 `get_minimal_context_tool` → 不可用时输出降级声明 → 跳过步骤 2
```
具体工具名 `get_minimal_context_tool` 泄漏到命令文件。

**影响：** 如果将来换用其他 MCP 服务（如 sourcegraph、codebundles），需要同时修改命令文件和技能文件——边界模糊化违背了 skill-command-boundary 规则的设计初衷。

### 4. 🟡 P0 阻断"停止执行"无法强制执行

方案对 P0 命令的处理：
> 不可用时输出 `❌ 阻断` 并**停止执行**

Markdown 提示文字可以让 AI **输出**"❌ 阻断"的消息，但无法**强制** AI 真的停止。AI 可能在输出消息后继续往下执行（"虽然不可用但我帮你用 Read 方式做..."）。

**对比 hook 方案：** 一个 pre-command hook 可以在命令启动前检查 MCP 状态，不满足条件时直接拒绝执行并返回错误。这是真正的阻断。

**纯 prompt 能做到的最好效果：** 在 P0 skill 的降级声明中写"**禁止**在 MCP 不可用时继续执行任何后续步骤。输出 ❌ 阻断后立即结束，**不得**尝试用 Grep/Read 替代。"——增加"禁止"和"不得"的强度，但没有 hook 的硬保证。

### 5. 🟡 16 个文件分散修改 → 维护噩梦

| 修改类型 | 文件数 |
|----------|:-----:|
| 新增命令+技能 | 2 |
| 修改命令 | 5 |
| 修改技能 | 11 |
| **合计** | **18** |

降级声明的格式和措辞分散在 11 个 skill 文件中。如果未来需要调整格式（比如加"影响等级"字段、改为英文、适配新的 MCP 服务），需要修改 11 个文件并保持一致性。这违反了 DRY 原则。

### 6. 🟢 次要遗漏：未覆盖 CLAUDE.md 已加载的 MCP 工具列表

方案没有提及一个关键细节：在 Claude Code 中，MCP 工具的可用性信息已经在系统提示中（工具列表）。Claude Code 的系统提示中包含了所有可用工具的完整 schema。AI **已经知道**哪些 MCP 工具可用、哪些不可用——不需要做探测调用。

这意味着 `/capability-check` 的 Stage 1 探测（"MCP 服务是否安装"）可以通过检查工具列表完成，不需要实际调用 `ListMcpResourcesTool`。但 Stage 2（"图谱是否构建"）确实需要调用 `list_graph_stats_tool` 来确认。

---

## 💡 优化建议

### 1. 🔑 核心改动：CLAUDE.md 加 1 行 ≈ 覆盖全局

**当前 CLAUDE.md（系统提示中加载）：**
```
**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.**
```

**建议追加 1 行：**
```
**IMPORTANT: This project has a knowledge graph. ALWAYS use the
code-review-graph MCP tools BEFORE using Grep/Glob/Read to explore
the codebase.** 如果 MCP 工具不可用（不在工具列表中或调用失败），
必须在对话中显式输出 `⚠️ 降级：code-review-graph MCP 不可用 →
改用 Grep/Read（影响：失去架构感知能力）`，然后继续降级执行。
```

**为什么这比方案好：**
- **覆盖自由对话**：CLAUDE.md 每次会话都加载 → 自由对话中 MCP 不可用时 AI 也会输出降级声明
- **1 行改动 vs 18 个文件**：维护成本天差地别
- **不违反任何现有规则**：CLAUDE.md 本身就是全局指令的存放地
- **Token 成本极低**：~50 tokens 常驻，比 1 个 rule 文件还少

### 2. P0 阻断：保留两个 skill 的加强版，其余 14 个文件不改

**只改这 2 个 skill：**
- `skills/architecture-report/SKILL.md` — 在降级策略段改为硬阻断声明
- `skills/dead-code-check/SKILL.md` — 同上

**改动内容（示例，architecture-report）：**
```markdown
## 降级策略（硬阻断）

**此命令 100% 依赖 code-review-graph MCP。MCP 不可用时必须阻断，不得降级。**

MCP 不可用时：
1. 输出：`❌ 阻断：architecture-report 100% 依赖 code-review-graph MCP，
   请先安装 MCP 服务并运行 build_or_update_graph_tool 构建图谱。
   配置指引：/capability-check`
2. **停止执行。禁止**使用 Grep/Read 或任何替代方式继续。
```

**不改的 14 个文件：**
- 5 个命令文件（review/verify/debug/architecture-report/dead-code-check）—— P1 降级声明已被 CLAUDE.md 全局覆盖，命令内的 Step-0 检查多余
- 9 个 P2 skill 文件（gen-tests、test-api、test-e2e、test-frontend、test-all、harness-check 等）—— P2 影响小，CLAUDE.md 全局声明已足够，不值得为"锦上添花"的降级各改一个文件

### 3. /capability-check 保留，但简化

保留 `/capability-check` 命令+技能作为诊断工具，但做以下调整：

- **去掉"修复引导"（Step 5）**：让 AI 引导用户配置 MCP 容易出错且安全风险高（可能误改 settings.json）。改为输出配置文档路径即可。
- **Stage 1 改为检查工具列表**而非调用 `ListMcpResourcesTool`：更轻量，且不依赖 MCP 本身可用。
- **命令文件中的探测步骤泛化**：写"按技能中的探测流程检查 MCP 可用性"，不写具体工具名。

### 4. 可选增强：session-start hook 注入 MCP 状态标记

如果未来需要更强的保证，在 session-start hook 中加一段：

```bash
# 检查 MCP 工具是否在工具列表中
if ! grep -q "code-review-graph" <<< "$CLAUDE_MCP_TOOLS" 2>/dev/null; then
  echo "⚠️ MCP code-review-graph 不可用，本次会话将降级到 Grep/Read"
fi
```

但前提是 Claude Code 提供了检测 MCP 可用性的环境变量（当前不确定）。不依赖此方案，作为未来演进方向。

### 5. 降级声明的"≥2次重试"规则删除

理由见风险 #2。改为简单的"工具不在列表中或调用返回错误即视为不可用"。

---

## 对比：原方案 vs 简化方案

| 维度 | 原方案 | 简化方案 |
|------|--------|---------|
| 修改文件数 | 18 个 | 4 个（CLAUDE.md + 2 skill + /capability-check） |
| 覆盖自由对话 | ❌ 不覆盖 | ✅ CLAUDE.md 全局覆盖 |
| 覆盖命令模式 | ✅ 5 个命令 | ✅ CLAUDE.md + 2 个 P0 skill |
| P0 阻断强度 | prompt 级别（可绕过） | prompt 级别（可绕过，但措辞更强） |
| 维护复杂度 | 高（11 个 skill 各维护降级声明） | 低（CLAUDE.md 统一声明） |
| Token 增量 | ~350 行按需 + 0 常驻 | ~3 行按需 + ~50 tokens 常驻 |
| 违反 skill-command-boundary | 🟡 命令文件泄漏工具名 | ✅ 不违反 |
| 能否真正阻止静默降级 | 部分（仅命令模式） | 较好（全局覆盖，但不能 100% 保证） |

---

## 最终建议

**核心结论：p0 阻断可以靠 prompt，但全局降级可见性需要从 CLAUDE.md 入手，不能只靠命令+技能。**

1. **CLAUDE.md 加 1 行降级声明** → 覆盖率从 ~20% 提升到 ~95%
2. **P0 两个 skill 加强阻断措辞** → 和方案一致
3. **/capability-check 保留** → 诊断工具独立价值
4. **砍掉其余 14 个文件的修改** → 省维护成本
5. **删除"≥2次重试"规则** → 简化逻辑
6. **注意命令文件不放工具名** → 遵守 skill-command-boundary

**对核心问题的回答：仅靠修改 skill/command 中的 markdown 提示文字，能可靠改变 AI 行为吗？**

在**命令模式**下——能，因为命令文件被显式读取后 AI 会遵循其中的输出格式要求。但**自由对话**场景下——不能，因为 AI 根本不会加载那些 skill/command 文件。这是原方案最大的盲区。

解决方案不是否定 prompt 方案（它确实有效），而是把降级声明放到**一定会被加载的上下文**中——即 CLAUDE.md。

[REVIEW_DONE]
