# Orca Review Round 2: 部署质量门控实现验证

**评审日期:** 2026-07-22
**评审人:** Claude Code (orca-review, 第二轮)
**评审对象:** 
- `hermes/business-chains.json` — 链路注册表
- `.claude/rules/deploy-quality-gate.md` — 质量门控规则
- `.claude/rules/workflow.md` — 开发流程(已更新集成)
- `hermes/reviews/deploy-quality-gate-review.md` — 上轮评审(基准)

---

## 1. 逐项检查结果

### H1: 变更分级过滤 ✅ 完全实现

| 检查点 | 状态 | 证据 |
|--------|:--:|------|
| 四级分类(skip/light/standard/full) | ✅ | `business-chains.json` L84-127 `changeClassification.levels` |
| 改文案→skip | ✅ | `deploy-quality-gate.md` L52: `.vue` 仅 `<template>` 文字或样式 |
| 改Entity→full | ✅ | `deploy-quality-gate.md` L60: `Entity.java` 新增/修改字段 → full |
| 取最高等级 | ✅ | `deploy-quality-gate.md` L66: "同一批变更取所有文件的最高等级" |
| 规则文件与JSON配置一致 | ✅ | 两份文件的分级标准完全对齐 |

**结论：** 上轮要求"改文案不触发全链路"已解决。四级分类覆盖了从纯文本到数据库 schema 的全谱变更，判定逻辑明确。

---

### H2: 失败策略 + quality-gate 对齐 ✅ 完全实现

| 检查点 | 状态 | 证据 |
|--------|:--:|------|
| P0→BLOCKED 映射(正式模式) | ✅ | `business-chains.json` L155: `"auditP0_liveMode": "BLOCKED，修复后重新部署"` |
| P0→仅记录(影子模式) | ✅ | `business-chains.json` L154: `"auditP0_shadowMode": "记录P0，部署继续"` |
| API/E2E失败不阻塞 | ✅ | `business-chains.json` L152-153 明确"部署继续(不阻塞，人工判断)" |
| 与 quality-gate-criteria.md 对齐声明 | ✅ | `deploy-quality-gate.md` L153: "本规则的 audit P0 在正式模式下映射到 BLOCKED" |
| 测试超时处理 | ✅ | `business-chains.json` L157: "5分钟超时，记录超时，部署继续" |

**结论：** 失败策略矩阵完整，区分了影子/正式两种模式下的行为，API/E2E/审计/超时四种失败类型各有处理策略。

---

### H3: 影子模式过渡 2 周 ✅ 完全实现

| 检查点 | 状态 | 证据 |
|--------|:--:|------|
| 14天过渡期 | ✅ | `business-chains.json` L133-134: startDate 2026-07-22 → endDate 2026-08-05 |
| 只审计不阻塞 | ✅ | `business-chains.json` L135: "审计P0记录到报告，部署继续" |
| 转正条件明确 | ✅ | `deploy-quality-gate.md` L159-168: ≥14天数据 + 误报率<20% + 真实发现率>50% |
| workflow.md 声明当前模式 | ✅ | `workflow.md` L149: "影子模式（当前）" |

**结论：** 2周过渡期精确到日期，转正条件量化可衡量。影子模式保护了方案不被误报杀死。

---

### S1: .last-deploy-commit 替代 HEAD~1 ✅ 完全实现

| 检查点 | 状态 | 证据 |
|--------|:--:|------|
| 配置文件定义 | ✅ | `business-chains.json` L163: `"rule": "git diff .last-deploy-commit..HEAD 获取差集"` |
| 规则文件使用 | ✅ | `deploy-quality-gate.md` L24: `git diff .last-deploy-commit..HEAD --name-only` |
| 首次fallback | ✅ | `deploy-quality-gate.md` L25: "若不存在 → 使用 HEAD~1（首次）" |
| 文件实际存在 | ✅ | `.last-deploy-commit` 存在，内容为 `3ac6df2a2dd718133983d5acf7a1fba2c36e1855` |

**结论：** 修复了上轮指出的"多人并行部署漏审中间commit"问题。首次部署的 fallback 也做了处理。

---

### S2: JSON Schema 校验 + CI 覆盖审计 ⚠️ 部分实现

| 检查点 | 状态 | 证据 |
|--------|:--:|------|
| `$schema` 引用存在 | ✅ | `business-chains.json` L2: `"$schema": "business-chains.schema.json"` |
| Schema 文件存在 | ❌ | `hermes/business-chains.schema.json` — **文件不存在** |
| CI 链路覆盖审计 | ❌ | 未找到检查"所有 Controller 是否被至少一条链路覆盖"的脚本或配置 |

**结论：** Schema 引用是"占位符"——声明了但没有实际文件来校验。这比没有引用更危险：如果代码中有 `$schema` 加载逻辑，加载失败可能导致静默跳过验证。CI 覆盖审计完全缺失。

---

### S3: P0 指纹去重 ⚠️ 未实现

