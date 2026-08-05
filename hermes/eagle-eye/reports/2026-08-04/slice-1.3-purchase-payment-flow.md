# Slice 1.3 — purchase-payment-flow.chain 跑测报告

- **报告路径**：`hermes/eagle-eye/reports/2026-08-04/slice-1.3-purchase-payment-flow.md`
- **生成时间**：2026-08-04 (Asia/Shanghai)
- **测试文件**：`harness/tests/chains/purchase-payment-flow.test.js`
- **测试目标**：采购入库 → 应付生成 → 付款核销（跨业务/财务链路）
- **后端**：localhost:8080/jeecg-boot，✅ 存活（200 OK）
- **数据库**：MySQL:13306 ✅ Redis ✅
- **分支**：fix/regression-2026-08-04

---

## 切片信息

| 字段 | 值 |
|---|---|
| sliceId | 1.3 |
| name | purchase-payment-flow（采购→入库→付款 完整链路） |
| type | chain-integration（业务+财务跨域） |
| risk | **P0**（应付单 supplier_id 兜底缺失致入库审核失败） |
| effort | M |
| assertions | 22（19 通过 / 3 失败） |
| passRate | **86.4%** |
| duration | ~2.2s |

---

## 跑测结果

```
===== 业务链路测试: 采购→入库→付款 =====

--- 0. Setup ---
  ✅ 0.1 创建仓库
  ✅ 0.2 创建物料
  ✅ 0.3 创建供应商
  ✅ 0.4 创建并审核期初入库（100 个）
  ✅ 0.5 记录期初库存: qty=100

--- 1. 创建采购申请 ---          ✅
--- 2. 审核采购申请 ---          ✅ (申请状态=3 已审核)
--- 3. 加载申请明细 + 创建采购订单 --- ✅
--- 4. 审核采购订单 ---          ✅ (订单状态=3 已审核)
--- 5. 加载订单明细 + 创建采购入库 --- ✅
--- 6. 审核采购入库（库存增加）--- ❌ P0 BUG
--- 7. 数据完整性校验 ---         ❌ (7.1, 7.3 因 6.1 失败级联)
--- 8. 查询应付单 ---            ✅ (接口可达)
--- 9. 创建付款单 ---            ✅
--- 10. 付款后续校验 ---          ✅
--- 11. Cleanup ---             ✅ (清理测试数据: 全部完成)

===== 采购链路：19 通过, 3 失败 =====
===== 通过率：86.4% =====
```

---

## ❌ 失败明细（P0）

### 6.1 审核入库失败（核心）

```
PUT /mes/purchase/receipt/audit?id=2084350048681877505
{"success":false,"message":"\r\n### Error updating database.  Cause:
  java.sql.SQLException: Field 'supplier_id' doesn't have a default value\r\n
### The error may exist in org/jeecg/modules/mes/finance/payable/mapper/MesPayableMapper.java
```

### 7.1 / 7.3 库存数据级联失败

```
GET /mes/warehouse/inventory/list?...     → currentQty=100（期望 110）
GET /mes/warehouse/ledger/list?...        → inQty=100（期初 100，无本次入库 10）
```

> 因为 6.1 审核入库未提交（事务回滚），库存增加与应付生成一同未生效。

### ✅ 通过的关键链路点

| # | 断言 | 结果 | 说明 |
|---|------|------|------|
| 1.1 | 创建采购申请 | ✅ | 申请 id 生成 |
| 2.1 | 审核申请 | ✅ | msg="审核成功，已自动生成采购订单" |
| 2.2 | 申请状态=已审核(3) | ✅ | status=3 |
| 3.2 | 创建采购订单 | ✅ | 订单 id 生成 |
| 4.2 | 订单状态=已审核(3) | ✅ | status=3 |
| 5.2 | 创建采购入库 | ✅ | 入库单 id 生成（**但 supplierId 字段未传**） |
| 8.1 | 应付单查询接口可达 | ✅ | total=37（接口层 OK，业务未生成） |
| 9.1 | 创建付款单 | ✅ | id=…，amount=120 |
| 10.1 | 付款单存在 | ✅ | code=PAY-… |
| 11.1 | 清理测试数据 | ✅ | 全部完成 |

---

## 🔍 根因分析

### 代码定位

**`MesPurchaseReceiptServiceImpl.audit()`（行 ~230）**

```java
// 应付（税额取订单行税率，不再硬编码）
MesPayable ap = new MesPayable();
ap.setCode("AP-" + e.getCode());
ap.setSupplierId(e.getSupplierId());   // ← ⚠️ e.getSupplierId() 为 null
ap.setSourceType("采购入库");
ap.setSourceBillId(e.getId());
ap.setSourceBillNo(e.getCode());
ap.setAmount(totalAmount);
// …
try { payableService.save(ap); } catch (DuplicateKeyException ex) { /* 已生成 */ }
```

### 数据库约束

```sql
-- db/V9.0.0__mes_finance_init.sql
CREATE TABLE IF NOT EXISTS c_mes_payable (
    …
    supplier_id  VARCHAR(32) NOT NULL COMMENT '供应商ID',  -- ⚠️ NOT NULL
    …
);
```

### 字段流转

