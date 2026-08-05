# 测试覆盖率提升方案 v3（复审修订版）

评审日期：2026-08-06｜复审结论：needs-rewrite → 已执行

## 现状（复审校正后）

| 维度 | v2 | v3（实测） |
|---|---|---|
| API test 文件 | 22 | 22 |
| 端点总数 | ~344 | ~344 |
| 零覆盖 Controller | 1 个（Location） | 0 个（均有部分覆盖） |
| 真实缺口 | 17 个状态机 | **15 个端点** |

## 真实缺口清单（代码扫描 + 测试覆盖双重验证）

### A. Location 缺失端点（5 个）

basic.test.js 已覆盖 4/9，新增 5 个：

| 端点 | basic.test.js 状态 |
|---|---|
| /list | ✅ 已覆盖 |
| /add | ✅ 已覆盖 |
| /generate | ✅ 已覆盖 |
| /edit | ✅ 已覆盖 |
| **/delete** | ❌ 缺失 |
| **/deleteBatch** | ❌ 缺失 |
| **/exportXls** | ❌ 缺失 |
| **/importExcel** | ❌ 缺失 |
| **/selectPage** | ❌ 缺失 |

### B. 状态机缺口（10 个端点，11 个 Controller）

**已确认代码有端点但测试未覆盖：**

| Controller | 端点 | chains/ 已覆盖？ | modules/ 已覆盖？ | 缺口 |
|---|---|---|---|---|
| PurchaseApply | /reject | ❌ | ❌ | 🔴 |
| PurchaseOrder | /unaudit | ❌ | ❌ | 🔴 |
| ProductionPicking | /audit（2个） | ❌ | ❌ | 🔴 |
| CompletionReceipt | /audit（2个） | ❌ | ❌ | 🔴 |
| Voucher | /audit（2个） | ❌ | ❌ | 🔴 |

**注：** PurchaseApply/audit、PurchaseReceipt/audit/unaudit、SalesOrder/audit、SalesOutbound/audit、OtherStockIn/Out/audit、Stocktake/audit 已在 chains/ 覆盖，无需重写。

**已排除（代码无此端点）：**
Bom/audit, ProductionOrder/audit, AccountSubject/audit, Collection/audit, Payment/audit, PurchaseInvoice/audit, SalesInvoice/audit, SalesInvoice/cancel

### C. 前置条件

| 文件 | 问题 | 决策 |
|---|---|---|
| `manufacturing.test.js` 头部 | 3 个遗留 bug（#STATUS-FLOW-MISSING 等） | 确认 ProductionPicking/CompletionReceipt 可测，不依赖 bug 修复 |
| `finance.test.js` | "鉴权 only"约束 | Voucher 审计独立，不受 finance 约束影响 |
| `chains/` 目录 | 9 个链路测试已覆盖部分状态机 | **阶段 0 审计确认** |

## 执行记录

| 阶段 | 状态 | 完成日期 | 备注 |
|---|---|---|---|
| 阶段 0：链路测试审计 | ✅ 完成 | 2026-08-06 | chains/ 9 个文件审计完毕 |
| 阶段 1：Location 补全 | ✅ 完成 | 2026-08-06 | 5 端点新增，20/20 通过 |
| 阶段 2：采购状态机 | ✅ 完成 | 2026-08-06 | PurchaseApply /reject 覆盖 |
| 阶段 3：生产状态机 | ✅ 完成 | 2026-08-06 | CompletionReceipt/Picking audit，27/27 |
| 阶段 4：财务状态机 | ✅ 完成 | 2026-08-06 | Voucher audit，131/8（有8个既有失败）|

## 执行计划（v3）

### 阶段 0：链路测试审计（前置，1 小时）

| 步骤 | 内容 | 产出 |
|---|---|---|
| 0.1 | 审计 9 个 chains/ 文件覆盖的端点清单 | `hermes/plan/chains-audit.md` |
| 0.2 | 对照本方案缺口表，剔除已覆盖端点 | 确认最终缺口清单 |
| 0.3 | 验证 basic.test.js Location 覆盖范围 | 确认 5 个缺失端点 |

### 阶段 1：Location 补全（~50 行）