| 检查点 | 状态 | 证据 |
|--------|:--:|------|
| 去重机制 | ❌ | 在所有 `.claude/rules/` 中搜索 "fingerprint/去重/dedup/新P0/遗留P0" — **无匹配** |
| 报告模板区分新/遗留 | ❌ | `deploy-quality-gate.md` 模板只有 `⚠️ 需人工关注: <仅列 P0>`，未区分 |
| 上轮建议的报告结构 | ❌ | 上轮要求"变更概况→P0 新发现→P0 遗留→测试结果→判定"，当前模板未采用 |

**结论：** 上轮评审警告的"狼来了效应"（同一遗留 P0 反复出现→报告被忽略）仍然存在。没有机制区分"本次变更引入的 P0"和"已知但未修的遗留 P0"。

---

### S4: --skip-audit 紧急旁路 ✅ 完全实现

| 检查点 | 状态 | 证据 |
|--------|:--:|------|
| 标记定义 | ✅ | `business-chains.json` L148: `"flag": "--skip-audit"` |
| 使用规则 | ✅ | `business-chains.json` L149: "仅限生产P0修复，使用后记录到日志" |
| 行为定义 | ✅ | `deploy-quality-gate.md` L114: "跳过 Step 2-4 → 直接输出'紧急部署，已跳过质量门控'" |
| workflow.md 引用 | ✅ | `workflow.md` L151: 提及 `--skip-audit` 紧急旁路 |
| 日志文件存在 | ✅ | `hermes/logs/skip-audit.log` 已创建 |

**结论：** 紧急旁路完整实现，hotfix 不会被审计阻塞。

---

## 2. 新发现的问题

### N1: JSON Schema 文件缺失 🔴 中

`business-chains.json` L2 引用了 `"$schema": "business-chains.schema.json"` 但文件不存在。如果未来添加 Schema 校验加载逻辑，引用断裂会导致解析失败。当前虽不影响运行（无校验代码），但这是一个"声明了但没兑现"的承诺。

**建议：** 创建 `hermes/business-chains.schema.json`，定义 `chains`、`changeClassification`、`qualityGate` 的结构和必填字段。

---

### N2: skip-audit.log 内容为占位符 🟡 低

`hermes/logs/skip-audit.log` 当前内容：
```json
{"description": "skip-audit log records"}
```

而非 `deploy-quality-gate.md` L120 定义的格式：
```json
{"date": "2026-07-22T18:00:00", "reason": "生产支付接口500", "commit": "abc123"}
```

**建议：** 初始化为空 JSON 数组 `[]` 或写入一条示例记录（标注为 `"_example": true`）。

---

### N3: P0 去重机制缺失 🟡 中

同 S3 — 无机制区分新 P0 和遗留 P0。

**建议方案（低成本）：** 在审计输出中为每个 P0 生成指纹 `md5(module + file + line + description)`，与上一轮审计的指纹集比对，标记 `status: "new"` 或 `status: "legacy"`。

---

### N4: 质量报告模板结构不完整 🟡 低

上轮评审建议的固定结构 "变更概况→P0 新发现→P0 遗留→测试结果→判定" 未采用。当前模板缺少 "P0 遗留" 区块。

**建议：** 在 `deploy-quality-gate.md` 报告模板中增加"🔁 P0 遗留（非本次引入）"区块。

---

### N5: CI 链路覆盖审计缺失 🟡 中

上轮评审 S2 要求 "CI 应定期检查所有 Controller 是否被至少一条链路覆盖"。未找到相关实现。

**建议方案：** 添加一个轻量脚本 `hermes/tasks/scripts/check-chain-coverage.sh`，扫描 `jeecg-boot-module/project-mes/` 下所有 `*Controller.java`，检查其路径前缀是否命中 `business-chains.json` 中至少一条链路的 `modules[]`。

---

### N6: 并发部署竞态未处理 🟡 低

上轮评审第 4 节遗漏场景 #1："两个流水线同时触发，共享 `.last-deploy-commit`"。仍未处理。

**说明：** 当前 JeecgBoot 部署架构为单服务端串行部署（部署控制台单进程），并发场景在现有运维模型下不会发生。但应在文档中标注此假设。

**建议：** 在 `deploy-quality-gate.md` 中加一条约束："假设串行部署（单部署控制台），并发部署场景另行处理。"

---

### N7: workflow.md 编排管道与 deploy-quality-gate.md 执行流程不统一 🟡 低

`workflow.md` L177-215 "质量门控编排管道" 描述了一个 verify→review→test 的三阶段 DAG：
```
git commit + push → verify门控 → review门控 → test门控 → /done
```

而 `deploy-quality-gate.md` L20-44 描述的是五步流程：
```
部署完成 → Step1获取差集 → Step2变更分级 → Step3查链路 → Step4执行验证 → Step5报告
```

两者描述的是同一体系的不同视角（开发中门控 vs 部署后门控），但 workflow.md 的编排管道图在"部署"触发点之前（标注为 `git commit + push`），容易让读者误以为这是部署门控的流程。

