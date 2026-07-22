---
name: deploy-quality-gate
description: 集中部署后自动质量门控——变更分级+链路回归+审计+报告，替代手工逐页验收
glob: "**/*"
version: 1.0.0
---

# 部署后自动质量门控

> **目标**：把"部署后手工验收 2-4 小时"变成"部署后自动验证 5-15 分钟 + 人工只看异常"。
>
> **兼容**：本规则与 `workflow.md` 分级测试互补——分级测试用于开发中的快速自检，本规则用于集中部署后的系统级验证。

## 触发条件

**集中部署完成后自动执行**（非可选，非提示）。AI 识别到"部署完成"信号时，必须执行以下流程。

> **约束假设**：当前部署架构为单服务端串行部署（部署控制台单进程），`.last-deploy-commit` 无并发写冲突。若未来引入并行部署流水线，需加文件锁或改用数据库记录。

## 执行流程

```
部署完成
  │
  ├─ Step 1: 获取变更差集
  │   git diff .last-deploy-commit..HEAD --name-only
  │   若 .last-deploy-commit 不存在 → 使用 HEAD~1（首次）
  │
  ├─ Step 2: 变更分级（按 hermes/business-chains.json 的 changeClassification）
  │   ├─ skip:    纯文案/样式/注释 → 输出"无需质量验证"→ 跳到 Step 5
  │   ├─ light:   前端组件逻辑 → 跑 E2E
  │   ├─ standard: Controller 写操作 → 跑 API + E2E
  │   └─ full:    Entity/Service/Mapper/SQL → 跑 API + E2E + 铁拳团审计
  │
  ├─ Step 3: 查链路注册表
  │   根据变更文件路径匹配 hermes/business-chains.json 中的链路
  │   命中链路 → 加载对应测试文件路径
  │   未命中 → 仅跑通用 smoke test
  │
  ├─ Step 4: 执行验证
  │   ├─ 鹰眼团 API 回归: node harness/tests/mes/<chain>.test.js
  │   ├─ 鹰眼团 E2E 回归: npx playwright test harness/e2e/mes/<chain>.spec.ts
  │   ├─ 铁拳团模块审计: 10 Agent 并行审计 (仅 full 级, 约10min)
  │   └─ 链路审计: 变更涉及 ≥2 模块时自动触发 (链路人1号, 约5min)
  │       详见 .claude/skills/jeecg-chain-audit/SKILL.md
  │
  └─ Step 5: 输出质量报告 + 更新 .last-deploy-commit
```

## 变更分级细则

AI 分析 `git diff .last-deploy-commit..HEAD` 时按以下优先级判定（取最高等级）：

| 判定依据 | 等级 | 动作 |
|----------|:--:|------|
| 仅 `.md` / 注释 / 格式化 / import 排序 | skip | 无 |
| `.vue` 仅 `<template>` 文字或样式，script 无变更 | skip | 无 |
| `.vue` `<script>` 逻辑变更 | light | E2E |
| `.data.ts` 列配置变更 | light | E2E |
| `Controller.java` 新增/修改 GET 方法 | light | E2E |
| `Controller.java` 新增/修改 POST/PUT/DELETE 方法 | standard | API + E2E |
| `api.ts` / 路由配置变更 | standard | API + E2E |
| ≥3 个文件同时变更 | standard | API + E2E |
| `Entity.java` 新增/修改字段 | **full** | API + E2E + 审计 |
| `ServiceImpl.java` 核心逻辑变更 | **full** | API + E2E + 审计 |
| `Mapper.java` / `Mapper.xml` / `*.sql` 变更 | **full** | API + E2E + 审计 |
| 跨 ≥2 个模块目录变更 | **full** | API + E2E + 审计 |
| `pom.xml` 依赖变更 | **full** | API + E2E + 审计 |

> **判定规则**：同一批变更取所有文件的最高等级。比如改了 1 个 Controller + 1 个 Entity → full。

## 链路匹配规则

变更文件路径前缀匹配 `hermes/business-chains.json` 中 `chains.<name>.modules[]`：

| 变更路径包含 | 命中链路 | 加载测试 |
|-------------|---------|---------|
| `purchase/` | 采购链路 | `purchase.test.js` + `purchase.spec.ts` |
| `sales/` | 销售链路 | 对应测试 |
| `manufacturing/` | 生产链路 | `manufacturing.test.js` |
| `basic/` | 基础数据(独立) | `basic.test.js` |
| 多条链路同时命中 | 串行执行各链路 | 各自测试 |

> **未命中任何链路** → 跑通用 smoke test（登录 + 基础接口可用性）。

## 铁拳团审计触发规则

**模块审计**：仅 full 级变更触发。审计范围：

1. 变更涉及的所有模块（不是单模块）
2. 若链路上游/下游模块上次审计 > 7 天 → 一并审计

**链路审计**（铁拳团第11视角）：变更涉及 `business-chains.json` 中任意链路 ≥2 个模块时自动触发，**不依赖变更分级**。

