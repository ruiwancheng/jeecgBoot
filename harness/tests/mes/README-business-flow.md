# MES 业务链路测试模板（gen-tests v2）

**日期**：2026-08-04
**关联**：`.claude/plans/2026-08-04-mes-regression-plan.md` + `mes-business-flow-test-report.md`

---

## 一、为什么需要业务链路测试

回归测试只跑单接口（list/add/edit/delete）暴露不了真实业务 bug。本次发现 2 个 P1：
- 采购入库审核触发 `supplier_id doesn't have default value`（入库单表没存 supplier_id，但应付单需要）
- Customer 列表查询报 `Unknown column 'grade'`（实体加了字段但 DB schema 没同步）

单接口 200 看起来正常，但**审核 + 跨表 = 真业务触发点**，必须跑完整链路。

## 二、模板设计原则

### 2.1 测试结构（5 段式）

```
0. Setup    — 准备基础数据（仓库 + 物料 + 供应商/客户 + 期初库存）
1. 触发单据 — 创建第一个单据（申请/订单/出库）
2. 状态推进 — 审核/下达/关闭
3. 下游单据 — 创建第二个单据（订单/入库/出库）
4. 跨表校验 — 库存 vs 台账 vs 应付/应收 vs 付款/收款
5. Cleanup  — 反审核 + 删除所有测试数据（顺序：叶子 → 根）
```

### 2.2 SUFFIX 设计（避免数据冲突）

```javascript
// ❌ 错误：可能被并发覆盖
const SUFFIX = String(Date.now()).slice(-8);  // 9.9E+7 范围，可能冲突

// ✅ 正确：毫秒×1000 + 随机数，12 位唯一
const TS = Date.now() * 1000 + Math.floor(Math.random() * 1000);
const SUFFIX = String(TS).slice(-12);
```

**所有创建的单据 code 必须包含 SUFFIX**，便于：
- 跑测试时容易识别（避免数据冲突）
- cleanup 时按 code 模式删
- 跨表查询时按 code 过滤（如 `payable.list?code=...`）

### 2.3 setup 复用 helpers/fixtures.js

```javascript
const {
  createWarehouse, createMaterial, createSupplier, createCustomer,
  createAndAuditStockIn, safeDeleteDoc, cleanupWarehouseScope,
} = require('../helpers/fixtures');

// 复用 fixture 函数（自带 cleanup 兜底）
const warehouse = await createWarehouse(c, SUFFIX, '测试仓库');
const material = await createMaterial(c, SUFFIX, '测试物料');
const stockIn = await createAndAuditStockIn(c, {
  whId: warehouse.id, matId: material.id, qty: 100, unitCost: 10, suffix: SUFFIX,
});
```

### 2.4 跨表校验（关键）

```javascript
// 库存校验：实时查
const r = await c.api('GET', `/mes/warehouse/inventory/list?warehouseId=${whId}&materialId=${matId}&pageSize=1`);
const currentQty = parseFloat(r.result?.records[0]?.current_qty ?? 0);

// 库存台账校验
const ledger = await c.api('GET', `/mes/warehouse/ledger/list?warehouseId=${whId}&materialId=${matId}&pageSize=50`);
const totalIn = ledger.result.records.reduce((sum, r) => sum + parseFloat(r.inQty || 0), 0);

// 应付单校验（注意：按 code 过滤避免取到历史数据）
const payable = await c.api('GET', `/mes/finance/payable/list?pageSize=200`);
const matched = payable.result.records.filter(p => p.code?.includes(SUFFIX));
```

### 2.5 Cleanup 顺序（重要）

```javascript
// 顺序：叶子 → 根（反审核 → 删除 → DB 清理）
if (paymentId) await safeDeleteDoc(c, '/mes/finance/payment', paymentId);
if (receiptId) {
  try { await c.api('PUT', `/mes/purchase/receipt/unaudit?id=${receiptId}`); } catch (e) {}
  await safeDeleteDoc(c, '/mes/purchase/receipt', receiptId);
}
if (orderId) {
  try { await c.api('PUT', `/mes/purchase/order/unaudit?id=${orderId}`); } catch (e) {}
  await safeDeleteDoc(c, '/mes/purchase/order', orderId);
}
if (applyId) {
  try { await c.api('PUT', `/mes/purchase/apply/unaudit?id=${applyId}`); } catch (e) {}
  await safeDeleteDoc(c, '/mes/purchase/apply', applyId);
}
if (stockIn) await safeDeleteDoc(c, '/mes/stock/otherIn', stockIn.id);
cleanupWarehouseScope(warehouse.id, material.id);  // DB 级清理
await safeDeleteDoc(c, '/mes/basic/supplier', supplier.id);
```

---

## 三、字段名陷阱（必须先查实体）

| 单据 | items 数量字段 | 关联字段 |
|---|---|---|
| 采购申请 | `quantity` | — |
| 采购订单 | `quantity` | `purchaseApplyId` |
| 采购入库 | **`receiptQuantity`** + `orderQuantity` | `purchaseOrderId` |
| 销售订单 | `quantity` | — |
| 销售出库 | **`deliveryQty`** + `actualQty` | `salesOrderId` |
| 销售订单 | — | **无 warehouseId 字段** |

**绝不能猜字段名！** 必须先 `grep -E "private.*[a-zA-Z]+;" .../entity/MesXxx.java` 列出实体字段。

## 四、模板代码（可直接复用）

### 模板 A: 采购 → 入库 → 付款
参考：`purchase-payment-flow.test.js`（已生成）

### 模板 B: 销售 → 出库 → 收款
参考：`sales-receipt-flow.test.js`（已生成）

### 模板 C（建议下次实现）: 生产 → 入库 → 领料
- createProductionOrder → audit → createProductionReceipt (入库半成品) → createMaterialIssue (领料) → 校验成品库存

### 模板 D（建议下次实现）: 库存预警触发链路
- 制造一个低库存场景 → 验证 inventory_alert 自动创建 → 验证补货流程

### 模板 E（建议下次实现）: 批次全生命周期
- 采购入库带批次 → 销售出库带批次 → 批次追溯 API 查到 → 库存按批次减少

---

## 五、使用建议

### 5.1 何时跑
- **每次 PR 合并前**（至少跑采购 + 销售链路）
- **每月一次全量回归**（跑全部链路 + 单接口）
- **重大重构后**（必须跑全量）

### 5.2 跑失败的快速定位
1. 看 setup 阶段：基础数据创建成功？
2. 看触发单据：第一步 add 成功？
3. 看状态推进：audit 返回什么错？
4. 看跨表校验：业务字段是否对账？

### 5.3 失败分级（参考 plan §5）
- **P0**：创建基础数据失败（仓库/物料/供应商）
- **P1**：audit 报 SQL 异常（最严重，多是 schema 不一致）
- **P1**：跨表对账失败（业务字段缺失）
- **P2**：测试代码断言错（实体字段名猜错）
- **P3**：数据准备/cleanup 失败

---

## 六、待办（明早建议）

1. **🔴 修 P1-1**：采购入库单 add 时补 supplier_id（从关联 order 拉）
2. **🔴 修 P1-2**：补 c_mes_customer 表的 6 列迁移脚本
3. **🟡 验证修复**：修完后跑 `node harness/tests/mes/purchase-payment-flow.test.js` + `node harness/tests/mes/sales-receipt-flow.test.js` 验证
4. **🟢 后续**：实现模板 C/D/E（生产、库存预警、批次）