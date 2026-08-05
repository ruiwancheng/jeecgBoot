# 测试体系链路重组 — 架构评审报告

> **日期**: 2026-08-04
> **评审范围**: harness/tests/ 从"按模块"重组为 chains/ + modules/ 双目录结构
> **评审方法**: 逐项对账计划声明 vs 实际代码状态（Git 已跟踪文件 + 路径引用全局扫描）

---

## 一、通过项 ✅

| # | 项目 | 判定 |
|---|------|:--:|
| 1 | chains/ + modules/ 双目录结构设计合理——独立模块（basic/system）和业务链路（采购/销售）确实需要不同治理策略 | ✅ |
| 2 | `business-chains.json` 结构清晰，6 条链路定义完整，flow/criticalPaths/modules 字段可作为 CI 自动路由输入 | ✅ |
| 3 | 采购链路 3 个 chain/flow 文件（`purchase-apply-order.chain.test.js` + `purchase-order-receipt.chain.test.js` + `purchase-payment-flow.test.js`）是经过实战验证的模板 | ✅ |
| 4 | `git mv` 方式保留历史，优于 delete+recreate | ✅ |
| 5 | 不改测试内容（断言/数据）、不动业务代码——范围控制正确 | ✅ |
| 6 | 验收红线明确（6 条链路 enabled + healthy + 链文件就位 + CI 跑通） | ✅ |

---

## 二、必须修改项 🔴（高风险遗漏，不解则阻塞实施）

### P0-1: 迁移脚本引用 3 个不存在的 .mjs 文件

```bash
# migration-commands.sh 第 17-19 行
git mv harness/tests/mes/codeRule.test.mjs harness/tests/modules/
git mv harness/tests/mes/sales-api.test.mjs harness/tests/modules/
git mv harness/tests/mes/sales-order.test.mjs harness/tests/modules/
```

**实际状态**: `harness/tests/mes/` 下 **不存在** 这三个文件。

```
$ find harness/tests/mes -name "*.mjs"
（空——无输出）
```

**影响**: `git mv` 不存在的文件直接报错，整个迁移脚本失败。`set -e` 下第一步就中断，modules/ 和 chains/ 目录创建后为空。

**修正**: 删除这 3 行。如果这些文件是计划阶段预想的（尚未生成），应在计划中标注"待生成"而非"git mv"。

### P0-2: `require()` 路径全部断裂

**当前状态**: 所有测试文件使用 `require('../helpers/api')` 和 `require('../helpers/fixtures')`。

```
harness/tests/mes/xxx.test.js
                   └── ../helpers/api.js  ✅ 正确（从 mes/ 上跳到 tests/，再进 helpers/）
```

**迁移后**（按计划，文件进入 `harness/tests/modules/` 或 `harness/tests/chains/`）:

```
harness/tests/modules/xxx.test.js
                   └── ../helpers/api.js  ❌ 错误（../ 从 modules/ 上跳到 tests/，没问题 ✅ 等等——让我重算）

harness/tests/modules/  →  ../ = harness/tests/  →  ../helpers/ = harness/tests/helpers/  ✅ 正确！
harness/tests/chains/   →  ../ = harness/tests/  →  ../helpers/ = harness/tests/helpers/  ✅ 正确！
```

**更正**: 让我重新计算路径。如果 tests/ 下的结构变为:
```
harness/tests/
  ├── modules/
  │   ├── basic.test.js      → require('../helpers/...') = tests/helpers/ ✅
  │   └── ...
  ├── chains/
  │   ├── purchase-chain.test.js  → require('../helpers/...') = tests/helpers/ ✅
  │   └── ...
  └── helpers/
      ├── api.js
      └── fixtures.js
```

**实际上路径不需要改！** `../` 从 modules/ 或 chains/ 上跳一层到 tests/，然后 `helpers/` 正确。这和我之前快速心算的结论不同——让我确认:

- `harness/tests/modules/basic.test.js` → `../helpers/api.js` → 解析为 `harness/tests/modules/../helpers/api.js` → `harness/tests/helpers/api.js` ✅
- `harness/tests/mes/basic.test.js` → `../helpers/api.js` → 解析为 `harness/tests/mes/../helpers/api.js` → `harness/tests/helpers/api.js` ✅

