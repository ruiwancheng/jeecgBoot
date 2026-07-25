# 终审报告 — 采购全链路质量体系建设

**审查日期：** 2026-07-22
**审查人：** 终审专家（Claude Opus 4.8）
**审查范围：** 53 个文件，1215 行新增，89 行删除
**审查维度：** 一致性 / 遗漏 / 风险 / 过度设计

---

## 总体判定：🟢 PASS（7 个建议，0 个阻断）

本次会话建设的采购全链路质量体系结构完整、逻辑自洽。基础设施（deploy-quality-gate + business-chains.json + chain-audit）三者形成闭环：注册表声明依赖 → 门控自动触发验证 → 链路审计填补跨模块盲区。代码修复覆盖了所有 3 个采购模块（申请/订单/入库），链路测试 33 项全部通过。

以下 7 个建议按优先级排列，无阻断项。

---

## 一、整体一致性

### C1. ⚠️ JSON Schema 未覆盖 `chainTests`、`chainAudit`、`health` 字段

**严重度：** P2（不影响运行，文档不完整）

`business-chains.schema.json`（148行）定义了 chain 对象的基础属性（id、modules、flow 等），但 `business-chains.json` 实际使用的三个重要字段未出现在 schema 中：
- `chains.<name>.chainTests` — 链路测试配置
- `chains.<name>.health` — 链路健康状态
- 顶层 `chainAudit` — 链路审计配置

当前因为 `additionalProperties` 默认为 true，JSON 验证不会报错。但这些字段缺少类型约束，schema 失去了"文档+校验"的双重价值。

**建议：** 在 `business-chains.schema.json` 的 chain `properties` 中补充 `chainTests` 和 `health` 的 schema 定义；在顶层 `properties` 中补充 `chainAudit`。

---

### C2. ⚠️ 规则双写无权威来源声明

**严重度：** P2（当前一致，但维护风险）

以下信息在两个文件中重复定义：

| 信息 | 在 `deploy-quality-gate.md` | 在 `business-chains.json` |
|------|:--:|:--:|
| 变更分级规则 | 表格（第53-69行） | `changeClassification.levels` |
| 链路匹配规则 | 表格（第77-83行） | `chains.<name>.modules` |
| 失败处理策略 | "失败处理"表（第125-133行） | `qualityGate.failureStrategy` |

当前两者内容一致，但没有声明"谁是权威来源"。如果未来有人只改了一处，两处就会不同步——AI 读到的规则将自相矛盾。

**建议：** 在 `deploy-quality-gate.md` 开头加一句："**权威配置：** `hermes/business-chains.json` 是变更分级、链路匹配、失败策略的唯一权威来源。本文件中的同名表格仅供人类阅读参考，如有冲突以 JSON 为准。"

---

### C3. ⚠️ 链路审计触发条件在 skip 级别存在浪费

**严重度：** P3（边界 case，实际不太会发生）

`deploy-quality-gate.md` 第 107 行：
> 链路审计：变更涉及 ≥2 个模块时自动触发，**不依赖变更分级**

但 skip 级别（仅 .md / 注释 / 格式化变更）如果恰好涉及 2 个模块目录，也会触发链路审计。例如：在 `purchase/apply/` 和 `purchase/order/` 各改了一个注释 → 触发 5 分钟的链路审计 → 结果为空。

**建议：** 加一条防御规则："skip 级别时跳过链路审计（因为 skip 仅含 .md/注释/格式化变更，不影响代码行为）。"

---

## 二、遗漏

### O1. 🔴 `hermes/reviews/INDEX.md` 缺失

**严重度：** P1（违反 `engineering-artifacts.md` 强制规范）

`engineering-artifacts.md` 规定：
> 每个子目录必须有 `INDEX.md`（摘要 + 文件列表）

`hermes/reviews/` 目录目前有 16 个评审文件，但没有 `INDEX.md`。每次新增评审文件后也没有更新索引的流程。

**建议：** 创建 `hermes/reviews/INDEX.md`，列出所有已有评审文件的日期、文件名和说明。后续 deploy-quality-gate 或 /session-wrap 时检查并更新。

---

### O2. ⚠️ P0 指纹去重存储位置未定义

**严重度：** P2（影子模式期间不影响，但正式模式前必须解决）

`deploy-quality-gate.md` 第 184 行定义了 P0 指纹去重规则：
> 为每个 P0 生成指纹 `md5(模块+文件路径+行号+问题描述前50字符)`，与上一轮审计指纹集比对

但未定义"上一轮审计指纹集"存在哪里。而 `tiequan-report-retention.md` 规定"同模块再次审计时删除旧报告"，这意味着旧审计报告（含指纹）会被删除。

**建议：** 明确指纹存储方案，二选一：
- **方案 A（推荐）：** 在 `hermes/tiequan/` 下维护一个独立的 `p0-fingerprints.json`，永久保留（不随报告删除）
- **方案 B：** 修改 `tiequan-report-retention.md`，旧报告删除前提取指纹到新报告中

---

### O3. ⚠️ `skip-audit.log` 无轮转/清理机制

**严重度：** P3（短期内不会膨胀到有问题）

`engineering-artifacts.md` 规定 `hermes/logs/` 保留最近 7 天。但 `skip-audit.log` 是纯追加模式，没有按天轮转或按大小截断的机制。

当前文件内容为空数组 `[]`，不构成实际问题。但规则与实现之间存在 gap。

