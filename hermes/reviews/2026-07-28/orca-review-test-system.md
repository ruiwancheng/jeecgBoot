# Orca 评审：Harness 测试体系改进方案

> 评审对象：`hermes/reviews/2026-07-28/test-system-review-input.md`
> 评审日期：2026-07-28
> 评审依据：现有 harness 测试基础设施（API 测试 6 个、E2E 3 个 spec、chain 测试 2 个、pre-deploy-check 钩子、testing.md 规则、helpers/auth.ts）
> 输出：`hermes/reviews/2026-07-28/orca-review-test-system.md`

---

## 一、通过 ✅

以下改进方案经对照现有测试基础设施验证后确认方向正确、可行：

### 1.1 P0：把测试钉进关键路径 ✅

**方向完全正确。** 现状中 `/done`、`/finish` 写了"测试必须过"，但实际执行路径是 `/verify → /pre-commit-gate → git commit → 部署`，测试在关键路径之外——这是复盘 4 个 bug 漏到人工发现的根因。

**pre-deploy-check 钩子加关键套件的可行性：**

现有 `pre-deploy-check.sh` 已经拦截了 `docker compose up`，跑 3 项轻量检查（登录/菜单/前端可达），约 5 秒。加关键套件的代价分析：

| 套件 | 耗时 | 依赖 | 钩子执行 |
|------|:--:|------|---------|
| 登录+菜单+前端 | ~5s | curl only | ✅ 已内置 |
| 关键 API 套件（8 模块 × ~30s） | ~4min | Node.js + MySQL + 后端在线 | ⚠️ 需后端在线 |
| 关键 E2E（~3 个 spec） | ~3min | Node.js + Playwright + 浏览器 | ⚠️ 需前端在线 |

**关键发现：** 部署前 Check 钩子是在 `docker compose up` 前触发的——此时**后端可能未启动**。API/E2E 套件无法在钩子中跑，因为：

1. 部署前 = 旧版本在线（测试旧版本无意义）
2. 部署后 = 新版本刚启动，钩子拿不到新部署的 commit diff
3. 钩子执行超时限制：Playwright 超时通常 30s，钩子总耗时 >5min 会严重影响部署体验

**修正建议：**

不只是改钩子，而是改"部署后验证流程"。当前 `deploy-verify.md` 已定义了部署后三路并行验证——但当前只做了**冒烟检查**（API 可达性），没有运行真实业务流测试。应该扩展 `/deploy-verify` 的内容：

```
/deploy-verify 扩展后：
  ├─ 冒烟（现有）：登录 + 菜单 + 前端可达（~5s）
  ├─ API 关键套件（新增）：创建→审核→状态→库存校准（~4min）
  └─ E2E 关键流（新增）：1 条完整业务流（~2min）
```

**pre-deploy-check 钩子的角色调整：**
- 钩子保持轻量（当前 3 项检查，<10s）—— 检测后端是否在线、前端是否可达
- 钩子发现失败时输出提示："部署前验证 ❌，建议先跑 /deploy-verify 定位问题"
- **不在钩子中跑重测试** — 钩子是秒级门控，测试是分钟级门控，两者分开

### 1.2 P1：新模块测试模板（/plan 固定一栏）✅

**方向正确。** 盘点单模块的 `stocktake.test.js` 已经是这个模板的实例——14 个场景覆盖全盘/抽盘/盘盈/盘亏/守卫，数据从 API 真实创建。做得好的点：

- 数据隔离：唯一编码后缀 `Date.now()`，不同测试次不冲突 ✅
- 全链路：创建→审核→库存→成本→回写，一步不跳 ✅
- 清理：`dbCleanup` 函数删所有关联数据 ✅
- 显示值断言：`check('generatedOutId 已回写', !!item.generatedOutId, ...)` ✅

**不足（也是方案要改进的）：**
- `dbCleanup` 仍用 `execSync('mysql ...')` — Windows 引号问题（见 P2 改进方案的环境自愈条目）
- 代码长度 129 行，含大量 setup/cleanup 样板 — 需要 template 化

### 1.3 P2：规则对齐 ✅

**testing.md 改写"token 注入合法化"完全正确。** 现状 logic：

```
# testing.md 原文：
"E2E 测试用浏览器登录（fill+click），不直接设 Token"

# 实际代码（other-stock-in.spec.ts:5）：
import { loginViaApi } from './helpers/auth';
```