**结论**: `require()` 路径在迁移后**保持不变且正确**。计划在此点上正确。但计划没有提及这个验证——应该在计划文档中明确声明这个验证结果（"已验证: modules/ 和 chains/ 都在 tests/ 下，`../helpers/` 无需改动"）。

> 修正: 不是 P0，改为 P2（文档遗漏）。但 plan 应显式声明已验证路径。

### P0-3: **真正的 P0**——迁移后 6 个文件留在 mes/ 目录未处理

**migration-commands.sh 注释**（第 24-33 行）说明以下文件保留在 `mes/`:
```
purchase-apply-order.chain.test.js
purchase-order-receipt.chain.test.js
purchase-payment-flow.test.js
sales-receipt-flow.test.js
other-stock-in.test.js
stocktake.test.js
finance.test.js
manufacturing.test.js
traceability-batch-level.test.js
```

**问题**: 计划声称将 18 个模块文件移到 `modules/`。但迁移脚本实际只移 8 个（括号中为 8 个模块测试），以上 9 个文件原样留在 `mes/`。最终目录变为:

```
harness/tests/
  ├── mes/             ← 依然存在！含 9 个文件
  ├── modules/         ← 只有 8 个文件
  └── chains/          ← 空
```

这与验收红线 #2（"18 个模块文件全部迁移到 modules/，不丢失"）直接矛盾。

**修正**: 必须决策:
- 方案 A（推荐）: 所有文件全部迁移——模块文件进 `modules/`，chain/flow 文件进 `chains/`，**彻底删除 `mes/` 目录**
- 方案 B: 只移真正的"模块测试"（basic/batch-global-switch 等），chain/flow 保持现有命名和位置，**不创建 `chains/` 目录**，仅重组 `mes/` 内的命名规范

方案 B 改动量小但无法实现"双目录结构"。建议方案 A。

### P0-4: 6 条链路 ≠ 6 个 CI job——2 条标记 isStandalone

**business-chains.json 事实**:

| 链路 | isStandalone | chainTests | 应建 chain job? |
|------|:--:|:--:|:--:|
| 采购链路 | ❌ | enabled=true | ✅ 是 |
| 销售链路 | ❌ | 无 | ✅ 是（需新建链文件） |
| 生产链路 | ❌ | 无 | ✅ 是（需新建链文件） |
| **基础数据** | **✅ true** | 无 | ❌ **不应该**——独立模块无上下游 |
| **其它出入库** | **✅ true** | 无 | ❌ **不应该**——独立模块无上下游 |
| 仓储链路 | ❌ | 无 | ✅ 是 |

**修正**: CI 应为 **4 个链路 job**，而非 6 个。基础数据和其他出入库作为独立模块，对应 `modules/` 目录，在 api-test job 中统一跑即可（不走链路 CI）。

### P0-5: 13 处路径引用需更新——计划遗漏

全局扫描 `harness/tests/mes/` 在项目中的所有引用（排除 `harness/tests/mes/` 目录内文件自身）:

| # | 文件 | 引用内容 | 需要改? |
|---|------|---------|:--:|
| 1 | `hermes/business-chains.json` | `"api": "harness/tests/mes/purchase.test.js"` | ✅ 改 |
| 2 | `hermes/business-chains.json` | `"file": "harness/tests/mes/purchase-apply-order.chain.test.js"` | ✅ 改 |
| 3 | `hermes/business-chains.json` | `"file": "harness/tests/mes/purchase-order-receipt.chain.test.js"` | ✅ 改 |
| 4 | `hermes/business-chains.json` | `"api": "harness/tests/mes/manufacturing.test.js"` | ✅ 改 |
| 5 | `hermes/business-chains.json` | `"api": "harness/tests/mes/basic.test.js"` | ✅ 改 |
| 6 | `hermes/business-chains.json` | `"api": "harness/tests/mes/other-stock-in.test.js + ..."` | ✅ 改 |
| 7 | `.github/workflows/functional-regression.yml` | `tests/mes/*.test.js`（4 处） | ✅ 改 |
| 8 | `.claude/skills/chain-test/SKILL.md` | `harness/tests/mes/purchase-*.chain.test.js`（2 处） | ✅ 改 |
| 9 | `.claude/skills/gen-tests/SKILL.md` | `harness/tests/mes/sales.test.js` | ✅ 改 |
| 10 | `.claude/rules/testing.md` | `harness/tests/mes/stocktake.test.js` + `purchase-apply-order.chain.test.js` | ✅ 改 |
| 11 | `.claude/rules/deploy-quality-gate.md` | `harness/tests/mes/<chain>.test.js`（3 处） | ✅ 改 |
| 12 | `.claude/rules/deploy-verify/SKILL.md` | `harness/tests/mes/*.test.js` | ✅ 改 |
| 13 | `.claude/rules/gen-tests-rules.json` | `harness/tests/mes/*.test.js` | ✅ 改 |

