# orca-review v3: 采购入库明细自动加载 — 独立评审（二次派发）

**评审日期:** 2026-07-22
**评审人:** Claude Code (orca-review worker, 独立二次派发)
**评审对象:** 采购入库明细自动加载方案（5 文件跨前后端）
**评审方法:** 逐文件代码级验证 + 初版/v2 评审交叉复验

---

## 一、逐文件代码级验证

对方案涉及的 5 个文件 + 关联文件逐一做了代码级 Read：

| # | 文件 | 状态 | 关键发现 |
|---|------|:--:|------|
| 1 | `MesPurchaseOrderItemForReceipt.java` | ✅ 已存在 | DTO 字段齐全，含 itemId/remainQty/taxRate。但 materialCode/materialName **声明未填充** |
| 2 | `MesPurchaseReceiptServiceImpl.java` | ✅ 已存在 | `loadOrderItemsForReceipt` 方法已实现（L286-307），接口已声明 |
| 3 | `MesPurchaseReceiptController.java` | ✅ 已存在 | `GET /loadOrderItemsForReceipt` 端点已注册（L98-105） |
| 4 | `receipt.api.ts` | ✅ **已存在**（v2 误报为不存在） | `loadOrderItemsForReceipt(orderId)` 已定义（L27-30） |
| 5 | `ReceiptDrawer.vue` | ✅ **已存在**（v2 误报为不存在） | 抽屉完整，但缺少 autoload 接线（无 change handler） |
| + | `MesPurchaseReceiptItem.java` | ✅ 已存在 | **无 orderItemId 字段** — DTO 有 itemId 但入库行无法追溯订单行 |
| + | `MesPurchaseOrderItemMapper.java` | ✅ 已存在 | `atomicReceive` 用 materialId 做 WHERE — 同物料多行场景有 bug |
| + | `JPurchaseOrderSelect.vue` | ✅ 已验证 | emit change 含 `{ value, label, record }`，record 来自 selectPurchaseOrderPage |
| + | `PurchaseOrderSelectModal.vue` | ✅ 已验证 | record 从表格行数据来，含 supplierId_dictText 等，需验证含 supplierId 原始值 |

---

## 二、与 v2 评审的关键差异

### v2 评审错误：前端文件"不存在"

v2 评审声称 `receipt.api.ts` 和 `ReceiptDrawer.vue` "❌ 不存在，全局搜索无匹配"。

**实际情况：两个文件均存在且完整：**
- `jeecgboot-vue3/src/views/project/mes/purchase/receipt/receipt.api.ts` — 35 行，含 `loadOrderItemsForReceipt` 函数
- `jeecgboot-vue3/src/views/project/mes/purchase/receipt/ReceiptDrawer.vue` — 109 行，完整的抽屉组件

v2 的"新发现 3"（前端文件+路由确认）基于错误的文件搜索，**对应的 P3 项应从 v2 报告中撤销**。

---

## 三、独立发现的问题（逐项代码证据）

### 🔴 P0-1: orderItemId 未落库 + atomicReceive 同物料多行 bug

**与 v2 Gap 1 一致，但补充额外代码证据。**

`MesPurchaseReceiptItem.java` (49行) — 无 `orderItemId` 字段：
```java
private String receiptId;
private Integer lineNo;
private String materialId;    // ← 只有物料ID，无订单行ID
private BigDecimal orderQuantity;
private BigDecimal receiptQuantity;
```

DTO 已携带 `itemId`（`MesPurchaseOrderItemForReceipt.itemId`），但 `saveItems()` （ServiceImpl L272-283）不读取它：
```java
private void saveItems(MesPurchaseReceipt entity) {
    // 只 set receiptId/lineNo/createBy/createTime/updateBy/updateTime
    // 没有 setOrderItemId —— itemId 在传输中丢失
    itemMapper.insert(item);
}
```

`atomicReceive` SQL（Mapper L11-12）— **同物料多行的致命缺陷：**
```sql
UPDATE c_mes_purchase_order_item SET received_qty = received_qty + #{qty}
WHERE order_id = #{orderId} AND material_id = #{materialId}
  AND received_qty + #{qty} <= quantity
```

