# orca-review v2: 采购入库明细自动加载 — 独立复评审

**评审日期:** 2026-07-22
**评审人:** Claude Code (orca-review worker, 独立派发)
**评审对象:** autoload 方案 + 初版评审 `2026-07-22-orca-review-receipt-autoload.md`
**评审方法:** 逐文件代码级验证 + 初版评审逐条复验

---

## 一、复验方法

对方案涉及的 5 个文件逐一做了代码级验证：

| # | 文件 | 状态 | 验证方式 |
|---|------|:--:|------|
| 1 | `MesPurchaseOrderItemForReceipt.java` | ✅ 已存在 | Read 全文，确认 DTO 字段齐全（itemId/remainQty/taxRate） |
| 2 | `MesPurchaseReceiptServiceImpl.java` | ✅ 已存在 | Read 全文 293 行，验证 audit()/validateReceipt()/saveItems() |
| 3 | `MesPurchaseReceiptController.java` | ✅ 已存在 | Read 全文，确认现有 API 结构 |
| 4 | `receipt.api.ts` | ❌ 不存在 | 全局搜索无匹配 |
| 5 | `ReceiptDrawer.vue` | ❌ 不存在 | 全局搜索无匹配 |
| + | `MesPurchaseReceiptItem.java` | ✅ 已存在 | 确认字段列表（无 orderItemId） |
| + | `MesPurchaseOrderItem.java` | ✅ 已存在 | 确认 receivedQty+taxRate 字段已存在 |
| + | `MesPurchaseOrderItemMapper.java` | ✅ 已存在 | 确认 atomicReceive SQL 签名为 materialId 级别 |
| + | `MesPurchaseReceipt.java` | ✅ 已存在 | 确认主表结构（supplierId/warehouseId 独立字段） |

---

## 二、初版评审逐条复验

### Gap 1: orderItemId 缺失 → 🔴 确认，且严重度应升级为 P0

**代码证据:**

`MesPurchaseReceiptItem.java` (49行) — 无 `orderItemId` 字段：
```java
private String receiptId;
private Integer lineNo;
private String materialId;    // ← 只有物料ID，无订单行ID
private BigDecimal orderQuantity;
private BigDecimal receiptQuantity;
```

`audit()` 方法注释 (ServiceImpl L.139-140) 承认此限制：
```java
// 从采购订单行取单价（同物料多行取第一行——后续 order_item_id 关联后再优化）
```

**初版评审未发现的额外风险：`atomicReceive` 的 SQL 签名同样是 materialId 级别**：

`MesPurchaseOrderItemMapper.java` L.11-12:
```sql
UPDATE c_mes_purchase_order_item SET received_qty = received_qty + #{qty}
WHERE order_id = #{orderId} AND material_id = #{materialId}
  AND received_qty + #{qty} <= quantity
```

**严重问题：** 如果同物料在同一订单中有两行（如批次不同、价格不同），`atomicReceive` 的 `WHERE material_id = #{materialId}` 会匹配**全部行**，导致：
- 两行的 `received_qty` 同时 +qty（静默写错）
- 订单行 A (qty=100, received=30) + 订单行 B (qty=50, received=30) = 两行都显示 30 已收（实际只有 30 入库）
- 后续入库时校验 `received_qty + #{qty} <= quantity` 会在错误的数据基础上计算

**结论：** Gap 1 不是"追溯性问题"，而是"数据完整性缺陷"。**严重度从 🟡 中 升级为 🔴 高（P0）**。autoload 方案如不修复此问题，会在同物料多行场景下产生静默数据错误。

另外，`validateReceipt()` L.208-209 也有同样问题：
```java
Map<String, BigDecimal> orderQtyMap = orderItems.stream()
    .collect(Collectors.toMap(MesPurchaseOrderItem::getMaterialId,
        MesPurchaseOrderItem::getQuantity, (a, b) -> a));
// merge函数 (a,b)->a 意味着同物料多行时只保留第一行的quantity
```

### Gap 2: 供应商联动 → 🟡 确认

`MesPurchaseReceipt.java` 有独立的 `supplierId` 字段 (L.40)，与 `purchaseOrderId` 解耦。
自动加载方案需在订单选择 change 事件中同步填充，初版评审描述准确。

### Gap 3: 订单变更清理 → 🟡 确认

逻辑正确。补充一点：不仅需要清空 items，还需要清空可能被 Gap 2 联动填充的 supplierId 和 warehouseId。

### Gap 4: 物料只读 → 🟡 确认

无前端代码可验证，但从业务逻辑判断正确——自动加载的明细物料来自订单，不应允许修改。

### Gap 5: remainQty 展示 → 🟡 确认

DTO 已计算 `remainQty`（`MesPurchaseOrderItemForReceipt` L.39），合理性确认。

### Gap 6: 过滤 remainQty≤0 → 🟢 确认

建议合理，减少前端无效选项。`atomicReceive` 是最终防线。

### 设计建议 1 (勾选入库) 和 2 (taxRate 落库) → 确认合理

