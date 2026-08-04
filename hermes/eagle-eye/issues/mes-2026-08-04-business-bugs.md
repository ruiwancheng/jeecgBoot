# MES 业务 Bug 清单（按模块分桶）

> 生成时间：2026-08-04T14:32:12+08:00
> 数据来源：`harness/.e2e-results.json`（32 E2E 失败） + 链路日志（4 链路失败）
> 提交 commit：`f15cae8 test(e2e): 补齐 10 个缺失的 MES 页面 E2E spec`
> 跑测命令：`PLAYWRIGHT_BASE_URL=http://localhost:3100 npx playwright test e2e/mes/ --workers=4`

## 总览

| 模块 | 失败切片数 | P1 | P2 | P3 |
|---|---|---|---|---|
| basic | 4 | 2 | 1 | 1 |
| batch | 3 | 0 | 1 | 2 |
| finance | 4 | 0 | 4 | 0 |
| purchase | 1 | 1 | 0 | 0 |
| sales | 1 | 0 | 0 | 1 |
| **合计** | **13** | **3** | **6** | **4** |

## 严重程度定义

- **P1**：整页不可用（所有/大部分交互失败），阻塞业务
- **P2**：核心流程缺失（新增/导出/抽屉触发等），数据可看不可改
- **P3**：次要按钮或契约不一致，不影响主流程

## 复核进度跟踪

| # | Issue | 严重程度 | 复核状态 | 核实结果 |
|---|---|---|---|---|
| 1 | 库存总览 (`/project/mes/warehouse/inventory`) | P1 | ✅ 误判 | URL 写错 + 页面是只读 dashboard，原 spec 误把“导出/新增/抽屉”当必备能力 |
| 2 | 库存预警 (`/project/mes/basic/inventoryAlert`) | P2 | 🔴 真实需求（产品优化） | 测试侧误判（spec 按 CRUD 模板生成） + 产品侧明确需要优化（用户判断：当前基本无用） |
| 3 | 编码规则 (`/project/mes/basic/codeRule`) | P3 | 🔵 待复核 | — |
| 4 | 通用设置 (`/project/mes/basic/commonSetting`) | P1 | 🔵 待复核 | — |
| 5 | 批次台账 (`/project/mes/batch/ledger`) | P3 | 🔵 待复核 | — |
| 6 | 批次库存 (`/project/mes/batch/inventory`) | P3 | 🔵 待复核 | — |
| 7 | 其它入库自动预填 (`/project/mes/stock/other-in`) | P2 | 🔵 待复核 | — |
| 8 | 应收账款 (`/project/mes/finance/receivable`) | P2 | 🔵 待复核 | — |
| 9 | 收款管理 (`/project/mes/finance/collection`) | P2 | 🔵 待复核 | — |
| 10 | 应付账款 (`/project/mes/finance/payable`) | P2 | 🔵 待复核 | — |
| 11 | 付款管理 (`/project/mes/finance/payment`) | P2 | 🔵 待复核 | — |
| 12 | 采购台账 (`/project/mes/purchase/ledger`) | P1 | 🔵 待复核 | — |
| 13 | 销售链路 fixture (`/project/mes/sales/outbound`) | P3 | 🔵 待复核 | — |

> 复核状态说明：
> - 🔵 待复核
> - 🟡 复核中（有问题/验证中）
> - ✅ 误判（写明核实依据）
> - 🔴 真实 Bug（写明核实依据）

---

## BASIC 模块

### [P1] 库存总览（/project/mes/warehouse/inventory）

- **后端 controller**：`MesInventoryController`
- **原报告症状**：页面 8/8 测试全失败：表格不渲染、列头/搜索/导出/新增按钮、数据行、抽屉、仓库筛选全部缺失

#### ✅ 复核结果：误判（2026-08-04 由 ruiwancheng/pi 复核）

**两个独立问题复合在一起造成误报，需拆开看：**

1. **测试 URL 写错**：spec 里写的是 `/project/mes/basic/inventory`，但菜单注册和 router 都把 inventory 放在 `warehouse` 父节点下，**正确 URL 是 `/project/mes/warehouse/inventory`**。修正 URL 后路由可达。
2. **页面是设计上的只读 dashboard**：
   - 后端 `MesInventoryController` 只暴露 `@GetMapping("/list")`，没有 add/edit/delete/exportXls
   - 前端 `inventory.api.ts` 只导出 `queryInventoryList`
   - 前端 `index.vue` 调用 `useListPage` 时**没有传** `exportConfig`、`importConfig`、也没启用新增/操作列
   - 菜单注册仅给 `mes:inventory:list` 权限
   - 对比仓库管理页（传了 `exportConfig: { url: getExportUrl }` → 有导出按钮），库存总览本来就无导出