**攻击场景：**
```
订单行A: material=M001, qty=100, received=0
订单行B: material=M001, qty=50,  received=0
→ 入库行A 30个 → atomicReceive(orderId, M001, 30)
→ 订单行A received=30 ✓  AND 订单行B received=30 ✗ (静默错误!)
```

**严重度：🔴 P0** — 数据静默损坏，不可恢复。

### 🟡 P1-1: ReceiptDrawer.vue 缺少 autoload 接线

**当前状态（ReceiptDrawer.vue L5）：**
```html
<JPurchaseOrderSelect v-model:modelValue="model[field]" status="3" />
```
无 `@change` 监听。组件确实 emit change（JPurchaseOrderSelect.vue L60），但抽屉未消费。

**缺失的逻辑：**
1. 选择订单后不调 `loadOrderItemsForReceipt` API
2. 不联动填充 supplierId / warehouseId
3. 切换订单时不清理旧 items
4. 物料列不设只读
5. 不展示 remainQty

### 🟡 P1-2: validateReceipt 的 orderQtyMap merge 逻辑

**ServiceImpl L208-209：**
```java
Map<String, BigDecimal> orderQtyMap = orderItems.stream()
    .collect(Collectors.toMap(MesPurchaseOrderItem::getMaterialId,
        MesPurchaseOrderItem::getQuantity, (a, b) -> a));
// merge函数 (a,b)->a → 同物料多行只保留第一行的quantity
```

如果订单行A (M001, qty=100) + 订单行B (M001, qty=50)，`orderQtyMap[M001] = 100`（丢失50），校验上限偏低。修复：改用 `BigDecimal::add` 汇总同物料数量，或改为 orderItemId 级别匹配。

### 🟡 P1-3: DTO 的 materialCode/materialName 声明未填充

DTO 声明了 `materialCode` 和 `materialName` 字段（L27-31），但 `loadOrderItemsForReceipt`（L288-306）只 set 了 itemId/materialId/orderQty/receivedQty/remainQty/unitPrice/taxRate。

如果前端需要显示物料名称（只读模式），需要：
- 方案A：Service 中 join 物料表填充 code/name
- 方案B：前端通过 materialId 异步查名称（不推荐，N+1 问题）

当前只显示 materialId（裸 UUID），UX 不可接受。

### 🟢 P2-1: loadOrderItemsForReceipt 不过滤 remainQty≤0

Service L288-306 返回全部订单行，包括已全部入库的（remainQty=0）。建议加过滤：
```java
if (dto.getRemainQty().compareTo(BigDecimal.ZERO) <= 0) continue;
```

### 🟢 P2-2: loadOrderItemsForReceipt 无采购订单状态校验

当前方法不校验订单状态（是否允许入库）。`validateReceipt` 会在保存时校验（L202-203），但如果 API 被独立调用（非保存流程），可能返回不应入库的订单行。建议加状态守卫。

### 🟢 P3-1: selectPurchaseOrderPage 返回的 record 是否含 supplierId

`PurchaseOrderSelectModal` 的数据来自 `selectPurchaseOrderPage`（分页查询）。Table columns 只显示了 `supplierId_dictText`（L91），但 record 对象来自后端 entity 序列化，应包含 `supplierId` 原始值。需在 autoload 实施时验证——如果 record 不含原始 supplierId，联动填充无法实现。

---

## 四、端到端流程走查（修订版）

以"用户新建入库单→选采购订单→自动加载明细→填数量→保存→审核"为例：

