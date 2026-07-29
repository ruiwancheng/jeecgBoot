# Orca 评审：盘点单测试用例

> 评审对象：`harness/tests/mes/stocktake.test.js` (14 断言) + `harness/e2e/mes/stocktake.spec.ts` (10 断言)
> 评审日期：2026-07-29
> 评审依据：`.claude/rules/testing.md` v2（5 断言锚点）、`hermes/business-chains.json` 仓储链路 criticalPaths、`MesStocktakeServiceImpl` 最新代码（含 refreshItems/batchAudit/validateBookQty）

---

## 一、通过 ✅

### 1.1 核心业务流覆盖扎实

| 链路 | API 测试 | E2E 测试 |
|------|:--:|:--:|
| 全盘创建自动快照 → book/cost/snapshotTime 断言 | ✅ 场景1 (5断言) | ✅ L66-76 (3断言) |
| 实盘 → 盘亏审核 → 库存校准 | ✅ 场景2 (4断言) | ✅ L106-111 |
| 实盘 → 盘盈审核 → 库存增加 | ✅ 场景3 (2断言) | — |
| 已审核单禁止删除 | ✅ 场景4 | ✅ L114-117 |
| 草稿可删除 | ✅ 场景4 | — |
| 移动平均不变（盘亏不联动成本） | ✅ L91-92 | — |
| generatedOutId 回写 | ✅ L93-94 | — |
| 显示值断言（物料列显示编码非 ID）| — | ✅ L82-90 |

### 1.2 断言质量优秀——无"水断言"

逐个审查所有 10+14=24 断言：

| 断言 | 类型 | 质量 |
|------|------|:--:|
| API `book=100, actual=100, cost=10` | 数据正确性 | ✅ 精确比较 |
| API `snapshotTime` 存在 | 存在性 | ✅ 必需（字段非空即正确） |
| API `库存 100→95` | 数据传递 | ✅ 数值精确对比 |
| API `movingAvgCost = 10` | 数据传递 | ✅ |
| API `generatedOutId` 存在 | 存在性 | ✅（ID 格式 JVM 生成，无法精确断言） |
| API `审核生成盘亏单` (message.includes) | 状态流转 | ✅ 口径验证 |
| API `已审核禁删` (code !== 200) | 守卫 | ✅ |
| API `草稿可删` (code === 200) | 守卫 | ✅ |
| E2E `status='1'` (API 查) | 创建断言 | ✅ |
| E2E `book=20, cost=8` (API 查) | 数据正确性 | ✅ |
| E2E `snapshotTime 存在` | 存在性 | ✅ |
| E2E `bodyText 含 matCode` | 显示值断言 | ✅（锚点 #4） |
| E2E `抽屉物料列含 matCode` | 显示值断言 | ✅ |
| E2E `status='2'` (审核后 API 查) | 状态流转 | ✅ |
| E2E `current_qty=17` (库存变化) | 数据传递 | ✅ |
| E2E `已审核单无删除入口` (count=0) | 守卫 | ✅ |

**0 个水断言**（"水"=只测 `!== undefined` 或 `typeof === 'object'` 而不验证具体值）。24 个断言全部有具体的预期值。

### 1.3 清理方案正确迁移到 SQL 文件 ✅

```js
// stocktake.test.js L2
const { dbCleanup: sqlFileCleanup } = require('../helpers/fixtures');
```

从 V1 的 `execSync('mysql -e ...')` 升级为 `fixtures.js` 的 `writeFileSync + mysql < file` —— 绕开 Windows 引号问题 ✅

E2E 测试 `stocktake.spec.ts` 也用了同样的 `dbCleanup` import + API 双段清理 ✅

### 1.4 测试数据隔离 ✅

```js
const suffix = Date.now();
const pdCodes = [`PD-TEST-${suffix}-1`, `PD-TEST-${suffix}-2`, `PD-TEST-${suffix}-3`];
```

`Date.now()` 时间戳后缀保证不同次运行不冲突 ✅

---

## 二、遗漏 ⚠️

### 2.0（待评审问题逐答）

#### 问题 1：覆盖盲区

对照 `business-chains.json` 仓储链路 6 条 criticalPaths + 模块实际功能：

| criticalPath / 功能 | API | E2E | 等级 |
|------|:--:|:--:|:--:|
| POST /add → 全盘自动快照 | ✅ | ✅ | — |
| PUT /edit → book_qty 防篡改 | ❌ | ❌ | 🔴 P1 |
| PUT /audit → 差异合并+库存校准+回写 | ✅ | ✅ | — |
| refreshItems（草稿态刷新快照） | ❌ | ❌ | 🔴 P1 |
| batchAudit（批量审核单事务） | ❌ | ❌ | 🔴 P0 |
| 抽盘路径（takeType=2, 手工选物料） | ❌ | ❌ | 🔴 P1 |
| 多物料合并单据（M1 盘盈+M2 盘亏 同盘点） | ❌ | ❌ | 🟡 P2 |
| 已审核单编辑拦截 | ❌ | ❌ | 🟡 P2 |
| 零库存物料盘盈（book=0, actual=5） | ❌ | ❌ | 🟡 P2 |
| generatedInId 回写（盘盈侧） | ❌ | ❌ | 🟡 P2 |
| 出入库单金额 = 盘点差异金额 对账 | ❌ | ❌ | 🟡 P2 |
| 库存不足时出库拦截（差盘亏出库） | ❌ | ❌ | 🟡 P3 |