**修正 URL + 后端就绪后重测（5 passed / 3 failed）：**

| 测试 | 结果 | 真实原因 |
|---|---|---|
| 1. 路由可达性 | ✅ pass | 路由 OK |
| 2. 表格 + 列头 | ✅ pass | 表格正常 |
| 3. 搜索表单 + 查询 | ✅ pass | 搜索表单正常 |
| 4. 导出按钮 | ❌ fail | **页面没导出按钮（设计如此）** |
| 5. 新增按钮 | ❌ fail | **页面没新增按钮（设计如此）** |
| 6. 数据行 | ✅ pass | 数据正常 |
| 7. 新增抽屉 | ❌ fail | **没新增按钮自然无抽屉（设计如此）** |
| 8. 仓库筛选 | ✅ pass | 仓库下拉正常 |

**核实依据**：调用 `cat jeecgboot-vue3/src/views/project/mes/basic/inventory/inventory.api.ts`、`MesInventoryController.java` 源码 + `MesMenuRegistry.java` 权限标记 + `useListPage` 调用参数对比仓库页。

**action items**（不进排期，作为测试侧改进）：
- 修正 `harness/e2e/mes/basic-inventory.spec.ts` 的 `PAGE_PATH` 为 `/project/mes/warehouse/inventory`
- 调整 4/5/7 三个测试为 `test.skip` 或改成只读断言（这个页面是 dashboard，不该期望新增/导出/抽屉）
- 生成时我把 basic/inventory.spec.ts 全部按 CRUD 模板生成，没看 controller 实际暴露的端点——模板应根据 controller endpoint set 调整
  - `库存总览 8. 仓库筛选可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "库存总览" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P2] 库存预警（/project/mes/basic/inventoryAlert）

- **后端 controller**：`MesInventoryAlertController`
- **症状**：只读页面缺少查询/导出/筛选/新增按钮（后端只暴露 GET /list，前端期望更多操作）
- **失败测试**（5 个）：
  - `库存预警 3. 搜索表单 + 查询按钮可见`
  - `库存预警 4. 导出按钮可见`
  - `库存预警 5. 新增按钮可见`
  - `库存预警 7. 点击新增 → 抽屉可见`
  - `库存预警 8. 预警级别筛选可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "库存预警" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

#### 🔴 复核结果：测试误判 + 产品真实需求（2026-08-04 由 ruiwancheng/pi 复核）

**两层结论（需拆开看，不能简单归为误判）：**

1. **测试侧：5 个 E2E 失败属于误判** — spec 按 CRUD 模板生成，未对照 controller 实际端点
2. **产品侧：用户判断当前页面**“基本没什么用”，**确实需要优化** — 这是真实的产品需求，不能归为误判

**与 #1 库存总览不同** —— #1 是设计合理的只读 dashboard，不该期待 CRUD；#2 是**还没做出业务价值**的占位页面，需要重设计。

#### 🟡 测试侧复核：误判（与 #1 同型）

**核实依据：**

**核实依据：**

| 检查项 | 实际内容 | 文件:行 |
|---|---|---|
| 后端端点 | 仅 `@GetMapping("/list") @RequiresPermissions("mes:inventoryAlert:list")`，无 add/edit/delete/exportXls/importXls | `MesInventoryAlertController.java:24-49` |
| 后端逻辑 | 聚合查询：从 `MesMaterial.safetyStock` 和 `MesInventory.currentQty` 计算缺口并按缺口降序返回，**不接受任何查询参数** | 同上 |
| 前端模板 | 单一 `<a-table>` + `<a-alert>` 提示；无 `<BasicForm>`/`<QueryFilter>`/搜索栏；无 `<a-drawer>`/`<a-modal>`；`:pagination="false"`；用 `ref + onMounted` 拉一次数据，**没有** `useListPage` | `index.vue`（全文 39 行） |
| 前端 API | 仅 `queryInventoryAlerts()` 一个方法，调 `GET /mes/basic/inventoryAlert/list` | `inventoryAlert.api.ts`（全文 3 行） |
| 菜单权限 | `addPerms(list, "mes:inventoryAlert:", ..., new String[]{"list"})` —— 仅 list 一个权限 | `MesMenuRegistry.java:60` |

**实测 spec（5 failed / 3 passed）：**