建议 2 特别值得采纳——如果本次修复了 Gap 1（加 orderItemId），则税率可从 orderItemId 精确查找，不需要冗余落库。

---

## 三、初版评审未发现的额外问题

### 新发现 1: `atomicReceive` 的 WHERE 条件应包含 `order_item_id` 🔴

见上文 Gap 1 详述。`atomicReceive` 方法签名需要从：
```java
int atomicReceive(orderId, materialId, qty)
```
改为：
```java
int atomicReceive(orderId, orderItemId, materialId, qty)
```

SQL 的 WHERE 子句需增加 `AND id = #{orderItemId}`。

### 新发现 2: autoload 方案应包含 `validateReceipt` 的同步修复 🟡

`validateReceipt()` 中的 `orderQtyMap` 构建使用 `materialId` 作为 key，同物料多行时 `(a,b)->a` 会丢失第二行的 quantity 信息。这会导致校验时使用错误的采购数量上限。修复方案：改用 `Map<String, BigDecimal>` 按 materialId 汇总 quantity（sum 而非 first-wins），或改用 orderItemId 级别匹配。

### 新发现 3: 前端文件不存在 — 需要确认路由注册 🟢

采购入库的前端文件（`ReceiptDrawer.vue`, `receipt.api.ts`）目前不存在于 `jeecgboot-vue3/src/views/` 目录下。需要确认：
- 这些文件是否需要从零创建
- 路由是否已在 `mes.ts` 注册
- 菜单是否已在 `MesMenuRegistry` 注册

---

## 四、端到端流程走查（补充初版评审）

补充初版评审未覆盖的异常路径：

| 路径 | 场景 | 当前防护 | 建议 |
|------|------|:--:|------|
| 异常1 | API 被绕过直接 POST 入库行（不经过 autoload） | `validateReceipt` 校验订单外物料 | ✅ 已有 |
| 异常2 | 加载明细后、保存前，采购订单被取消 | `validateReceipt` 再次查订单状态 | ✅ 已有 |
| 异常3 | 加载明细后、审核前，同一物料被其他人全部入库 | `atomicReceive` 返回 0 | ✅ 已有 |
| 异常4 | 加载时 remainQty=50，填写 50，审核时另一个人已入库 30 | `atomicReceive` WHERE received+50≤quantity 判定失败 | ✅ 已有 |
| 异常5 | 同物料两行，用户只入库第一行，但 `atomicReceive` 同时扣了两行 | ❌ 无防护 | 🔴 需修复 |

---

## 五、修订后的优先级排序

| 优先级 | 事项 | 初版评级 | 修订评级 | 变更原因 |
|:--:|------|:--:|:--:|------|
| **P0** | Gap 1: orderItemId 关联 + atomicReceive 改签名 | P0 | **P0** | 不变，且发现更深层 SQL 缺陷 |
| **P1** | Gap 2: 供应商联动 | P1 | P1 | 不变 |
| **P1** | Gap 3: 订单变更清理 | P1 | P1 | 不变 |
| **P1** | Gap 4: 物料只读 | P1 | P1 | 不变 |
| **P1** | 新发现 1: atomicReceive SQL 修复 | — | **P1** | 新增，与 Gap1 一体修复 |
| **P2** | Gap 5: remainQty 展示 | P2 | P2 | 不变 |
| **P2** | Gap 6: 过滤 remainQty≤0 | P2 | P2 | 不变 |
| **P2** | 新发现 2: validateReceipt quantity 汇总 | — | **P2** | 新增 |
| **P3** | 建议 1: 勾选入库 | P3 | P3 | 不变 |
| **P3** | 建议 2: taxRate 落库 | P3 | P3 | 不变 |
| **P3** | 新发现 3: 前端文件+路由确认 | — | **P3** | 新增 |

---

## 六、最终判定

**🔶 ADJUST — 与初版评审结论一致，但 Gap 1 的严重度上调。**

初版评审的 6 个 Gap 全部确认有效。额外发现：
1. `atomicReceive` 在同物料多行场景下存在静默数据错误（与 Gap 1 同源，但更严重）— 修复 Gap 1 时一并解决
2. `validateReceipt` 的 `orderQtyMap` 在 merge 冲突时取 first-wins 可能丢失 quantity
3. 前端文件需确认是否从零创建

**核心风险：** 如果不修复 Gap 1（orderItemId），autoload 方案会在同物料多行场景下产生错误的 received_qty 数据，且前端展示的 remainQty 也无法精确到行级别。

**建议：** P0+P1 项（Gap 1-4 + 新发现 1）必须在编码前完成设计对齐。P2-P3 可在实施中逐步添加。

---

## 七、与初版评审的差异总结

| 维度 | 初版评审 | 本复评审 |
|------|------|------|
| Gap 验证 | 逻辑推演 | 代码级验证（逐文件 Read） |
| Gap 1 严重度 | P0（数据完整性） | **维持 P0 + 发现 atomicReceive SQL 同源缺陷** |
| 新发现 | — | 3 个（atomicReceive 签名/validateReceipt merge/前端存在性） |
| 总体判定 | ADJUST | **ADJUST**（一致） |