| 实体 | supplierId 字段 | 来源 | 当前值 |
|------|----------------|------|--------|
| `c_mes_purchase_order`（采购订单） | ✅ `supplier_id` | 测试 line 126 传入 `supplierId: supplier.id` | 已正确写入 |
| `c_mes_purchase_receipt`（入库单） | ✅ `supplier_id` | **测试 line 172 入库 body 未传 supplierId** | **NULL** |
| `c_mes_payable`（应付单） | ✅ `supplier_id` NOT NULL | `audit()` line 233：`e.getSupplierId()` | **NULL → 触发 SQL 异常** |

### 根因

`MesPurchaseReceiptServiceImpl.audit()` 在生成应付单前，**未对入库单 supplierId 做兜底回填**——当前端/调用方未显式传 supplierId 时（测试场景、采购订单转单场景等），入库单 supplierId 为 NULL，导致应付单 INSERT 违反 NOT NULL 约束，事务回滚，**连带库存增加/批次/订单状态推进全部失败**。

---

## 🛠 修复方案

### 方案 A（推荐）：audit() 内从采购订单反查兜底

修改 `MesPurchaseReceiptServiceImpl.audit()`：

```java
// P0修复-入库审核 supplierId 兜底：从关联采购订单回填
if (!StringUtils.hasText(e.getSupplierId()) && e.getPurchaseOrderId() != null) {
    MesPurchaseOrder order = purchaseOrderMapper.selectById(e.getPurchaseOrderId());
    if (order != null && StringUtils.hasText(order.getSupplierId())) {
        e.setSupplierId(order.getSupplierId());
        // 持久化到入库单（防止后续反审核/查询再次为 null）
        baseMapper.updateById(e);
    }
}
// 仍为空则兜底失败，给出明确错误
if (!StringUtils.hasText(e.getSupplierId())) {
    throw new JeecgBootException("入库单供应商ID为空且无法从采购订单反查，请检查数据");
}
```

### 方案 B：saveWithItems() 入口补齐

在 `saveWithItems()` 里增加同样的兜底逻辑——入库单保存时即从采购订单回填 supplierId（持久化在 DB 层）。**A 更稳健**：覆盖历史脏数据；**B 更早拦截**：保存即校验。

**建议两者结合**：B 兜底 + A 二次保险。

### 测试侧建议（可选）

测试 line 172 入库 body 增加 `supplierId: supplier.id`，与采购订单一致；不应依赖后端兜底。但**生产修复不能依赖测试侧传对**——必须后端兜底。

---

## 📋 影响面

| 模块 | 影响 | 严重性 |
|------|------|--------|
| 采购入库审核 | ❌ 入库审核完全失败（500） | **P0** |
| 库存增加 | ❌ 同步失败 | **P0** |
| 库存台账 | ❌ 无本次入库记录 | **P0** |
| 批次库存 | ❌ 同步失败 | **P0** |
| 采购订单状态推进 | ❌ part/fullyReceived 未更新 | **P1** |
| 应付单生成 | ❌ 业财联动断 | **P0**（财务核销链路阻塞） |
| 付款核销 | ⚠️ 测试 9/10 通过但无对应应付单核销（**测试场景未真正验证核销**） | **P1**（测试覆盖缺失） |

### ⚠️ 测试覆盖盲区

通过不代表"付款单真的核销了某张应付单"——测试只断言了：
- 8.1 应付单接口可达（total=37）
- 9.1 创建付款单成功
- 10.1 付款单存在

**未断言**：付款单的 `sourceBillId` 是否等于本次入库单 id、应付单 `paidAmount`/`unsettledAmount` 是否联动更新。建议下个迭代增强 10.x 断言：
- 10.2 应付单存在且 sourceBillId = receiptId
- 10.3 应付单 paidAmount/unsettledAmount 等于付款金额
- 10.4 付款单 sourceBillId = payableId（或 payable.code 反查）

---

## ✅ Slice 1.3 结论

| 维度 | 评估 |
|------|------|
| 切片通过 | ❌ **FAIL** — 3 项断言失败（86.4%） |
| 阻塞类型 | **P0 bug**（应付单 supplier_id 兜底缺失） |
| 阻塞根因 | `MesPurchaseReceiptServiceImpl.audit()` 未做 supplierId 兜底 |
| 修复路径 | 方案 A+B（后端兜底，建议 2 行 SQL 改动） |
| 修复预估 | ≤30 行 Java，1 SQL 字段无变更，0 数据迁移 |
| 阻断其他切片 | 财务核销链路（P1.4+）、库存准确性（P0） |
| 测试侧增强 | 9.x/10.x 断言需补强（验证核销联动） |

**下一步建议**：
1. **立即修复** audit() supplierId 兜底（方案 A）
2. saveWithItems() 入口同步兜底（方案 B）
3. 修复后重跑 slice-1.3，期望 22/22 全绿
4. 增强测试 10.x 断言（核销联动真验证）
5. 复跑 slice-1.1 / slice-1.2 确认无回归

---

## 🗂 关联

- **前序切片**：[slice-1.1-purchase-apply-order.md](./slice-1.1-purchase-apply-order.md)（发现 P1 日期精度）、[slice-1.2-purchase-order-receipt.md](./slice-1.2-purchase-order-receipt.md)（16/16 全绿）
- **下一切片建议**：slice-1.4 sales-payment-flow（销售→出库→收款，跨财务对偶链路）
- **代码位置**：
  - `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/purchase/receipt/service/impl/MesPurchaseReceiptServiceImpl.java`（行 233 修复点）
  - `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/finance/payable/entity/MesPayable.java`
  - `jeecg-boot/jeecg-boot-module/project-mes/db/V9.0.0__mes_finance_init.sql`（表结构）