| 测试 | 结果 | 真实原因 |
|---|---|---|
| 1. 路由可达性 | ✅ pass | 路由 OK |
| 2. 表格 + 列头 | ✅ pass | 表格 6 列（物料编码/名称/当前库存/安全库存/最高库存/缺口）正常 |
| 3. 搜索表单 + 查询按钮 | ❌ fail | **页面无搜索栏（设计如此）** |
| 4. 导出按钮 | ❌ fail | **页面无导出按钮（设计如此）** |
| 5. 新增按钮 | ❌ fail | **页面无新增按钮（设计如此）** |
| 6. 数据行或空状态 | ✅ pass | 数据/空状态正常 |
| 7. 点击新增 → 抽屉 | ❌ fail | **没新增按钮自然无抽屉（设计如此）** |
| 8. 预警级别筛选 | ❌ fail | **页面无 select 筛选（后端不接受任何查询参数）** |

**测试侧 action items**（不进排期，作为测试侧改进）：
- 调整 `harness/e2e/mes/basic-inventoryAlert.spec.ts` 的 3/4/5/7/8 五个测试为 `test.skip`，或改成只读 dashboard 断言（路由 + 表格 + 数据 + 列头）
- 同样问题在 #5 批次台账、#6 批次库存也会出现，需在 spec 改造时统一处理
- gen-tests 模板应根据 controller endpoint set 调整：对只有 GET /list 的 controller，不要生成 add/edit/delete/export 相关的测试
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/basic-inventoryAlert.spec.ts --workers=1
  ```

#### 🔴 产品侧复核：真实需求（用户判断）

**用户判断（2026-08-04）：**
> 这个页面目前就是个纯展示页面，但确实需要做优化，目前基本没什么用

**问题本质：**
- 后端仅返回**一个按缺口排序的扁平表格**，用户无法针对业务场景做任何主动操作
- 没有筛选（按仓库 / 按物料类型 / 按预警级别），实际使用中上千条物料会一屏堆满
- 没有交互（点击物料查看历史 / 触发补货单 / 跳转到采购建议），预警发现后无下游动作
- 没有分组（按仓库 / 按物料类别聚合），不解决**“哪些仓库缺货最严重”**这类管理问题
- 没有导出/汇总邮件/推送，**无法驱动补货流程**

**产品优化方向（待排期讨论，可能包含）：**
- 筛选能力：仓库 / 物料类别 / 预警级别（低/中/高缺口比例）
- 分组视图：按仓库 / 按物料类别聚合
- 交互能力：点击行展开缺料历史 + “一键生成采购建议” / “跳转到采购订单新增页并预填物料”
- 主动推送：低于阈值自动通知采购员
- 导出/汇总：导出当前预警 + 周报/月报汇总

**归属建议**（进入产品排期）：
- 需业务侧明确优化范围（最小可用版 / 完整版）
- 后端：扩展 controller 支持查询参数 + 分组聚合端点
- 前端：重设计为可筛选 + 可分组 + 可交互的预警工作台
- 复核后**不算误判**，纳入 P2 排期

### [P3] 编码规则（/project/mes/basic/codeRule）

- **后端 controller**：`MesCodeRuleController`
- **症状**：导出按钮未渲染（其它基础 CRUD 功能正常）
- **失败测试**（1 个）：
  - `编码规则 4. 导出按钮可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "编码规则" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P1] 通用设置（/project/mes/basic/commonSetting）

- **后端 controller**：`MesGlobalSwitchController`
- **症状**：整页加载失败，浏览器 runtime 报错（"pageerror: any is not defined" 已知 bug 之一）
- **失败测试**（1 个）：
  - `切片B：通用设置页面端到端验证`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "通用设置" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

---

## BATCH 模块

### [P3] 批次台账（/project/mes/batch/ledger）

- **后端 controller**：`MesBatchLedgerController`
- **症状**：只读页面有"新增"按钮但点击后抽屉不显示（与后端只有 GET 端点的事实不符）
- **失败测试**（2 个）：
  - `批次台账 5. 新增按钮可见`
  - `批次台账 7. 点击新增 → 抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "批次台账" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P3] 批次库存（/project/mes/batch/inventory）

- **后端 controller**：`MesBatchInventoryController`
- **症状**：只读页面有"新增"按钮但点击后抽屉不显示
- **失败测试**（2 个）：
  - `批次库存 5. 新增按钮可见`
  - `批次库存 7. 点击新增 → 抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "批次库存" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P2] 其它入库（自动预填）（/project/mes/stock/other-in）