规则和现实矛盾 — 代码已经用了 API 登录注入 token，规则却禁止。应该改为"登录统一用 `loginViaApi(page, path)` helper，禁止各 spec 重复写注入逻辑" — 这就是 `frontend.md` 中已经写了的规范（来源：2026-07-28 E2E 体系建设）。

### 1.4 复盘 4 个 bug × 4 个盲区的诊断准确 ✅

| Bug | 盲区 | 诊断准确性 |
|-----|------|:--:|
| 物料显示 ID | API 测试只断数不不断显示值 | ✅ 准确 — `stocktake.test.js` 只查 `item.generatedOutId` 存在性，没查渲染层 |
| 账面数取值有误 | 测试 payload 手工想当然 | ✅ 准确 — 前端 `actualQty` 初始值逻辑复杂，API 测试 payload 是手工造的 |
| 审核未生效 | 没有 E2E 完整业务流 | ✅ 准确 — 新模块只有 API，没有 Playwright 走完整业务流程 |
| 明细过多 | P0 修复副作用，自动化测不出 | ✅ 准确 — 自动化验证数据正确但不会评估 UX（500 行滚动是否灾难） |

---

## 二、遗漏 ⚠️

以下风险点改进方案未覆盖：

### 2.0（待评审问题逐答）

#### 问题 1：关键套件钉进门禁会不会太重？

**结论：分两层，不在钩子中跑。**

| 层级 | 触发时机 | 内容 | 耗时 | 通过标准 |
|------|---------|------|:--:|---------|
| **L1：钩子门控** | `docker compose up` / `start-docker-compose` 前 | 当前 3 项（登录+菜单+前端） | <10s | 全部 ✅ |
| **L2：部署后验证** | 部署完成后手动 `/deploy-verify` | API 关键套件 + E2E 关键流 | 5-8min | 关键流全绿 |

**业务方接受的节奏：**
- 每次部署：钩子 10s（无感）+ 手动 `/deploy-verify` 5min（喝杯水）
- 部署是一个低频操作（日 1-2 次），5-8 分钟的验证不是负担，而是保险
- API only (~2min) 作为快速模式：`/deploy-verify --api-only` 给轻量变更

**不推荐只跑 API（~2min）跳过 E2E** — 复盘 bug 3（审核未生效）恰恰是只有 API 没 E2E 才漏的。E2E 的价值不在"测功能"(API 也能测)而在"测集成"——浏览器完整业务流。

#### 问题 2：影子模式 2 周转阻断合理吗？

**结论：合理，但加一个条件——"预存在失败已清零"。**

影子模式转阻断的前提：
1. ✅ 2 周内关键套件至少跑了 5 次部署验证
2. ✅ 未出现误报阻断（测试自身的 bug 导致的失败 < 20%）
3. ⚠️ **预存在失败已清零**（当前的 2 个 chain 测试破窗必须先修或隔离）

第 3 点最关键：如果有已知的失败测试，阻断机制一开始就是"假阳性"——用户看到红，问"是这次部署弄坏的吗" → 回答"不是，是一直坏着的" → 信任崩溃。影子模式的核心目标是建立信任，不是技术上线。

**建议：** 转阻断前先修或注释掉 2 个破窗链测试，确保"红 = 真的有问题"。

#### 问题 3：新模块三件套会不会导致水测试？

**结论：不会 — 如果给模板生成最小的"断言锚点"。**

"水测试"的根因不是模板，而是**缺乏验证标准**。模板如果只写 "创建→审核→验证" 三个词，开发者会填最小可通过的内容。如果模板写的是：

```javascript
// 【必填断言锚点】
// 1. 创建后：code 非空 + status='1'
// 2. 审核后：status='2' + 库存实际变化量 = 单据申报量
// 3. 反审核后：status='1' + 库存恢复原值
// 4. 显示值断言：物料列显示编码（如 'MAT-001'），非 ID（如 'abc123'）
// 5. 守卫断言：已审核单不可编辑/删除
```

然后让 AI 生成上述断言的具体数据（具体数值、具体编码），"水"的难度比"正常写"还大。模板的价值是**锚定验证点**不是**锚定空流程**。

**防敷衍机制：**
- `/plan` 输出时显式列"测试断言锚点"一栏（5 项必填）
- 部署验证时检查"新模块是否有对应的 test.js 且至少 5 条断言"
- 缺少断言锚点 → `/deploy-verify` 输出 WARN："模块 X 测试存在但断言不足（3/5 项），建议补充"

#### 问题 4：放弃 60% 覆盖率改"关键业务流 100%"，会不会范围越缩越小？

