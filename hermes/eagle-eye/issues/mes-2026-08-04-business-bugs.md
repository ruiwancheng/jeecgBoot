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
| 1 | 库存总览 (`/project/mes/basic/inventory`) | P1 | 🔵 待复核 | — |
| 2 | 库存预警 (`/project/mes/basic/inventoryAlert`) | P2 | 🔵 待复核 | — |
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

### [P1] 库存总览（/project/mes/basic/inventory）

- **后端 controller**：`MesInventoryController`
- **症状**：页面 8/8 测试全失败：表格不渲染、列头/搜索/导出/新增按钮、数据行、抽屉、仓库筛选全部缺失
- **失败测试**（7 个）：
  - `库存总览 2. 表格 + 列头可见`
  - `库存总览 3. 搜索表单 + 查询按钮可见`
  - `库存总览 4. 导出按钮可见`
  - `库存总览 5. 新增按钮可见`
  - `库存总览 6. 数据行或空状态可见`
  - `库存总览 7. 点击新增 → 抽屉可见`
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