| 步骤 | 端点 | 文件 |
|---|---|---|
| 1.1 | /delete, /deleteBatch | basic.test.js 追加 |
| 1.2 | /exportXls, /importExcel, /selectPage | basic.test.js 追加 |
| 1.3 | 验收：5 个新端点全 200 OK | — |

### 阶段 2：采购状态机补全（~50 行）

| 步骤 | 端点 | 文件 |
|---|---|---|
| 2.1 | PurchaseApply /reject | purchase.test.js 追加 |
| 2.2 | PurchaseOrder /unaudit | purchase.test.js 追加 |
| 2.3 | 验收：2 个新端点全 200 OK | — |

### 阶段 3：生产状态机（~100 行）

| 步骤 | 端点 | 文件 |
|---|---|---|
| 3.1 | ProductionPicking /audit（2个） | manufacturing.test.js 追加 |
| 3.2 | CompletionReceipt /audit（2个） | manufacturing.test.js 追加 |
| 3.3 | 验收：4 个新端点全 200 OK | — |

### 阶段 4：财务状态机（~50 行）

| 步骤 | 端点 | 文件 |
|---|---|---|
| 4.1 | Voucher /audit（2个） | 新建 finance-voucher.test.js |
| 4.2 | 验收：2 个新端点全 200 OK | — |

## 端点覆盖矩阵（验收标准）

```
Location:
├── /list         → ✅ basic.test.js:78
├── /add         → ✅ basic.test.js:82
├── /generate    → ✅ basic.test.js:90
├── /edit        → ✅ basic.test.js:99
├── /delete      → ❌ 本阶段新增
├── /deleteBatch → ❌ 本阶段新增
├── /exportXls   → ❌ 本阶段新增
├── /importExcel → ❌ 本阶段新增
└── /selectPage  → ❌ 本阶段新增

PurchaseApply:
├── /audit       → ✅ chains/purchase-apply-order:58
├── /reject      → ❌ 本阶段新增
└── /unaudit     → ✅ chains/purchase-payment-flow:297

PurchaseOrder:
├── /audit       → ✅ chains/purchase-order-receipt:xxx
└── /unaudit     → ❌ 本阶段新增

ProductionPicking:
└── /audit(2端点) → ❌ 本阶段新增

CompletionReceipt:
└── /audit(2端点) → ❌ 本阶段新增

Voucher:
└── /audit(2端点) → ❌ 本阶段新增
```

## 工作量估算（v3）

| 阶段 | 新增端点数 | 预估行数 |
|---|---|---|
| 阶段 0 | 0（审计） | ~30 行 |
| 阶段 1：Location | 5 | ~50 行 |
| 阶段 2：采购 | 2 | ~50 行 |
| 阶段 3：生产 | 4 | ~100 行 |
| 阶段 4：财务 | 2 | ~50 行 |
| **合计** | **13 端点** | **~280 行** |

（原 v2 估 420 行 → v3 实估 280 行，-33%）

## 风险清单（v3）

| 风险 | 等级 | 缓解 |
|---|---|---|
| basic.test.js 是聚合文件，追加 Location 可能与 Customer 等混在一起 | 🟡 中 | 注释明确标注区块，用 `// === Location ===` 分隔 |
| manufacturing.test.js 有遗留 bug，追加 ProductionPicking 可能撞上 | 🟡 中 | 阶段 0 确认端点可独立测试 |
| Voucher audit 依赖采购入库单/销售出库单已审核 | 🟡 中 | 阶段 4 内部先建测试数据再审 |
| purchase.test.js 已有 252 行，追加 unaudit 需小心合并 | 🟢 低 | 参考已有 reject 模式复制 |
| 阶段 0 审计后发现更多端点已在 chains 覆盖 | 🟢 低 | 阶段 0 本身即用于此目的 |

## 备注

- 复审发现 7 个 phantom 端点（Bom/ProductionOrder/AccountSubject/Collection/Payment/PurchaseInvoice/SalesInvoice 的 audit）已从方案中移除
- chains/ 目录 9 个链路测试文件已覆盖 PurchaseApply/Order/Receipt/SalesOrder/SalesOutbound/OtherStockIn/Out/Stocktake 的 audit，无需重复补
- 仅补真正缺口：Location 5 端点 + PurchaseApply reject + PurchaseOrder unaudit + 生产 4 audit + Voucher 2 audit