```
1. 用户点击"新增" → Drawer 打开 → getNextCode 获取编码 ✓ (已实现)
2. 用户选择采购订单 → JPurchaseOrderSelect change 事件触发
   2a. ❌ 缺少 change handler → 什么都不发生
   2b. 需实现: 调 loadOrderItemsForReceipt API → 获取明细
   2c. 需实现: setFieldsValue({ supplierId: record.supplierId })
   2d. 需实现: 清空旧 items → 填充新 items
   2e. 需实现: 物料列只读（materialCode/materialName 显示）
   2f. 需实现: remainQty 展示 + receiptQuantity ≤ remainQty 校验
3. 用户填写 receiptQuantity + 质检结果 → 提交
   3a. saveItems() → itemId 未落库 ⚠️ P0-1
   3b. validateReceipt() → orderQtyMap merge 取 first ⚠️ P1-2
4. 审核 → atomicReceive → 同物料多行 bug ⚠️ P0-1
   4a. audit() 取单价 → get(0) 同物料多行取第一行 ⚠️ P0-1
```

---

## 五、优先级排序

| 优先级 | 事项 | 类别 | 首次评审状态 |
|:--:|------|------|:--:|
| **P0** | orderItemId: Entity加字段 + DDL + saveItems落库 + atomicReceive改SQL签名 + audit取价精确匹配 | 数据完整性 | v1 Gap1 / v2 确认 |
| **P1** | ReceiptDrawer: 加 change handler 实现 autoload（调API+填表+清旧行+联动supplier） | 功能缺失 | 新发现 |
| **P1** | validateReceipt: orderQtyMap merge 改为 sum 或 orderItemId 匹配 | 校验准确 | v2 新发现2 |
| **P1** | materialCode/materialName 填充（Service 或前端 N+1） | UX | 新发现 |
| **P2** | remainQty 列展示 + 前端数量校验 | UX | v1 Gap5 / v2 确认 |
| **P2** | loadOrderItemsForReceipt 过滤 remainQty≤0 | 后端优化 | v1 Gap6 / v2 确认 |
| **P2** | loadOrderItemsForReceipt 加订单状态校验 | 防御性 | 新发现 |
| **P3** | 物料列只读（自动加载模式下） | UX | v1 Gap4 / v2 确认 |
| **P3** | 验证 record.supplierId 可用性 | 依赖确认 | 新发现 |

---

## 六、最终判定

**🔶 ADJUST — 与 v1/v2 评审结论一致。**

方案骨架已就位——后端 API、DTO、前端 API 函数均已实现。但核心接线未完成：

1. **P0**: orderItemId 缺失导致同物料多行场景下 received_qty 静默错误，且 atomicReceive SQL 签名必须一同修改（`+AND id=#{orderItemId}`）
2. **P1**: ReceiptDrawer.vue 缺少 change handler 是整个 autoload 功能的**最后一步接线**——API 调用、表单联动、旧行清理、物料只读、数量展示全部依赖这个 handler
3. **v2 评审的"前端文件不存在"结论需要撤销**——两个文件均存在

**实施建议：**
- P0（orderItemId + atomicReceive）是最大风险项，涉及 DDL 变更 + Mapper SQL 修改 + audit 逻辑调整，必须先做
- P1 的 ReceiptDrawer 接线是 autoload 的核心交互实现，改动集中在 Vue 组件内，风险可控
- 编码前先确认：`selectPurchaseOrderPage` 返回的 record 是否含 `supplierId` 原始值（非仅 dictText）

---

## 七、三版评审差异总览

| 维度 | v1 初版 | v2 复评审 | v3 本评审 |
|------|------|------|------|
| 验证方式 | 逻辑推演 | 代码级验证 | 代码级验证 + 交叉复验 |
| 前端文件存在性 | 未验证 | ❌ 误报"不存在" | ✅ 确认存在 |
| Gap 1 严重度 | P0 | P0（+atomicReceive 同源缺陷） | P0（维持，+ saveItems 丢失 itemId） |
| 新发现 | 6 Gap + 2 建议 | 3 个（atomicReceive/validateReceipt/前端存在） | 4 个（materialCode 未填充/ReceiptDrawer 无 handler/API 无状态校验/record.supplierId 待验证） |
| v2 误报 | — | — | 前端文件"不存在"需撤销 |
| 总体判定 | ADJUST | ADJUST | **ADJUST**（一致） |
