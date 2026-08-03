# 测试体系现状评估 — 2026-08-04（修正版）

> **修正说明**（2026-08-04 Claude 外部评审发现）：
> 原版断言统计方法错误（只匹配 `expect()/assert()/✓/✅`，漏了项目自定义的 `c.check(name, condition, detail)` 模式）。
> 本版本用 `c.check()` 模式重新统计，事实基础已修正。
>
> **目的**：基于最近回归基线（2026-08-04）和全流程探索，盘点 harness 测试体系现状与缺口，为 `/plan` 提供输入。
> **触发**：用户反馈"这两天都在规划自动化测试体系，效果并不明显"，四类症状（漏检/不稳/不可信/空洞）全中。
> **核心诉求**：回归测试 + 持续集成 + 新功能快速补齐测试 + 历史遗留问题检测。

---

## 一、当前能力盘点

### 1.1 测试工程规模

| 维度 | 数量 | 位置 |
|---|:-:|---|
| API 测试文件 | 14 | `harness/tests/mes/` |
| E2E 测试文件 | 17（含 4 smoke） | `harness/e2e/mes/` + `e2e/smoke/` |
| pytest 回归 | 1（仅 security） | `tests/security/` |
| 业务链路注册 | 6 条 | `hermes/business-chains.json` |
| Gen-Test 自定义规则 | 8 条 | `.claude/rules/gen-tests-rules.json` |
| 命令层 | 5 个 | test-all / test-api / test-e2e / test-frontend / chain-test |
| 测试规则版本 | testing v2 | `.claude/rules/testing.md` |
| 测试技能 | 6 个 | test-all / test-api / test-e2e / test-frontend / chain-test / gen-tests |

### 1.2 断言密度真实统计（修正版，c.check 模式）

| 文件 | 行数 | c.check 数 | legacy 断言 | 真实问题 |
|---|:-:|:-:|:-:|---|
| `finance.test.js` | 192 | **34** | 16 | ⚠️ 数量足够但**浅断言**（多测"不崩溃"非"数据正确"） |
| `traceability-batch-level.test.js` | 217 | **35** | 0 | ✅ 充分（10 组场景+对账断言） |
| `batch-global-switch.test.js` | 195 | **26** | 0 | ⚠️ 数量够但**缺状态流转断言**（仅验证开关关/开时批次生成数） |
| `system.test.js` | 98 | **14** | 0 | ✅ 充分（鉴权+特殊字符+字段存在性） |
| `batch-manual-e2e.test.js` | 76 | **9** | 1 | ✅ 充分（手工录入+重复+兜底） |
| `basic.test.js` | 117 | 0 | **14** | ✅ 充分（CRUD+删除保护+重复编码） |
| `manufacturing.test.js` | 298 | 0 | **32** | ✅ 充分 |
| `purchase.test.js` | 252 | 0 | **28** | ✅ 充分 |
| `purchase-apply-order.chain.test.js` | 117 | **18** | 4 | ✅ 充分（链路断言） |
| `purchase-order-receipt.chain.test.js` | 139 | **16** | 4 | ✅ 充分 |
| `purchase-payment-flow.test.js` | 318 | **2** | 1 | ⚠️ 偏少（318 行只 3 断言） |
| `sales-receipt-flow.test.js` | 257 | **2** | 1 | ⚠️ 偏少 |
| `stocktake.test.js` | 187 | 0 | **8** | ✅ 充分 |
| `other-stock-in.test.js` | 141 | 0 | **5** | ⚠️ 偏少（E2E + API 复合） |

> ⚠️ **重要修正**：原评估报告"6 个 0 断言文件"诊断错误。**全部 14 个 API 测试文件都有断言**（最少 2 个，最多 100+）。
> 真实问题是 **断言深度**（浅断言 vs 语义断言）而非断言数量。

### 1.3 最新基线（2026-08-04 鹰眼团全量回归）

