# orca-review: 采购入库明细自动加载方案评审

**评审日期:** 2026-07-22  
**评审人:** Claude Code (orca-review worker)  
**方案范围:** 5 文件跨前后端，采购入库单选择采购订单后自动加载明细

---

## 一、方案概要

| 层 | 文件 | 改动 |
|---|------|------|
| 后端 DTO | `MesPurchaseOrderItemForReceipt.java` | ✅ 已存在（`remainQty` 预计算） |
| 后端 Service | `MesPurchaseReceiptServiceImpl.java` | 新增 `loadOrderItemsForReceipt(purchaseOrderId)` |
| 后端 Controller | `MesPurchaseReceiptController.java` | 新增 `GET /mes/purchase/receipt/loadOrderItems` |
| 前端 API | `receipt.api.ts` | 新增 `queryOrderItemsForReceipt(params)` |
| 前端 Drawer | `ReceiptDrawer.vue` | 订单选择联动→自动加载明细行 |

---

## 二、评审结论

**判定: 🔶 调整后通过 (ADJUST)**

方案核心思路正确，基础设施（DTO、atomicReceive）已就位。但存在 **6 个需要补全的 gap** 和 **2 个设计建议**，补齐后即可实施。

---

## 三、逐项分析

### ✅ 3.1 做得好的部分

1. **DTO 设计合理** — `remainQty = orderQty - receivedQty` 在后端预计算，符合"后端优先"原则。字段齐全（物料编码/名称/数量/已收/可收/单价/税率），满足前端展示需求。

2. **并发安全已有兜底** — `atomicReceive()` 在审核时做原子扣减（`UPDATE ... SET received_qty = received_qty + #{qty} WHERE ... AND received_qty + #{qty} <= quantity`），即使加载时看到的 `remainQty` 因并发而过时，审核时也会被拒绝。这符合"乐观 UI + 悲观提交"模式。

3. **JPurchaseOrderSelect 已支持 change 事件** — 组件 emit `change` 时传递 `{ value, label, record }`，`record` 包含完整订单对象（含 `supplierId`、`code` 等），前端可以直接从中取供应商信息。

4. **现有校验逻辑可复用** — `validateReceipt()` 已有完整的超量校验（历史累计 + 本次入库 ≤ 采购数量），自动加载不影响这条防线。

### 🔶 3.2 必须补全的 Gap（6 个）

#### Gap 1: 缺少 `orderItemId` 关联字段

**严重度:** 🔴 高  
**影响:** 同物料多行场景下无法追溯

当前 `MesPurchaseReceiptItem` 没有 `orderItemId` 字段。audit() 方法中靠 `materialId` 匹配订单行取单价：
```java
// audit() 第140行 — 注释已承认此限制
piQw.eq(MesPurchaseOrderItem::getOrderId, e.getPurchaseOrderId())
     .eq(MesPurchaseOrderItem::getMaterialId, item.getMaterialId());
// 同物料多行取第一行——后续 order_item_id 关联后再优化
```

**场景:** 采购订单有两行同物料（不同交货日期/单价）：
- 行1: 物料A × 100, 单价 10.00
- 行2: 物料A × 50, 单价 12.00

当前按 `materialId` 匹配永远取到行1的单价 10.00，行2入库也会按10.00计价→金额错误。

**建议:** 
- 短期（本次）: `MesPurchaseReceiptItem` 新增 `orderItemId` 字段，`loadOrderItemsForReceipt` 返回时携带 `itemId`，前端保存时回传
- 或：本次先标注为已知限制（TODO-PHASE2），在 audit() 提价逻辑处加 warn 日志

#### Gap 2: 供应商未联动填充

**严重度:** 🟡 中  
**影响:** 用户体验——选完订单还要手动选供应商

当前 `ReceiptDrawer.vue` 第26行供应商是独立的下拉框（`ApiSelect`）。`JPurchaseOrderSelect` 的 change 事件已传递 `record.supplierId`，但未被消费。

**建议:** 在 purchase order change handler 中同步 `setFieldsValue({ supplierId: record.supplierId })`。

#### Gap 3: 订单变更时明细未清理

**严重度:** 🟡 中  
**影响:** 用户切换到另一个采购订单后，旧明细残留，数据错乱

**建议:** `purchaseOrderId` change 事件中：先清空 `items.value`，再调 API 加载新明细。同时清空供应商、仓库等已联动字段。

#### Gap 4: 物料列在自动加载模式下应为只读

**严重度:** 🟡 中  
**影响:** 自动加载后用户仍可改动物料（JMaterialSelect），不符合业务逻辑