- **后端 controller**：`MesOtherStockInController`
- **症状**：物料选中后未自动预填移动平均成本（已写入 feature 但实现缺）
- **失败测试**（1 个）：
  - `其它入库 › 新增入库单-物料选中后自动预填移动平均成本`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "其它入库（自动预填）" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

---

## FINANCE 模块

### [P2] 应收账款（/project/mes/finance/receivable）

- **后端 controller**：`MesReceivableController`
- **症状**："新增"按钮不渲染；抽屉不可触发（receivable 是自动生成的，无 add 端点，前端 UI 与后端契约错位）
- **失败测试**（2 个）：
  - `应收账款 5. 新增按钮可见`
  - `应收账款 7. 点击新增 → 弹窗/抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "应收账款" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P2] 收款管理（/project/mes/finance/collection）

- **后端 controller**：`MesCollectionController`
- **症状**："点击新增"后抽屉不显示（前端按钮存在但 drawer 渲染失败）
- **失败测试**（1 个）：
  - `收款管理 7. 点击新增 → 弹窗/抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "收款管理" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P2] 应付账款（/project/mes/finance/payable）

- **后端 controller**：`MesPayableController`
- **症状**：新增按钮不渲染 + 抽屉不可触发（同 receivable，自动生成无 add 端点）
- **失败测试**（2 个）：
  - `应付账款 5. 新增按钮可见`
  - `应付账款 7. 点击新增 → 弹窗/抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "应付账款" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

### [P2] 付款管理（/project/mes/finance/payment）

- **后端 controller**：`MesPaymentController`
- **症状**："点击新增"后抽屉不显示
- **失败测试**（1 个）：
  - `付款管理 7. 点击新增 → 弹窗/抽屉可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "付款管理" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

#### 链路失败（2）

- **finance-chain** / 收款单 创建：code=COL-1785822880128 success=false — 收款单 add 端点失败（前后端契约不一致或权限缺失）
- **finance-chain** / 销项发票 创建：code=SI-1785822880128 success=false — 销项发票 add 端点失败

---

## PURCHASE 模块

### [P1] 采购台账（/project/mes/purchase/ledger）

- **后端 controller**：`MesCostLogController + MesInventoryLedgerController`
- **症状**：整页 7/8 测试失败：表格/搜索/导出/新增/数据/抽屉/tab 切换全部异常
- **失败测试**（7 个）：
  - `采购台账 2. 表格 + 列头可见`
  - `采购台账 3. 搜索表单 + 查询按钮可见`
  - `采购台账 4. 导出按钮可见`
  - `采购台账 5. 新增按钮可见`
  - `采购台账 6. 数据行或空状态可见`
  - `采购台账 7. 点击新增 → 抽屉可见`
  - `采购台账 8. 成本/库存台账 tab 切换可见`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "采购台账" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

---

## SALES 模块

### [P3] 销售链路 fixture（/project/mes/sales/outbound）

- **后端 controller**：`—`
- **症状**：sales-receipt-flow.test.js 无法创建客户 fixture：admin 缺 mes:basic:add 权限，链路起点失败
- **失败测试**（1 个）：
  - `sales-receipt-flow step 0.3`
- **复现命令**：
  ```bash
  cd harness && PLAYWRIGHT_BASE_URL=http://localhost:3100 \
    E2E_UI_BASE=http://localhost:3100 E2E_API_BASE=http://localhost:8080/jeecg-boot \
    npx playwright test e2e/mes/ --grep "销售链路 fixture" --workers=1
  ```
- **归属建议**：业务前端 + 后端联调（路由/契约/UI 实现）

#### 链路失败（1）

- **sales-receipt-flow** / 0.3 创建客户：Subject does not have permission [mes:basic:add] — admin 缺 mes:basic:add 权限，链路 fixture 创建失败

---

## STOCK 模块

#### 链路失败（1）

- **warehouse-chain** / m1 初始库存入库：records=0 — 入库未生效，库存台账未生成流水

---

## 处理建议

1. **P1 先修**（基本 + 采购台账）：整页不可用，影响演示和日常操作
2. **P2 批量修**（财务 4 个 + 其它入库自动预填）：抽屉触发和前端契约
3. **P3 顺手清**（批次只读页 + 编码规则 + 销售 fixture）：UI 与后端契约对齐

## 不在本次范围

- 不修改 harness runner（已验证 E2E 失败是产品问题）
- 不修改业务代码（按 CLAUDE.md "不因为单个 E2E 失败自动修改业务代码"）
- 不修改 router/routes（已确认通过 MesMenuRegistry + 动态 addRoute 可达）