**最严重遗漏（P0）：batchAudit** —— 这是 V2 新加的批量审核单事务功能（后端 `batchAudit(List<String> ids)` + Controller 端点），但测试完全没覆盖。如果有 bug 导致批量审核部分成功 → 无测试发现。

**最严重遗漏（P1）：refreshItems** —— 也是 V2 新功能，草稿态重新快照账面数（保留 actualQty/unitCost），没有测试验证"刷新后 actualQty 没有丢失"（这正是 V2 审计 P0-1 的问题）。这个场景如果被测试覆盖，审计 P0-1 就不会漏到铁拳团发现。

**最严重遗漏（P1）：抽盘** —— 现有 14+10 断言全是全盘流程。抽盘的 `validateBookQty` 后端校验、`onMaterialChange` 前端拉账面等逻辑完全没测试。

#### 问题 2：断言质量——有没有水断言？

**无真正水断言。** 但有几个可以加强的：

| 断言 | 当前 | 可加强 | 等级 |
|------|------|--------|:--:|
| API `generatedOutId` 存在 | `!!item.generatedOutId` | 验证 `generatedOutId` 指向的出入库单确实存在且已审核 | 🟡 |
| API `audit.message.includes('盘亏出库单')` | 只验证 key 词 | 同时验证 message 包含生成的 code | 🟡 |
| E2E `expect(bodyText).toContain(matCode)` | 全页文本搜索 | `expect(subTableCell).toContainText(matCode)` 限定到子表单元格 | 🟡 |
| E2E `current_qty=17` | API 查库存表 | 同时验证 出库单的 `qty=3`（20-17） | 🟡 |
| API `movingAvgCost=10` | 盘亏后 `avg 不变` | 盘盈后 **也**应验证 `avg 不变`（场景3 缺失此断言） | 🟡 |

#### 问题 3：脆弱点

| # | 脆弱点 | 风险 | 等级 |
|---|--------|------|:--:|
| V-1 | E2E `expect(bodyText).toContain(fx.matCode)` — 全页文本搜索 | 任何位置出现 MAT-STE-xxx 都通过——包括页面 URL 中的 code 参数、loading 状态文本 | 🔴 P1 |
| V-2 | E2E `Date.now().slice(-8)` — 10 秒内冲突概率 | 每 100 秒一次冲突（8 位十进数字=10^8ms≈28小时，实际上 `slice(-8)` 取的是后 8 位，约 28 小时内重复一次） | 🟡 P2 |
| V-3 | E2E `fixtures.dbCleanup` import 路径 `../../tests/helpers/fixtures` — 相对于 `harness/e2e/mes/` | 如果 fixtures.js 移动，import 断裂。应放 e2e/helpers/ 或统一用绝对引用 | 🟡 P2 |
| V-4 | API 测试 `BASE = 'http://localhost:8080/jeecg-boot'` — 仅本地 | 服务端部署时 8080 不可达 → 测试全部挂。应可配置 | 🟡 P2 |
| V-5 | `dbCleanup` 静默失败（`if (!ok) console.log('...')`） | 清理失败无感知 → 下次跑残留数据干扰 | 🟡 P2 |
| V-6 | E2E `page.locator('.ant-drawer .ant-table-tbody .ant-table-row').nth(0).locator('td').nth(0)` | ServiceWorker/chunk 加载变化可能导致 nth(0) 选错行 | 🟡 P2 |

#### 问题 4：E2E 真实性——有没有绕过真实路径的"捷径"？

**有 2 个捷径：**

**捷径 1：** `fixtures.setupFixture()` 通过 API 直接建仓+料+期初入库

```ts
await api('POST', '/mes/basic/warehouse/add', { ... });
await api('POST', '/mes/basic/material/add', { ... });
await api('POST', '/mes/stock/otherIn/add', { ... });
await api('PUT', '/mes/stock/otherIn/audit?id=...');
```

这 4 步通过 API 完成——真实业务人员是通过 UI 创建仓库→物料→入库→审核。但**这个捷径是合理且必要的**：
- 测试目标是盘点单，不是仓库/物料/入库
- 仓库/物料/入库已有自己的测试覆盖
- 如果每个 E2E 都要从"创建仓库"开始 → 测试链 20+ 步 → 脆弱性爆炸

**捷径 2：** 快照明细验证用 API 而非 UI

```ts
const detail = await fx.api('GET', `/mes/stock/stocktake/queryById?id=${pd.id}`);
expect(Number(item.bookQty)).toBe(20);
```

展开行子表已做了 UI 断言（`bodyText 含 matCode`），明细数据由 API 验证。**UI 测"显示是否正确"，API 测"数据是否正确"——分工合理。**