**加上计划内的 25 个文件**（17 移动 + 6 新建链文件 + business-chains.json + CI workflow），**实际改动文件数约 37 个**，而非 25 个。

---

## 三、建议修改项 🟠（可优化，不阻塞）

### P1-1: 采购链路 3 个文件合并策略

**当前**: `purchase-apply-order.chain.test.js`（17 断言）+ `purchase-order-receipt.chain.test.js`（16 断言）+ `purchase-payment-flow.test.js`（~193 行）

**问题**: `purchase-payment-flow.test.js` **不在 chainTests.segments 中**——它是一个独立的 flow 测试文件，cover 了"采购入库→应付→付款"段（采购链路 flow 的最后两段）。如果合并成 `purchase-chain.test.js`，约 400+ 行，但采购链是唯一经过实战验证的链路模板。

**建议**: **不合并**。保留 3 段文件 + 链文件 `purchase-chain.test.js` 只做编排（require + 串联运行），不改内容。这样 CI 只需 `node chains/purchase-chain.test.js`，内部 `require()` 执行 3 段验证。其他链路参考此模板。

### P1-2: sales 链路 flow 不完整

**business-chains.json 销售链路**:
```json
"flow": ["下单", "发货通知", "出库"],
"criticalPaths": [],
"tests": { "api": null, "e2e": "harness/e2e/mes/sales-order.spec.ts" }
```

**问题**: `criticalPaths` 为空，`api` 为 null。链文件若新建，应基于实际 API 端点列出关键路径——而非凭空想象。建议先跑一次 `/chain-test 销售链路` 手工验证，再编码链文件。

**建议**: 计划中的"新建 5 条链路的链文件"改为"先手工验证链路可贯通性，再编码链文件"。优先采购（已有模板）→ 仓储（criticalPaths 已完整填写）→ 销售 → 生产。

### P1-3: 不应链接独立模块到 CI chain job

**基础数据**和**其它出入库**标记 `isStandalone: true` 是有原因的——它们不依赖上下游。强制链化会制造"假的"链路测试（不需要 ID 跨段传递、不需要数据一致性验证），反而稀释"链路贯通"的语义。

**建议**: 保持 `isStandalone` 模块在 `modules/` 目录，CI 按模块跑 API 测试。不强制建 `chainTests`。

### P1-4: CI 6 job 改 4 job + 矩阵复用

**当前 CI**（`functional-regression.yml`）已经是 3 job 结构（api-test → e2e-test → typecheck），api-test 统一跑 `tests/mes/*.test.js`。

**按链路分 job 的方案**:
```yaml
strategy:
  matrix:
    chain: [purchase, sales, manufacturing, warehouse]
```
每个 job 只跑对应链路的 `chains/<name>-chain.test.js`。

**收益**: 哪个链路断了一目了然（不通过 job 名称判断），失败不阻塞其他链路 CI。

**风险**: 4 个并行 job 都在 `mvn install` + `java -jar` 启动后端——每个 job 需要 ~3 分钟构建 + MySQL/Redis service container。GitHub Actions free tier 最多 20 并发 job，但每个 job 的资源独立计算。