**结论：不会 — 如果配套"关键路径注册表"。**

60% 行覆盖率 vs 100% 业务流覆盖率，本质是"覆盖所有代码" vs "覆盖所有关键路径"。后者更难作弊：代码覆盖率可以加 100 个单元测试刷满，但关键路径必须真实走完整业务流。

**关键路径注册表（防止退化）：**

```json
// hermes/business-chains.json 中扩展每个模块的 tests.criticalPaths
{
  "criticalPaths": [
    "PUT /mes/stock/stocktake/audit → 盘点审核 → 自动生成出/入库单 → 库存校准",
    "GET /mes/stock/stocktake/queryById → 盘点详情含 generatedInId/generatedOutId 回写",
    "PUT /mes/stock/stocktake/edit → 编辑盘点单 → 抽盘行 book_qty 后端校验"
  ]
}
```

`/deploy-verify` 执行时：
1. 读 `business-chains.json` 获取本模块的关键路径列表
2. 逐路径执行验证
3. 全部通过 → PASS；有遗漏路径 → WARN "模块 X 关键路径 Y 未验证"

**防止缩小的机制：** 每次新增模块时，`/plan` 输出必须含 `criticalPaths` 定义。没有定义 → `/deploy-verify` 报 WARN。关键路径清单**只增不减**。

#### 问题 5：有没有遗漏的改进点？

**有。以下 4 个在当前方案中未提及但在现有代码中已经出现的问题：**

##### 遗漏 A：🔴 P1 — 测试数据 seed 管理缺失

`stocktake.test.js` 的 Setup 逻辑：

```javascript
await api('POST', '/mes/basic/warehouse/add', token, { code: whCode, name: '盘点测试仓', status: 1 });
await api('POST', '/mes/basic/material/add', token, { code: matCode, name: '盘点测试料', type: '1' });
await api('POST', '/mes/stock/otherIn/add', token, { code: inCode, inType: '2', warehouseId: whId, ... });
await api('PUT', `/mes/stock/otherIn/audit?id=${inDoc.id}`, token);
```

4 个 API 调用做数据准备，另有 1 个 `dbCleanup` 函数做 SQL 清理。每个新模块的测试文件都重复这套逻辑。改进方案的环境自愈只提到了清理的 SQL 执行方式，没有提到**种子数据创建应该用共享 fixture**。

**改进建议：**
```javascript
// harness/tests/mes/helpers/fixtures.js
export async function createTestWarehouse(token, suffix) { ... }
export async function createTestMaterial(token, suffix) { ... }
export async function createAndAuditStockIn(token, whId, matId, qty, unitCost) { ... }
export async function cleanupTestData(token, whId, matId, pdCodes) { ... }
```

所有测试公共的 Setup/Cleanup 用共享 helper，减少 50% 样板代码，也降低"手工写错 payload"的概率。

##### 遗漏 B：🟡 P2 — 测试失败根因定位

当前的测试框架在断言失败时只打印：

```
❌ 快照明细 book=100: book=95
```

不打印：哪个 API 返回的 / 具体请求 payload / 完整 response。开发者需要加 `console.log` 重新跑一次才能定位。改进方案应加一条：**测试断言失败时自动打印上一轮 API 的完整 request 和 response**。

```javascript
function check(name, ok, detail) {
  if (!ok) {
    console.error(`  ❌ ${name}: ${detail}`);
    console.error(`     Last API: ${lastMethod} ${lastUrl}`);
    console.error(`     Response: ${JSON.stringify(lastResponse).substring(0, 200)}`);
  }
}
```

##### 遗漏 C：🟡 P2 — 渲染层断言的更轻手段（组件测试/Vitest 截图对比）

复盘 bug 1（物料显示 ID）属于渲染层问题，当前有两种检测手段：

| 手段 | 检测能力 | 耗时 | 适用性 |
|------|---------|:--:|------|
| E2E (Playwright) | 完整业务流 + 页面断言 | 2-5min | 关键路径 |
| 组件测试 (Vitest + Testing Library) | 单组件渲染验证 | <1s | 渲染层回归 |
| API 测试 | 数据正确性 | 1-5s | 业务逻辑 |

**渲染层 Bug 的分类检测矩阵：**

| Bug 类型 | API 可测？ | 组件测试可测？ | E2E 可测？ |
|---------|:--:|:--:|:--:|
| 显示 ID 而非编码 | ❌ | ✅ `expect(screen.getByText('MAT-001')).toBeVisible()` | ✅ |
| 金额精度错误 | ✅ `expect(amount).toBe(500.00)` | ✅ | ✅ |
| 差异高亮颜色 | ❌ | ✅ `expect(el).toHaveStyle({color:'#f5222d'})` | ✅ |
| 500 行明细 UX | ❌ | ❌ | ✅ 截图对比 |