| 类别 | 通过/总数 | 通过率 | 耗时 |
|---|:-:|:-:|:-:|
| API 测试 | 436/453 | **95.96%** | ~25 分钟 |
| E2E 测试 | 19/26 | **73.1%** | ~2.2 分钟 |
| 前端 vue-tsc | 0/742（错误数） | — | ~5 分钟 |
| 前端 build | 1/1 | ✅ | ~1 分钟 |
| **加权总通过率** | — | ~89% | **~35 分钟** |

### 1.4 CI/CD 现状

| 工作流 | 范围 | 触发 |
|---|---|---|
| `security-regression.yml` | semgrep + gitleaks + trivy + pytest 授权 POC + 周度 Strix | push / PR / 周日 02:00 |
| **功能回归 CI** | ❌ 不存在 | — |
| **新模块测试生成 CI** | ❌ 不存在 | — |
| **链路贯通 CI** | ❌ 不存在 | — |

> 仅 security-regression.yml 一个 workflow，功能层完全无 CI 守卫。

### 1.5 链路真实化程度

| 链路 | status | criticalPaths | API 测试 | E2E 测试 | 链路贯通测试 |
|---|:-:|:-:|:-:|:-:|:-:|
| 采购链路 | healthy | ✅ 3 条 | ✅ | ✅ | ✅ 2 段 |
| 销售链路 | **unknown** | ❌ 空 | ❌ null | ✅ | ❌ |
| 生产链路 | **unknown** | ❌ 空 | ✅ | ❌ | ❌ |
| 财务链路 | **unknown** | 部分 | ✅ 119 用例 | ❌ 0 | ❌ |
| 库存链路 | **unknown** | 部分 | ✅ | ✅ | ❌ |
| 批次追溯 | **unknown** | ❌ 空 | ✅ | ✅ | ❌ |

> 6 条链路仅 1 条真正 healthy。注册表 ≠ 实际贯通。

---

## 二、四类症状的具体表现

### 症状 1：测了但 bug 漏掉（漏检）

- **证据**：API 95.96% 高通过率下，2026-08-04 链路测试仍暴露 2 个 **P1 真 bug**：
  - P1-1 采购入库审核：`c_mes_payable` 需要 `supplier_id` 但 `c_mes_purchase_receipt` 没这个字段
  - P1-2 Customer 列表：`MesCustomer` 实体有 `grade` 等 6 列，但 `c_mes_customer` 表都不存在
- **根因**：单模块 API 测试隔离性强，**缺链路贯通验证**。`chain-test` 命令没人跑（最近回归是鹰眼团手工跑的，没用 `/chain-test`）
- **历史教训**（testing.md v2 背景）：API 14/14 + E2E 12/12 全绿仍漏 4 bug（显示 ID / payload 形状 / 审核未生效 / 明细过多）

### 症状 2：测了运行不稳（环境脆性）

- **证据 1**：2026-08-02 全量跑发现 `playwright.config.ts` 的 baseURL **失效**，显式 `--config` 才生效（E2E 21 用例第一次跑 62%，修复后 76%）
- **证据 2**：`basic.test.js` 跑出"仓库列表空"但 DB 残留 6 条历史数据 → 测试用例状态依赖数据库当前内容
- **证据 3**：E2E 有 2 cases "did not run"（setUp hook 偶发问题未根因）

### 症状 3：测了产出不可信（结果不可信）

- **证据 1**：vue-tsc **742 错误** vs `pnpm build` **成功**（build 跳过类型检查）— 工具层报告矛盾
- **证据 2**：`finance.test.js` 50+ 断言但**全是"code===200 不崩溃"**，没验证业务字段值（**浅断言**问题）
- **证据 3**：链路 status="unknown" 写了 5 条，但实际贯通验证空白 — 文档 ≠ 现实
- **根因**：Gen-Test 推导规则只生成"测什么"不强制"断言语义足够"

### 症状 4：覆盖空洞（没人管的链路）

