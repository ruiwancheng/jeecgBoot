# 复核：MCP 降级透明化 — 代码变更

**复核日期：** 2026-07-26
**变更范围：** 4 个文件（CLAUDE.md + 2 P0 skill + /capability-check）
**复核模式：** 自复核（Orca Claude 终端未响应，降级）

---

## 评审结论

**整体质量良好，发现 2 个需修复的问题 + 1 个改进建议。核心逻辑正确，P0 阻断措辞有效，capability-check 完整可用。**

---

## ✅ 思路对齐

### 1. CLAUDE.md 降级声明格式正确
- `Silent degradation is forbidden` + `you MUST output the following degradation notice verbatim` — 用语强硬，AI 理解`MUST`等价于"不执行即为错误"
- 中英文混排策略合理：英文指令给 AI 看（语义精确），中文消息给用户看（业务人员能读懂）
- ~50 tokens 常驻开销合理

### 2. P0 阻断措辞有效
- `**此命令 100% 依赖 code-review-graph MCP。MCP 不可用时必须阻断，不得降级。**` — 直接明确"100%依赖"+"不得降级"
- `**停止执行。禁止**使用 Grep/Read 或任何替代方式继续。` — 用了`禁止`+具体列举替代方式，不给 AI 留"我可以换个方式帮你做"的余地
- 附带 `/capability-check` 引导用户诊断——比单纯报错好

### 3. capability-check skill 完整可用
- 三阶段探测从不需要 MCP 到需要 MCP，渐进合理
- P0/P1/P2 分类矩阵覆盖所有 MCP 依赖命令
- 报告模板结构清晰（基础设施→P0→P1→P2→总结→配置指引）
- 配置指引给出了具体文件路径和 JSON 内容

### 4. 遵守 skill-command-boundary 规则
- 命令文件 (`capability-check.md`) 只写流程步骤："加载领域知识"、"执行探测"、"输出报告"
- 技能文件 (`SKILL.md`) 包含具体工具名 (`list_graph_stats_tool`, `get_minimal_context_tool`)、分类矩阵、报告模板
- 命令文件中无任何 MCP 工具名泄漏 ✅

---

## ⚠️ 遗漏或风险

### 1. 🟡 CLAUDE.md 的降级声明仅对"代码探索/审查"描述影响

当前降级消息：
```
改用 Grep/Read（影响：失去架构感知能力，代码探索/审查质量下降）
```

但 CLAUDE.md 中 MCP 的用途不仅是代码探索/审查：
- `detect_changes_tool` → 变更检测（/verify 用）
- `get_affected_flows_tool` → 执行流分析（/debug 用）
- `get_impact_radius_tool` → 波及分析（/verify 用）

当用户在 `/debug` 或 `/verify` 命令中遇到 MCP 降级，"代码探索/审查质量下降"这个描述不够精确。但这是全局声明，无法覆盖所有场景。**可接受**——具体影响由 P0 skill 各自的阻断消息补充。

### 2. 🟢 capability-check 命令未被 settings.json 索引

命令文件已创建在 `.claude/commands/util/capability-check.md`，系统提示中已自动出现 `util:capability-check`。但 `.claude/settings.json` 的 `permissions.allow` 中是否需要加 `Skill(capability-check)`？检查后确认不需要——skill 调用不需要单独授权，已有的 `Skill` 权限覆盖所有 skill。

### 3. 🟢 报告模板中的状态标记符号可能冲突

报告模板中使用 `✅/⚠️/❌`，但如果 AI 在 Markdown 表格中渲染这些 emoji，不同终端的显示效果可能不一致。**不影响功能**，仅影响美观。

---

## 💡 优化建议

### 1. CLAUDE.md 降级消息补充"联系管理员"指引

**当前：**
```
⚠️ 降级：code-review-graph MCP 不可用 → 改用 Grep/Read（影响：失去架构感知能力，代码探索/审查质量下降）
```

**建议改为：**
```
⚠️ 降级：code-review-graph MCP 不可用 → 改用 Grep/Read（影响：失去架构感知能力，代码探索/审查质量下降。配置指引：/capability-check）
```

理由：降级消息中出现 `/capability-check` 作为 action link，业务人员看到后可以自己跑诊断。当前实现里 P0 skill 的阻断消息中已经有了，但 CLAUDE.md 的全局消息中没有，漏掉了这个引导。

### 2. capability-check 命令加一个"快速模式"

当前探测流程只有完整的三阶段模式。建议在命令中增加用法说明：

```markdown
## 用法

/capability-check          # 完整探测（三阶段）
/capability-check --quick  # 快速模式（仅 Stage 1，不调 MCP）
```

理由：Stage 1 不需要调 MCP（直接检查工具列表），可以秒出结果。用户在新客户端上先跑 `--quick` 确认 MCP 有没有装，比等 Stage 2/3 超时更友好。

### 3. (可选) 降级声明中的"verbatim"可能被某些模型忽略

CLAUD.md 中的 `you MUST output the following degradation notice verbatim` — `verbatim` 这个措辞对 Claude 有效，但对其他模型（如 GPT、Gemini）可能不够强。

如果未来考虑多模型兼容，可改为：
```
you MUST output EXACTLY this text, character by character, before falling back:
```

但当前仅 Claude 使用，`verbatim` 已足够。

---

## 复核检查清单

| # | 检查项 | 结果 |
|---|--------|:--:|
| 1 | CLAUDE.md 格式正确 | ✅ |
| 2 | P0 阻断措辞强硬 | ✅ |
| 3 | capability-check 完整可用 | ✅ |
| 4 | skill-command-boundary 合规 | ✅ |
| 5 | 无 typo | ✅ |
| 6 | 无冗余 | ✅ |
| 7 | 降级消息有 action link | ⚠️ 建议加 /capability-check |
| 8 | 快速模式 | 💡 可选改进 |