当前 `itemColumns` 第14行 `materialId` 使用 `JMaterialSelect`（可编辑）。自动加载的明细物料来自订单，不应允许修改。

**建议:** 方案二选一：
- **方案A**: 新增 `readonly` prop 到列定义，自动加载时物料列渲染为纯文本
- **方案B**: 自动加载时 `JMaterialSelect` 设 `disabled=true`（更简单）

#### Gap 5: `remainQty` 未在前端展示

**严重度:** 🟡 中  
**影响:** 用户不知道还能入库多少，只能盲填数量

DTO 已计算了 `remainQty`，但当前表格列没有此列。

**建议:** 在 `itemColumns` 新增一列"可入库数量"，显示 `remainQty`，`receiptQuantity` 输入时校验不超过此值。

#### Gap 6: 后端应过滤 `remainQty <= 0` 的行

**严重度:** 🟢 低  
**影响:** 前端展示已全部入库的物料行（虽然 `atomicReceive` 会最终拦截）

**建议:** `loadOrderItemsForReceipt` 中只返回 `remainQty > 0` 的行，减少无效选项。

### 💡 3.3 设计建议（2 个）

#### 建议 1: 考虑"勾选入库"交互

方案描述中提到"勾选入库"，暗示用户可以选择性入库（不全量加载所有订单行）。当前表格无 rowSelection。

**实现路径:** 
- 后端返回全部可入库行（已过滤 remainQty > 0）
- 前端表格加 `rowSelection`（checkbox），默认全选
- 未勾选的行在提交时过滤掉（或 quantity 为 0 的自动跳过）

**权衡:** 如果大部分场景是全量入库，加 checkbox 增加交互复杂度。建议初期不加 checkbox，全部加载，用户手动删行。

#### 建议 2: `taxRate` 应落库到 receipt item

DTO 携带了 `taxRate`，但 `MesPurchaseReceiptItem` 无此字段。当前 audit() 在审核时才从订单行取税率，但如果订单行有多行（同物料不同税率），匹配可能出错。

**建议:** 如果本次加了 `orderItemId`（Gap 1），则税率从 orderItemId 精确查找，无需在 receipt item 冗余存储。如果暂不加 `orderItemId`，建议在 receipt item 加 `taxRate` 字段，加载时一并填充。

---

## 四、端到端流程走查

以"用户新建入库单→选采购订单→自动加载明细→填数量→保存→审核"为例：

```
1. 用户点击"新增" → Drawer 打开 → 自动获取编码 ✓
2. 用户选择采购订单 → JPurchaseOrderSelect change 事件触发 ✓
   2a. 前端调 loadOrderItems API → 获取 [MesPurchaseOrderItemForReceipt] ✓
   2b. 自动填充 supplierId ← record.supplierId ⚠️ Gap 2
   2c. 清空旧 items → 填充新 items ✓ / ⚠️ Gap 3
   2d. 物料列显示为只读文本 ⚠️ Gap 4
   2e. 显示 remainQty 列 ⚠️ Gap 5
3. 用户填写 receiptQuantity + 质检结果 → 提交
   3a. validateReceipt() 校验超量 ✓ (已有逻辑)
   3b. saveItems() 写入 receipt_item 表 ✓
4. 审核 → atomicReceive 原子扣减 → 真正防超收 ✓
```

---

## 五、实施建议优先级

| 优先级 | 事项 | 类型 |
|:--:|------|------|
| P0 | Gap 1: orderItemId 关联（至少标注 TODO） | 数据完整性 |
| P1 | Gap 2: 供应商联动 | UX |
| P1 | Gap 3: 订单变更清理 | 防数据错乱 |
| P1 | Gap 4: 物料只读 | 防误操作 |
| P2 | Gap 5: remainQty 展示 | UX |
| P2 | Gap 6: 过滤已收完的行 | 后端优化 |
| P3 | 建议 1: 勾选入库 | UX 增强 |
| P3 | 建议 2: taxRate 落库 | 业财准确性 |

---

## 六、最终判定

**🔶 ADJUST — 补全 6 个 Gap 后实施**

方案骨架正确，但缺少用户体验和数据完整性的关键细节。建议：
1. **P0-P1 项必须补全后再编码**（尤其是 Gap 1 的 orderItemId 至少标注 TODO）
2. P2-P3 项可在实施中逐步添加
3. 前后端接口契约（请求参数/返回格式）在编码前先对齐

预计实施时间：补全 Gap 后，5 个文件变更约 2-3 小时工作量。