- **证据 1**：`commonSetting.spec.ts` 1/1 失败（页面整页不可达）
- **证据 2**：`finance` 8 个 Controller 全部 0 个 E2E
- **证据 3**：`manufacturing` 24/24 API 全过但 **0 个 E2E**
- **证据 4**：采购链路贯通测试只覆盖"申请→订单→入库"，缺"→应付生成→付款"段

---

## 三、根因分级

| 级别 | 根因 | 影响 |
|:-:|---|---|
| **L1（结构性）** | 没有功能回归 CI，测试只在本机跑 | 漏检、漂移无人守 |
| **L1（结构性）** | 测试目录按"模块"组织，缺"链路"维度 | 跨模块 bug 漏检 |
| **L1（结构性）** | E2E CI 服务器可达性无方案（playwright.config.ts 硬编码 100.122.125.106） | E2E CI 实施第一天撞墙 |
| **L2（流程性）** | gen-tests 生成后无人做**断言语义深度**检查 | 浅断言入库 |
| **L2（流程性）** | 链路 status 手动维护不更新 | 文档 ≠ 现实 |
| **L3（执行性）** | pytest 只有 1 个文件（security），不是功能测试主力 | 渗透 vs 功能分离 |
| **L3（执行性）** | vue-tsc 742 错误未纳入质量门 | 类型层 bug 漏检 |
| **L3（执行性）** | 测试 runner 配置不自检（baseURL 失效 5 天才被发现） | 漂移无人知 |

---

## 四、可行性优化方案（4 块 + 1 收口）

> 围绕用户核心诉求"回归测试 + 持续集成 + 新功能快速补齐 + 历史遗留问题检测"展开。

### 方案 A：CI 集成层（持续集成载体）

