# 测试漏洞修复计划（基于 codex 审计）

生成日期：2026-08-06｜审计来源：codex review-test-coverage-gaps

## P0 漏洞（第一周）

### P0-1：MesDeliveryNote 状态机补全
- 文件：新建 `harness/tests/modules/sales-delivery.test.js`
- 端点：/cancel, /submit
- 依赖：SalesOrder 已审核才能 submit

### P0-2：MesBatch freeze/unfreeze 补全
- 文件：新建 `harness/tests/modules/batch-freeze.test.js`
- 端点：/freeze, /unfreeze
- 依赖：需要有真实批次数据

### P0-3：MesWarehouse activate/deactivate 补全
- 文件：扩展 `harness/tests/modules/basic.test.js` 或 `warehouse-chain.test.js`
- 端点：/activate, /deactivate

### P0-4：audit rollback 断言增强
- 文件：扩展以下文件，在 audit 后追加 unaudit 验证段
  - `harness/tests/modules/purchase.test.js`
  - `harness/tests/modules/manufacturing.test.js`
  - `harness/tests/modules/finance.test.js`
- 模板参考：`basic-otherStockOut.test.js` 的 rollback 段（13 处断言）

### P0-5：并发测试底座
- 文件：新建 `harness/tests/concurrent/audit-concurrent.test.js`
- 内容：Promise.all 并发 audit × 5 请求，验证仅 1 个成功其余被拦截

## P1 漏洞（第二周）

### P1-1：库存台账对账增强
- 文件：扩展 `warehouse-chain.test.js`
- 内容：audit 后断言 ledger 记录数 +1

### P1-2：PurchaseInvoice + SalesInvoice CRUD
- 文件：新建 `harness/tests/modules/finance-invoice.test.js`
- 内容：去除"鉴权 only"约束，做真实写入测试

### P1-3：Supplier 模块增强
- 文件：扩展 `harness/tests/modules/basic-supplier.test.js`
- 内容：补 9 个缺失端点

## 执行顺序

1. P0-1 DeliveryNote 状态机（最小依赖）
2. P0-2 Batch freeze/unfreeze（独立模块）
3. P0-3 Warehouse activate/deactivate（扩展现有文件）
4. P0-4 audit rollback（扩展现有文件）
5. P0-5 并发底座（新建）
6. P1-1 台账对账（扩展链测）
7. P1-2 Invoice CRUD（新建）
8. P1-3 Supplier（扩展）
