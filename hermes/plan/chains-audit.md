# chains/ 目录审计报告（阶段 0）

审计日期：2026-08-06｜目的：确认 v3 缺口清单的准确性

## chains/ 9 个文件覆盖状态机端点

| 文件 | 覆盖的 audit/unaudit 端点 |
|---|---|
| purchase-apply-order.chain.test.js | PurchaseApply/audit, PurchaseOrder/audit, **PurchaseOrder/unaudit** |
| purchase-order-receipt.chain.test.js | PurchaseOrder/audit, PurchaseReceipt/audit（2次） |
| purchase-payment-flow.test.js | PurchaseApply/audit, PurchaseOrder/audit, PurchaseReceipt/audit |
| sales-receipt-flow.test.js | SalesOrder/audit, SalesOutbound/audit |
| warehouse-chain.test.js | OtherStockIn/audit, OtherStockOut/audit |
| batch-chain.test.js | （无 PUT audit 端点） |
| finance-chain.test.js | （无 PUT audit 端点） |
| manufacturing-chain.test.js | （无 PUT audit 端点） |

## 关键纠正

### 1. PurchaseOrder/unaudit — 已在 chains 覆盖
`purchase-apply-order.chain.test.js:100` 有完整状态验证：
```javascript
// Step 7: 订单反审核
r = await c.api('PUT', '/mes/purchase/order/unaudit?id=' + orderId);
c.check('反审核订单', r.code === 200, r.message);
r = await c.api('GET', '/mes/purchase/order/queryById?id=' + orderId);
c.check('反审核后订单状态=草稿(1)', r.result?.status === '1');
```
→ **非缺口，从 v3 缺口表移除**

### 2. PurchaseReceipt/unaudit — 仅在 cleanup，非真实测试
`purchase-payment-flow.test.js:289`：
```javascript
if (receiptId) {
  try { await c.api('PUT', `/mes/purchase/receipt/unaudit?id=${receiptId}`); } catch (e) {}
  await safeDeleteDoc(c, '/mes/purchase/receipt', receiptId);
}
```
→ **cleanup try/catch，不算测试覆盖，仍为真实缺口**

### 3. PurchaseApply/unaudit — 仅在 cleanup
`purchase-payment-flow.test.js:299` 同上，仅 cleanup，非真实测试。

## 最终缺口清单（阶段 0 审计后校正）

| Controller | 端点 | 状态 | 文件 |
|---|---|---|---|
| PurchaseApply | /reject | 🔴 真实缺口 | purchase.test.js 新增 |
| PurchaseReceipt | /unaudit | 🔴 真实缺口（仅cleanup） | purchase.test.js 新增 |
| ProductionPicking | /audit（2端点） | 🔴 真实缺口 | manufacturing.test.js 新增 |
| CompletionReceipt | /audit（2端点） | 🔴 真实缺口 | manufacturing.test.js 新增 |
| Voucher | /audit（2端点） | 🔴 真实缺口 | 新建 finance-voucher.test.js |
| Location | /delete | 🔴 真实缺口 | basic.test.js 新增 |
| Location | /deleteBatch | 🔴 真实缺口 | basic.test.js 新增 |
| Location | /exportXls | 🔴 真实缺口 | basic.test.js 新增 |
| Location | /importExcel | 🔴 真实缺口 | basic.test.js 新增 |
| Location | /selectPage | 🔴 真实缺口 | basic.test.js 新增 |

**总计：10 个端点（比 v3 少 3 个，PurchaseOrder/unaudit 已覆盖）**

## 阶段 0 结论

✅ 9 个 chains/ 文件已审计
✅ 缺口表已校正（移除 PurchaseOrder/unaudit）
✅ basic.test.js Location 覆盖范围确认（4/9，缺 5）
✅ 前置条件：无阻塞manufacturing/finance 的问题