**建议**: 保持当前 api-test 单 job 结构，内部按链路分步跑（不是分 job）。修改为:
```bash
echo "=== 采购链路 ===" && node chains/purchase-chain.test.js || FAILED=1
echo "=== 销售链路 ===" && node chains/sales-chain.test.js || FAILED=1
echo "=== 生产链路 ===" && node chains/manufacturing-chain.test.js || FAILED=1
echo "=== 仓储链路 ===" && node chains/warehouse-chain.test.js || FAILED=1
echo "=== 独立模块 ==="
for f in modules/*.test.js; do node "$f" || FAILED=1; done
```

**原因**: API 测试需要 1 个后端进程。并行 4 个 job = 4 个后端进程 + 4 套 MySQL/Redis service container = 资源浪费。串行在 25 分钟内能跑完（当前 API 全量 ~25 分钟）。

### P1-5: E2E 目录也需要联动调整

`harness/e2e/playwright.config.ts`:
```ts
testDir: './mes',
```
`harness/playwright.config.ts`:
```ts
testDir: './e2e',
testMatch: ['**/mes/**/*.spec.ts', '**/smoke/**/*.spec.ts'],
```

如果 `tests/` 重组，E2E 目录结构（`harness/e2e/mes/`）是否也应重组为 `harness/e2e/chains/` + `harness/e2e/modules/`？当前 E2E 测试文件（17 个 .spec.ts）也是按模块组织的。

**建议**: 计划声明"不动 E2E 目录"是合理的——先验证 API 层重组效果，E2E 后续跟进。但应在计划中显式标注"已知不联动"。

---

## 四、拒绝采纳项 ❌

| # | 项目 | 理由 |
|---|------|------|
| 1 | "18 个模块文件" | 实际 14 个 .test.js + 0 个 .test.mjs（脚本引用的 3 个 .mjs 不存在） |
| 2 | 6 条链路的 CI job | 2 条是 standalone 模块，不应该链化。应该是 4 条链路 |
| 3 | 迁移脚本保留 mes/ 目录 | 应该彻底删除 `harness/tests/mes/` 目录（全部文件迁移到 modules/ 或 chains/） |

---

## 五、修订后实施建议

### 修订文件清单（37 个，从 25 个修正）

**移动文件**（14 个，非 17 个——删除了 3 个不存在 .mjs）:
```
git mv harness/tests/mes/basic.test.js              → harness/tests/modules/
git mv harness/tests/mes/batch-global-switch.test.js → harness/tests/modules/
git mv harness/tests/mes/batch-manual-e2e.test.js    → harness/tests/modules/
git mv harness/tests/mes/system.test.js              → harness/tests/modules/
git mv harness/tests/mes/purchase.test.js            → harness/tests/modules/  (模块级 API 测试)
git mv harness/tests/mes/finance.test.js             → harness/tests/modules/
git mv harness/tests/mes/manufacturing.test.js       → harness/tests/modules/
git mv harness/tests/mes/traceability-batch-level.test.js → harness/tests/modules/
git mv harness/tests/mes/other-stock-in.test.js      → harness/tests/modules/
git mv harness/tests/mes/stocktake.test.js           → harness/tests/modules/
git mv harness/tests/mes/purchase-apply-order.chain.test.js → harness/tests/chains/
git mv harness/tests/mes/purchase-order-receipt.chain.test.js → harness/tests/chains/
git mv harness/tests/mes/purchase-payment-flow.test.js → harness/tests/chains/
git mv harness/tests/mes/sales-receipt-flow.test.js  → harness/tests/chains/
rmdir harness/tests/mes/  # 确认空后删除
```

**新增文件**（6 个）:
- `harness/tests/chains/purchase-chain.test.js` — 编排文件（require 3 段）
- `harness/tests/chains/sales-chain.test.js` — 新建
- `harness/tests/chains/manufacturing-chain.test.js` — 新建
- `harness/tests/chains/warehouse-chain.test.js` — 新建
- `harness/tests/chains/basic.test.js` — 独立模块编排（不叫 chain）