**组件测试 (Vitest + Testing Library) 是最轻的渲染层验证手段**——比 E2E 快 100-1000 倍，可以覆盖 "显示值是编码不是 ID"、"金额精度"、"颜色样式" 等渲染层问题。但当前 MES 项目零组件测试。

改进方案应加一条 P2：**对高频变更的组件（Drawer 物料列、金额列、状态标签）加 1-2 条组件测试**。E2E 保留用于关键业务流验证，组件测试用于渲染层回归。

##### 遗漏 D：🟡 P2 — `/gen-tests` 闭环验证

改进方案提到"/gen-tests 用一次或删"。应该先验证它是否能生成正确的断言。用 `/gen-tests stocktake` 实际跑一次，把输出和手工写的 `stocktake.test.js` 对比——如果 AI 生成的质量 ≥ 手工写的 80%，就保留并改进；如果 ≤ 50%，就删除避免误导。

---

## 三、建议 💡

### 3.1 pre-deploy-check 钩子加一套 "关键套件" 的轻量提示

```
[Super Harness] 部署前验证: ✅ 3 通过 | ⚠️ 0 警告 | ❌ 0 失败
📊 关键套件状态（最近一次 /deploy-verify）:
  ✅ basic.test.js      (32s ago, 12/12)
  ✅ purchase.test.js    (32s ago, 18/18)
  ✅ stocktake.test.js   (32s ago, 14/14)
  ❌ purchase-apply-order.chain.test.js (32s ago, 2/3)
⚠️  1 个链测试预存在失败 — 建议部署前先修复或隔离
```

钩子不跑套件（太重），但提示最近一次套件状态——让部署者知道"上次验证的状态"。

### 3.2 testing.md 应形成三层结构

| 层 | 内容 | 当前状态 |
|----|------|:--:|
| **L0：规则** | 测试级别（轻量/标准/全量）+ 覆盖率目标（关键业务流 100%） | testing.md 已有部分 |
| **L1：模板** | API 测试模板 + E2E 测试模板 + 5 断言锚点 | **缺失** ← 需新增 |
| **L2：实践** | 4 bug × 4 盲区的诊断故事（用真实案例教育） | **缺失** ← 需新增 |

### 3.3 测试断言锚点五条

每个模块测试文件必须覆盖：

1. **创建断言**：code 非空 + status='1'
2. **状态流转断言**：草稿→审核→已审核 + 守卫（审核后不可编辑）
3. **数据传递断言**：审核前后的库存变化量 = 申报量
4. **显示值断言**：物料列显示编码/名称，非 ID
5. **清理断言**：测试后无残留数据

### 3.4 fixture 共享 helper 文件结构

```
harness/tests/mes/helpers/
  ├── fixtures.js    — createTestWarehouse / createTestMaterial / cleanupTestData
  ├── api.js         — login / api(method, path, token, body) 统一封装
  └── assert.js      — check(name, ok, detail) + 自动输出 last API 信息
```

这是改进方案的环境自愈条目的自然延伸。

---

## 评审总结

| 维度 | 结论 |
|------|------|
| 方向正确性 | ✅ P0/P1/P2 分级合理 — 把测试钉进关键路径是第一优先级 |
| pre-deploy-check 加套件 | ⚠️ 需修正 — 不在钩子中跑重测试，改为扩展 `/deploy-verify` |
| 影子 2 周转阻断 | ✅ 合理 — 但需先清零预存在失败（修或隔离 2 个破窗链测试） |
| 新模块三件套 | ✅ 方向正确 — 需要"5 断言锚点"作为防敷衍机制 |
| 放弃 60% 覆盖率 | ✅ 用"关键路径注册表"耦合 `/deploy-verify` 可防止退化 |
| 遗漏改进点 | 4 项 — seed fixture 共享 / 断言失败根因 / 组件测试补充 / gen-tests 验证 |

**总体判定：方案分析深刻（4 bug × 4 盲区复盘极为透彻），改进方向正确。主要修正：pre-deploy-check 不跑测试，改为扩展 `/deploy-verify` 的内容。补充 4 项遗漏改进点（fixture 共享、根因定位、组件测试、gen-tests 闭环）。影子模式转阻断前先清零破窗。**