**建议：** 在 `/session-wrap` 或 deploy-quality-gate 的 Step 5 中追加一句：清理 `hermes/logs/skip-audit.log` 中超过 30 天的记录。或者接受"skip-audit 使用频率极低，不需要清理"的设计决策并在 engineering-artifacts.md 中加例外说明。

---

## 三、风险

### R1. ⚠️ 影子模式结束日期硬编码

**严重度：** P2（8月5日前无影响）

`business-chains.json` 第 167 行：
```json
"shadowMode": { "startDate": "2026-07-22", "endDate": "2026-08-05" }
```

如果 8 月 5 日到达但转正条件（误报率 < 20%，真实发现率 > 50%）未满足，行为未定义。AI 会看到"影子模式已过期"但"正式模式条件不满足"的矛盾状态。

**建议：** 将 `endDate` 改为 `reviewDate`（评审日期），语义从"结束"变为"下次评审"。同时补充规则："到达 reviewDate 时，如果转正条件不满足，自动延期 7 天并更新 reviewDate。"

---

### R2. ⚠️ 应付模块（finance/payable）在采购链路中是单向 sideEffect

**严重度：** P3（应付模块尚未建成，暂不影响）

采购链路配置：
```json
"modules": ["purchase/apply", "purchase/order", "purchase/receipt", "purchase/ledger"],
"sideEffects": ["finance/payable"]
```

这是单向声明：采购模块变更 → 触发采购链路验证。但反过来，如果 `finance/payable` 有变更，由于它不在任何链路的 `modules` 中，只会跑通用 smoke test，不会触发采购链路回归。

当前应付模块尚未建成，所以不构成实际风险。但当应付模块上线后，应该将它加入采购链路的 `modules` 列表（或创建独立的"业财链路"）。

**建议：** 在 `business-chains.json` 的采购链路注释中加一句："TODO: 应付模块上线后，将 finance/payable 加入 modules 或创建独立的业财链路。"

---

## 四、过度设计

### D1. ⚠️ `business-chains.schema.json` 详细但从未被引用

**严重度：** P3（有比没有好，但 ROI 偏低）

148 行的 JSON Schema 文件定义了完整的类型约束，但：
- `deploy-quality-gate.md` 的执行流程中没有"验证 business-chains.json 符合 schema"这一步
- 没有任何工具/脚本引用此 schema
- `business-chains.json` 的 `$schema` 引用指向它，但 JSON 解析器通常不自动验证

它的实际作用是"给人类看的类型文档"。如果是文档目的，可以用更简洁的注释替代。

**建议：** 二选一：
- **保留但激活：** 在 deploy-quality-gate.md Step 1 之后加一个"验证 business-chains.json 符合 schema"的子步骤（用 `ajv` 或 `check-jsonschema` CLI）
- **简化：** 删除 schema 文件，在 business-chains.json 中用 `//` 注释标注各字段类型（虽然 JSON 标准不支持注释，但 AI 可读）

---

## 五、做得好的地方

以下设计决策值得肯定，不构成问题：

1. **链路审计不依赖变更分级的独立触发** — deploy-quality-gate.md 第 115-116 行的解释（"权限变更 standard 级也可能导致链路断裂"）是正确的，这是一个精心考虑的边界 case。

2. **影子模式 → 正式模式的渐进式开启** — 要求 14 天数据积累 + 误报率/真实发现率双指标达标才转正，设计严谨。

3. **冲突解决规则的"取高者"原则** — audit-classification.md 和 chain-audit SKILL.md 中"链路审计 vs 模块审计严重度不一致时取高者"的规则，与安全生产的保守原则一致。

4. **失败不阻塞部署的策略** — deploy-quality-gate.md 明确"API/E2E 失败不阻塞，人工判断"，避免了自动化测试不稳定导致的部署卡死。

5. **紧急旁路的审计日志** — `--skip-audit` + `skip-audit.log` 的设计让紧急情况有出口的同时留下审计痕迹。

6. **7 个链路审计维度的覆盖面** — 状态机 → 接口 → 数据契约 → 逆向流程 → 事务边界 → 字典一致性 → 权限衔接，从技术到业务全覆盖。

---

## 建议优先级汇总

| # | 类别 | 问题 | 严重度 | 建议动作 |
|---|------|------|:--:|------|
| O1 | 遗漏 | `hermes/reviews/INDEX.md` 缺失 | P1 | 立即创建 |
| C2 | 一致性 | 规则双写无权威来源 | P2 | 加声明 |
| C1 | 一致性 | JSON Schema 不完整 | P2 | 补充字段 |
| O2 | 遗漏 | P0 指纹存储未定义 | P2 | 正式模式前解决 |
| R1 | 风险 | 影子模式日期硬编码 | P2 | 改为 reviewDate |
| C3 | 一致性 | skip 级别触发链路审计 | P3 | 加防御规则 |
| O3 | 遗漏 | skip-audit.log 无轮转 | P3 | 接受或清理 |
| R2 | 风险 | 应付模块单向依赖 | P3 | 加 TODO 注释 |
| D1 | 过度设计 | Schema 未被引用 | P3 | 激活或简化 |

---

## 结论

**可以合入主分支。** 7 个建议中 0 个阻断，1 个 P1（INDEX.md 缺失，5 分钟可修复），其余均为 P2/P3 级别的改进项。体系设计核心逻辑正确，三层闭环（注册表→门控→审计）已经可以正常工作。

建议在合入前至少修复 O1（创建 INDEX.md），其余可在后续迭代中逐步处理。

---

*本报告由终审专家生成，基于对 53 个变更文件的全面审查。*