- 触发条件: 独立判断——改了哪个链路的 ≥2 个模块就触发
- Agent: 链路人1号（1个Agent，约5分钟）
- 技能文件: `.claude/skills/jeecg-chain-audit/SKILL.md`
- 输出: `hermes/tiequan/{date}/{module}-chain/13_链路审计报告.md`
- 回写: 更新 `business-chains.json` 中对应链路的 `health` 字段

> **为什么链路审计不依赖变更分级？** 权限变更（standard级）也可能导致链路断裂——A模块改了权限，B模块的调用就被拒绝了。仅 full 级触发会漏审。

审计结果按 `audit-classification.md` 分类。P0 处理规则：

| 模式 | P0 动作 | 当前状态 |
|------|---------|:--:|
| 影子模式 | 记录到报告，部署继续 | ✅ 当前 (至 2026-08-05) |
| 正式模式 | BLOCKED，修复后重新部署 | 待数据达标后开启 |

## 失败处理

| 失败类型 | 动作 |
|---------|------|
| 测试文件不存在 | 记录"缺少测试覆盖"，不阻塞 |
| 测试超时 (>5分钟) | 记录超时，部署继续 |
| API 回归有失败 | 在报告中列出失败项，部署继续 |
| E2E 有失败 | 在报告中列出失败项，部署继续 |
| 审计发现 P0 (影子模式) | 列入"需关注"区块 |
| 审计发现 P0 (正式模式) | BLOCKED，必须修复 |

> **为什么 API/E2E 失败不阻塞？** 测试环境与生产环境可能有差异，测试失败不一定是代码问题。但必须记录，人工判断。

## 紧急旁路

生产 P0 hotfix 使用 `--skip-audit` 跳过验证：

```
部署 → --skip-audit → 跳过 Step 2-4 → 直接输出"紧急部署，已跳过质量门控"
```

每次使用后记录到 `hermes/logs/skip-audit.log`：

```json
{"date": "2026-07-22T18:00:00", "reason": "生产支付接口500", "commit": "abc123"}
```

## 质量报告模板

部署完成后输出以下格式的报告（固定结构，不是 50 行日志）：

```
📊 部署质量报告 — YYYY-MM-DD HH:MM

变更概况:
├─ 链路: <链路名> (<n>/<m> 模块)
├─ module-a → <变更摘要>
├─ module-b → <变更摘要>
└─ 变更等级: skip/light/standard/full

自动验证:
├─ 🟢/🔴 鹰眼团 API  → <n>/<m> 通过 (<耗时>)
├─ 🟢/🔴 鹰眼团 E2E  → <n>/<m> 通过
└─ 🟢/🔴 铁拳团审计  → <n>个P0 (新<n>, 遗留<n>), <n>个P1

🆕 P0 新发现（本次变更引入）:
  <仅列本次新增的 P0，需立即处理>

🔁 P0 遗留（非本次引入，已在前期审计中记录）:
  <仅列已知遗留 P0，无需重复处理>

⚠️ 需人工关注:
  <测试失败项 + 其他异常>

✅ 可放心:
  <已验证通过的模块和关键路径>

判定: PASS / NEEDS WORK / BLOCKED
```

> **P0 指纹去重规则**：审计输出中为每个 P0 生成指纹 `md5(模块+文件路径+行号+问题描述前50字符)`，与上一轮审计指纹集比对。命中 → 标记为"遗留"，未命中 → 标记为"新发现"。同一 P0 反复出现时保留首次发现日期，报告中注明"首次发现: YYYY-MM-DD"。

## 与现有规则的关系

| 现有规则 | 本规则的关系 |
|---------|------------|
| `workflow.md` 分级测试 | 互补——分级测试是开发中快速自检，本规则是部署后系统验证 |
| `quality-gate-criteria.md` | 集成——本规则的 audit P0 在正式模式下映射到 BLOCKED |
| `quality-escalation.md` | 复用——审计 P0 的升级规则沿用 |
| `tiequan-report-scope.md` | 复用——审计报告归档沿用 |
| `deep-inspect-schedule.md` | 互补——深度巡检是定期体检，本规则是每次部署的快速验证 |

## 影子模式转正条件

满足以下全部条件后，AI 询问用户是否开启正式模式：
1. 已积累 ≥14 天影子模式数据
2. P0 误报率 < 20%（P0 中"经人工确认无需修"的比例）
3. P0 真实发现率 > 50%（P0 中"经人工确认需要修"的比例）

达标时 AI 输出提示：
```
影子模式数据达标（误报率 X% < 20%，真实发现率 Y% > 50%）。
是否开启正式门控模式？（审计P0将自动阻断部署）
```

## 文件索引

| 文件 | 用途 |
|------|------|
| `hermes/business-chains.json` | 链路注册表 + 变更分级配置 |
| `.last-deploy-commit` | 记录上次部署 commit，做 diff 基准 |
| `hermes/logs/skip-audit.log` | 紧急旁路使用记录 |
| `hermes/reviews/` | 部署质量报告归档 |