**建议：** 在编排管道图上方加一句注释："此编排管道用于开发中的提交门控（/quality-gate），部署后自动门控的流程见 `deploy-quality-gate.md`。"

---

### N8: quality-gate-criteria.md 的 BLOCKED 条件未包含审计 P0 🟡 低

`quality-gate-criteria.md` L61 定义 BLOCKED 为：
```
BLOCKED | 编译失败 / 核心端点不可用 / 安全扫描有 P0
```

但 `deploy-quality-gate.md` 在正式模式下将"审计 P0"也映射为 BLOCKED。`quality-gate-criteria.md` 的 BLOCKED 条件列表缺少"审计 P0"条目。

**建议：** 在 `quality-gate-criteria.md` BLOCKED 行增加"审计 P0（正式模式）"。

---

## 3. 综合评估

### 完成度矩阵

| 类别 | 要求 | 状态 | 完成度 |
|------|------|:--:|:--:|
| 🔴 硬要求 | H1 变更分级过滤 | ✅ | 100% |
| 🔴 硬要求 | H2 失败策略对齐 | ✅ | 100% |
| 🔴 硬要求 | H3 影子模式过渡 | ✅ | 100% |
| 🟡 软要求 | S1 .last-deploy-commit | ✅ | 100% |
| 🟡 软要求 | S2 JSON Schema + CI审计 | ⚠️ | 30% |
| 🟡 软要求 | S3 P0指纹去重 | ⚠️ | 0% |
| 🟡 软要求 | S4 紧急旁路 | ✅ | 100% |

### 新旧问题统计

| 问题等级 | 上轮遗留已修复 | 上轮遗留未修复 | 本轮新发现 |
|----------|:--:|:--:|:--:|
| 🔴 严重 | 3 (H1,H2,H3) | 0 | 0 |
| 🟡 中等 | 2 (S1,S4) | 2 (S2-部分,S3) | 3 (N1,N3,N5) |
| 🟢 轻微 | 0 | 0 | 5 (N2,N4,N6,N7,N8) |

---

## 4. 最终判定：✅ 有条件通过（Conditional Pass）

**三个硬要求全部实现，方案核心骨架完整且可运作。软要求 S2/S3 的部分缺口和 8 个新问题均不阻塞上线。**

### 上线前建议修复（非阻塞）

| 优先级 | 编号 | 问题 | 工作量 |
|:--:|------|------|:--:|
| P1 | N1 | 创建 `business-chains.schema.json` | 30min |
| P1 | N4 | 报告模板增加"P0 遗留"区块 | 10min |
| P2 | N3 | 实现 P0 指纹去重(基于 md5) | 1h |
| P2 | N8 | quality-gate-criteria.md 补充审计 P0 条目 | 5min |
| P3 | N2 | skip-audit.log 格式规范 | 5min |
| P3 | N5 | CI 链路覆盖审计脚本 | 2h |
| P3 | N6 | 文档标注并发假设 | 5min |
| P3 | N7 | workflow.md 编排管道加注释 | 5min |

### 影子模式期间必做

1. **积累 P0 误报率数据**（为转正决策提供依据）
2. **补齐 Schema 文件**（N1 — 防止注册表腐烂）
3. **实现 P0 指纹去重**（N3 — 防止"狼来了"效应）
4. **在 2026-08-05 前评估转正条件**（≥14天数据 → 评审误报率/真实发现率 → 用户决定是否开启正式模式）

---

## 5. 附录：评审证据索引

| 文件 | 关键行 | 证明内容 |
|------|--------|------|
| `business-chains.json` | L84-127 | 四级变更分类(changeClassification) |
| `business-chains.json` | L130-158 | 影子模式+失败策略+紧急旁路(qualityGate) |
| `business-chains.json` | L161-165 | .last-deploy-commit 差集规则(deployDiff) |
| `deploy-quality-gate.md` | L24-25 | .last-deploy-commit + HEAD~1 fallback |
| `deploy-quality-gate.md` | L46-66 | 变更分级细则表 |
| `deploy-quality-gate.md` | L82-94 | 审计触发规则+影子/正式模式 |
| `deploy-quality-gate.md` | L96-107 | 失败处理策略 |
| `deploy-quality-gate.md` | L109-121 | 紧急旁路(--skip-audit) |
| `deploy-quality-gate.md` | L147-155 | 与现有规则的对齐声明 |
| `deploy-quality-gate.md` | L157-168 | 影子模式转正条件 |
| `workflow.md` | L10-11 | 主线流程集成(部署→质量门控→/done) |
| `workflow.md` | L32 | 防失忆触发：部署完成自动执行质量门控 |
| `workflow.md` | L137-151 | 部署质量门控章节(引用 deploy-quality-gate.md) |
| `.last-deploy-commit` | — | 文件存在，内容为当前 HEAD commit |
| `hermes/logs/skip-audit.log` | — | 文件存在 |
| `hermes/business-chains.schema.json` | — | ❌ 不存在 |
| `.claude/rules/` (全文搜索) | — | ❌ 无 P0 去重/fingerprint 机制 |