**修改文件**（17 个，计划外 +13）:
- `hermes/business-chains.json` — 更新 6 处路径 + 4 条链路 chainTests
- `.github/workflows/functional-regression.yml` — 更新路径 + 分链路步骤
- `.claude/skills/chain-test/SKILL.md` — 更新 2 处路径
- `.claude/skills/gen-tests/SKILL.md` — 更新 1 处路径
- `.claude/skills/test-all/SKILL.md` — 更新 1 处路径
- `.claude/skills/deploy-verify/SKILL.md` — 更新 1 处路径
- `.claude/rules/testing.md` — 更新 2 处路径
- `.claude/rules/deploy-quality-gate.md` — 更新 3 处路径
- `.claude/rules/gen-tests-rules.json` — 更新 1 处路径
- 迁移命令脚本 + 计划文档更新

### 修订验收红线

| # | 原 | 修订 |
|---|-----|------|
| 1 | 6 条链路 chainTests.enabled=true | **4 条**链路（采购/销售/生产/仓储）+ 2 条独立模块（基础数据/其它出入库）标记 isStandalone=true，不强制 chainTests |
| 2 | 18 个模块文件迁移 | **14 个文件**全部迁移（无 .mjs），mes/ 目录删除 |
| 3 | 6 个 chain 文件 | **4 个链文件**就位（采购编排现有 3 段 + 销售/生产/仓储 各新建） |
| 4 | CI 6 个链路 job | CI 保持 3 job 结构（api-test/e2e-test/typecheck），api-test 内分链路步骤串行（非并行 job） |
| 5 | harness/tests/ 结构 | `chains/` + `modules/` + `e2e/` + `helpers/`，mes/ 目录删除 |

### 路径引用更新脚本

```bash
# 批量替换 harness/tests/mes/ → 新路径
# chains/ 文件
sed -i 's|harness/tests/mes/purchase-apply-order.chain.test.js|harness/tests/chains/purchase-apply-order.chain.test.js|g' \
  hermes/business-chains.json .claude/skills/chain-test/SKILL.md .claude/rules/testing.md .claude/rules/deploy-quality-gate.md
sed -i 's|harness/tests/mes/purchase-order-receipt.chain.test.js|harness/tests/chains/purchase-order-receipt.chain.test.js|g' \
  hermes/business-chains.json .claude/skills/chain-test/SKILL.md .claude/rules/deploy-quality-gate.md
# modules/ 文件
sed -i 's|harness/tests/mes/basic.test.js|harness/tests/modules/basic.test.js|g' hermes/business-chains.json
sed -i 's|harness/tests/mes/manufacturing.test.js|harness/tests/modules/manufacturing.test.js|g' hermes/business-chains.json
sed -i 's|harness/tests/mes/other-stock-in.test.js + harness/tests/mes/stocktake.test.js|harness/tests/modules/other-stock-in.test.js,harness/tests/modules/stocktake.test.js|g' hermes/business-chains.json
# CI workflow
sed -i 's|tests/mes/\*\.test\.js|modules/*.test.js chains/*.test.js|g' .github/workflows/functional-regression.yml
```

---

## 六、风险提示

| 风险 | 可能性 | 对策 |
|------|:--:|------|
| sales/manufacturing/warehouse 链路贯通测试写不出来（链路本身数据不通） | 高 | 先跑一次手工 `/chain-test <链路名>` 验证可贯通性再编码——不浪费写"假的"链文件 |
| 基础数据和其他出入库被强行链化 | 中 | 保持 isStandalone，不出现在 CI chain job 中 |
| E2E 目录不同步导致概念分裂 | 中 | 在 plan 中显式标注"E2E 目录暂不同步，后续跟进" |
| `.claude/memory/` 和 `.claude/plans/` 中残留旧路径引用 | 低 | 做完后全局 grep 确认 |
| CI 中 Maven 缓存 key 不包含 `harness/tests/` 路径变化 | 低 | 路径变化不影响 Maven 缓存（缓存 key 基于 pom.xml） |

---

**评审结论**: 方向正确，但 **P0-1（3 个不存在 .mjs 会让脚本第一步就挂）、P0-2（已验证路径正确只需声明）、P0-4（2 条 standalone 链路不应参与 CI chain job）、P0-5（遗漏 13 处路径引用更新）必须在写迁移脚本前修正**。实施文件从 25 个修订为 37 个。建议先做采购链路的迁移（风险最低、验证最充分），再逐链路推广。