| 动作 | 产出 | 估算 |
|---|---|:-:|
| 新增 `.github/workflows/functional-regression.yml`：api-test + e2e-test + typecheck 在 PR 必跑 | CI 守卫 | 1 人天 |
| api-test job：services(MySQL+Redis) → mvn install → java -jar → 端口就绪 → 跑 harness/tests/mes/*.test.js | 自包含后端 | 含在 1 人天 |
| e2e-test job：pnpm build + pnpm preview（端口 4173）+ baseURL=localhost + continue-on-error | E2E 可达 | 含在 1 人天 |
| typecheck job：vue-tsc --noEmit + 软门控（错误数 ≤ 200）+ pnpm build | 前端守卫 | 含在 1 人天 |
| Maven/pnpm 缓存（`actions/cache@v4`） | 加速 CI | 0.5 人天 |

### 方案 B：测试深度层（断言深度 + 覆盖空洞）

| 动作 | 产出 | 估算 |
|---|---|:-:|
| **改造 finance.test.js**：浅断言（仅 code===200）→ 语义断言（验证字段值 + 状态流转） | 质量提升 | 1 人天 |
| **改造 batch-global-switch.test.js**：加状态流转断言（批次 originBillNo/sourceBillType/quantity 字段值） | 链路守卫 | 0.5 人天 |
| finance 8 个 Controller 补 E2E | 链路守卫 | 2 人天 |
| manufacturing 补 E2E | 链路守卫 | 1 人天 |
| 新增 `/test-quality <项目>` 命令：扫描断言深度（浅/语义）、0 断言文件、覆盖率趋势 | 自检能力 | 1 人天 |

### 方案 C：新功能快速补齐层（gen-tests 自动化）

| 动作 | 产出 | 估算 |
|---|---|:-:|
| 追加 R009 规则：≥1 语义断言/场景（非数量下限） | 防浅断言 | 0.5 人天 |
| gen-tests SKILL.md 加自检步骤 | 落地 R009 | 0.5 人天 |
| `/gen-tests <项目> <模块>` 在 PR 注释中触发 | 自动建议 | 1 人天 |
| 新模块三件套检查自动化（API + E2E + 抓包）门控 | `/plan` 强制项 | 0.5 人天 |

### 方案 D：历史遗留检测层（链路贯通 + bug 反哺）

| 动作 | 产出 | 估算 |
|---|---|:-:|
| `/chain-test --all` 在 CI 周日跑（与 Strix 同期） | 链路 status 自动更新 | 0.5 人天 |
| 链路 status 自动从 `unknown` → `healthy` / `dropped` | 文档真实化 | 0.5 人天 |
| **bug 反哺规则**：每个 P1/P2 bug 修复 PR 强制问"是否需追加规则" | 规则持续进化 | 0.5 人天 |
| 历史 P1（采购入库 supplier_id）+ 历史 P2（Customer 缺列）作为回归用例沉淀 | 不再回潮 | 0.5 人天 |

### 方案 E：收口（一体化看板）

| 动作 | 产出 | 估算 |
|---|---|:-:|
| `hermes/eagle-eye/reports/` 按周聚合报告（baseline + Δ） | 趋势可视化 | 0.5 人天 |
| 在 `/quality-dashboard` 加测试维度卡片 | 业务人员可视 | 0.5 人天 |

---

## 五、推荐落地顺序（按 ROI 排序）

| 顺序 | 方案 | 总估算 | 优先级 |
|:-:|---|:-:|:-:|
| 1 | A 全部（CI workflow） | 1.5 人天 | 🔴 P0 |
| 2 | C 全部（gen-tests 规则 + SKILL） | 1.5 人天 | 🔴 P0 |
| 3 | B 改造 finance + batch-global-switch（断言深度） | 1.5 人天 | 🟠 P1 |
| 4 | D 全部（链路 CI + bug 反哺） | 2 人天 | 🟠 P1 |
| 5 | B 补 E2E（finance + manufacturing） | 3 人天 | 🟡 P2 |
| 6 | E 看板 | 1 人天 | 🟢 P3 |

**P0 周期**：3 天内完成（C1+A1）
**P1 周期**：+3.5 天（共 6.5 天）
**P2 周期**：+3 天（共 9.5 天）
**P3 周期**：+1 天（共 10.5 天）

---

## 六、验收标准

### 6.1 必须满足（验收红线）

1. PR 触发 `functional-regression.yml`：api-test + e2e-test + typecheck 全跑，**失败阻塞合并**
2. CI 周日自动跑 `/chain-test --all`，链路 status 自动更新
3. gen-tests R009：每个场景必须 ≥1 语义断言（验证字段值/状态流转，非仅 code===200）
4. 4 个核心链路（采购/销售/生产/财务）E2E 全覆盖

### 6.2 期望满足（达成指标）

| 指标 | 当前 | 目标 |
|---|:-:|:-:|
| API 通过率 | 95.96% | **≥ 98%** |
| E2E 通过率 | 73.1% | **≥ 90%** |
| 浅断言文件数（仅 code===200） | 1（finance） | **0** |
| 缺状态流转断言文件 | 1（batch-global-switch） | **0** |
| 链路 healthy 数 | 1/6 | **≥ 4/6** |
| vue-tsc 错误 | 742 | **≤ 200** |
| CI 单次回归耗时 | 35 分钟 | **≤ 40 分钟** |

---

## 七、风险与对策

| 风险 | 概率 | 对策 |
|:-:|:-:|---|
| CI runner 与本机环境差异 | 中 | setup-node@v4 锁 v20，setup-java@v4 锁 17 |
| E2E 浏览器环境不稳 | 中 | continue-on-error 兜底 + 周度全跑 |
| 测试断言补齐暴露新 bug | 高 | 预期内 — 暴露即记录 learnings/，进入 P1 处理 |
| Orca 评审排队阻塞 | 低 | 超时 10 分钟自动跳过，保留用户最终确认权 |
| gen-tests 规则改动影响历史用例 | 低 | 只在新生成时生效，已存在文件由本次手动改造 |

---

**下一步**：等用户确认本报告，按 `/plan` 流程落地 P0 三项（CI workflow + R009 + finance/batch-global-switch 改造）。