**一个真实的 E2E 太重的场景没有测：** 用户选全盘→后端自动生成 500 行→在 Drawer 中滚动到第 300 行→修改 actualQty=50→保存→再打开确认值没丢。但这属于 E2E 的边缘压力测试，不是必须覆盖。

#### 问题 5：5 断言锚点评分

| # | 锚点 | API 测试 | E2E 测试 | 综合评分 | 说明 |
|---|------|:--:|:--:|:--:|------|
| 1 | **创建断言** | 5/5 | 5/5 | **5** | code 非空(自动生成)+status='1'+book/cost 精确 |
| 2 | **状态流转断言** | 4/5 | 5/5 | **4.5** | 草稿→已审核 ✅，缺反审核(设计如此)，缺"审核后不可编辑" |
| 3 | **数据传递断言** | 5/5 | 5/5 | **5** | 库存变化量 = 单据申报量(100→95, 95→98) ✅ |
| 4 | **显示值断言** | 1/5 | 4/5 | **2.5** | E2E 测了编码显示 ✅，但 API 完全没测显示值(这是 API 测试的天然盲区——无法测渲染层) |
| 5 | **清理断言** | 4/5 | 4/5 | **4** | 唯一编码 ✅ + DB+API 双段清理 ✅，但清理失败静默无断言 |

**最低分项：锚点 #4（显示值断言）——2.5 分。** 这是 API 测试天然无法覆盖的维度。E2E 只能部分覆盖（全页文本搜索是弱断言）。补法：
- E2E 加精确的 DOM 断言：`expect(subTableRow.locator('td').nth(0)).toContainText('MAT-')` — 验证子表物料列含编码前缀
- 抽盘抽屉物料列同样加 DOM 级断言

---

## 三、建议 💡

### 3.1 补 batchAudit + refreshItems + 抽盘测试（P0/P1）

```javascript
// stocktake.test.js 加:
// 场景5: batchAudit 批量审核（事务性验证：2条全绿 vs 1条失败全部回滚）
// 场景6: refreshItems 刷新后 actualQty 保留 + unitCost 保留
// 场景7: 抽盘手工选物料 → book_qty 后端校验通过/失败
```

### 3.2 E2E 显示值断言从全页搜索改为 DOM 级

```ts
// 替换: expect(bodyText).toContain(fx.matCode);
// 为:
const subTable = page.locator('.ant-table-expanded-row .ant-table');
await expect(subTable.locator('td').first()).toContainText(fx.matCode);
```

### 3.3 补盘盈侧 generatedInId + 金额对账

```javascript
// stocktake.test.js 场景3 后加:
const detail2b = await api('GET', `/mes/stock/stocktake/queryById?id=${pd2.id}`, token);
check('generatedInId 已回写', !!detail2b.result.items[0].generatedInId, ...);

const inDoc = await api('GET', `/mes/stock/otherIn/queryById?id=${detail2b.result.items[0].generatedInId}`, token);
check('盘盈入库金额=diffAmount', Number(inDoc.result.totalAmount) === ..., ...);
```

### 3.4 补审核后编辑拦截测试（API + E2E）

```javascript
// API:
const editAudited = await api('PUT', '/mes/stock/stocktake/edit', token, { id: pd1.id, ... });
check('已审核单编辑被拒', editAudited.code !== 200, editAudited.message);

// E2E: 验证已审核单操作列无"录入实盘"按钮
```

### 3.5 E2E 脆弱性修复

| 修复项 | 内容 |
|--------|------|
| V-1 全页文本搜索 | 改为 `.ant-table-expanded-row` 限定范围 |
| V-3 import 路径 | `fixtures.js` 移到 `harness/e2e/mes/helpers/` 目录 |
| V-4 BASE URL 硬编码 | 读环境变量 `API_BASE`（`helpers/auth.ts` 已有 `API_BASE` 但测试文件没 import）——实测 `stocktake.spec.ts` 已 import `API_BASE` ✅ |

---

## 评审总结

| 维度 | 结论 |
|------|------|
| 断言质量 | 🟢 优秀 — 0 个水断言，24 个全部有具体预期值 |
| 覆盖盲区 | 🔴 batchAudit(P0)+refreshItems(P1)+抽盘(P1) 三个新功能零覆盖 |
| 测试脆弱性 | 🟡 6 个脆弱点，最严重为 E2E 全页文本搜索（P1） |
| E2E 真实性 | 🟢 API 准备数据合理（测试目标外），UI 和 API 验证分工清晰 |
| 5 锚点评分 | 总分 21/25，最低分锚点#4 显示值 2.5/5 |
| 清理方案 | ✅ 迁移到 SQL 文件执行（Windows 兼容），fixtures.js 共享 |

**总体判定：核心流程测试扎实（全盘创建→审核→盘盈/盘亏→库存校准），断言质量优秀。最大问题是 V2 新增的 3 个功能（batchAudit/refreshItems/抽盘）零测试覆盖。补这 3 个场景的 6-8 个断言即可达到"关键业务流 100% 覆盖"目标。E2E 全页文本搜索需改为 DOM 级限定搜索防止误判。**
