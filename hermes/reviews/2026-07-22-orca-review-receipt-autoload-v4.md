# orca-review v4: 采购入库明细自动加载 — 最终独立评审

**评审日期:** 2026-07-22
**评审人:** Claude Code (orca-review worker, 独立派发)
**评审对象:** 采购入库明细自动加载方案（5 文件跨前后端，实际 8 文件含 DTO/Entity/Mapper）
**评审方法:** 逐文件完整代码阅读 + v1/v2/v3 评审交叉验证 + 端到端流程走查

---

## 一、代码变更总结

本次 diff 涉及 5 个业务文件 + 1 个新增 DTO + 2 个关联文件（Entity + Mapper 需同步修改但未改）：

| # | 文件 | 变更内容 | 状态 |
|---|------|---------|:--:|
| 1 | `MesPurchaseOrderItemForReceipt.java` | **新增** DTO，含 itemId/materialId/materialCode/materialName/orderQty/receivedQty/remainQty/unitPrice/taxRate | ✅ |
| 2 | `MesPurchaseReceiptController.java` | +9行，新增 `GET /loadOrderItemsForReceipt` 端点 | ✅ |
| 3 | `IMesPurchaseReceiptService.java` | +4行，接口声明 | ✅ |
| 4 | `MesPurchaseReceiptServiceImpl.java` | +23行，实现 `loadOrderItemsForReceipt` 方法 | ✅ |
| 5 | `receipt.api.ts` | +5行，前端 API 函数 | ✅ |
| 6 | `ReceiptDrawer.vue` | +68/-14行，onOrderSelected handler + 行选择 + 列调整 | ✅ |
| - | `MesPurchaseReceiptItem.java` | **未修改** — 缺少 orderItemId 字段 | ⚠️ |
| - | `MesPurchaseOrderItemMapper.java` | **未修改** — atomicReceive 仍用 materialId 做 WHERE | ⚠️ |

---

## 二、逐文件代码级验证

### 2.1 Controller 端点 ✅

```java
@GetMapping("/loadOrderItemsForReceipt")
@RequiresPermissions("mes:purchaseReceipt:list")
public Result<List<MesPurchaseOrderItemForReceipt>> loadOrderItemsForReceipt(@RequestParam String orderId)
```

- ✅ `@RequiresPermissions` 已注册
- ✅ 返回类型正确，用完整限定名避免 import 依赖
- ✅ update-begin/end 标记完整
- ⚠️ 无 `@Operation` 的 `summary` 已填写

### 2.2 ServiceImpl.loadOrderItemsForReceipt ✅⚠️

```java
public List<MesPurchaseOrderItemForReceipt> loadOrderItemsForReceipt(String orderId) {
    // 查询订单行 → 逐行映射为 DTO
}
```

**正确部分：**
- ✅ 按 lineNo 排序，保证顺序
- ✅ receivedQty null-safe 处理（`!= null ? item.getReceivedQty() : BigDecimal.ZERO`）
- ✅ remainQty 正确计算（`quantity - receivedQty`）
- ✅ unitPrice 和 taxRate 透传

**遗漏：**
- ❌ **materialCode/materialName 未填充**（DTO 声明了这两个字段但从未 set）
- ❌ **未过滤 remainQty ≤ 0** 的订单行（已全部入库的行也会返回）
- ❌ **未校验订单状态**（任何状态的订单都能调用此 API，即使订单未确认）

### 2.3 DTO: MesPurchaseOrderItemForReceipt ✅

```java
@Data @Accessors(chain = true)
public class MesPurchaseOrderItemForReceipt implements Serializable {
    private String itemId;        // ✅ 订单行ID，关键追踪字段
    private String materialId;    // ✅
    private String materialCode;  // ✅ 声明但 Service 未填充
    private String materialName;  // ✅ 声明但 Service 未填充
    private BigDecimal orderQty;  // ✅
    private BigDecimal receivedQty; // ✅
    private BigDecimal remainQty;   // ✅
    private BigDecimal unitPrice;   // ✅
    private BigDecimal taxRate;     // ✅
}
```

- ✅ 字段设计合理，覆盖前端自动加载所需全部信息
- ✅ 链式调用风格与项目一致
- ✅ `itemId` 是关键字段——它是唯一能区分同物料多行的标识
- ⚠️ materialCode/materialName 是"声明但未实现"的半成品

### 2.4 前端: receipt.api.ts ✅

```typescript
export function loadOrderItemsForReceipt(orderId: string) {
  return defHttp.get({ url: `${BASE}/loadOrderItemsForReceipt`, params: { orderId } });
}
```

- ✅ GET 请求参数正确（`params: { orderId }`）
- ✅ 返回值类型由 defHttp 泛型自动推断

### 2.5 前端: ReceiptDrawer.vue — 核心交互 ✅⚠️

**已实现的改进：**
- ✅ `@change="onOrderSelected"` 已接线到 `JPurchaseOrderSelect`
- ✅ `onOrderSelected` 调 API、映射字段、填充 items、默认全选
- ✅ 行选择（rowSelection）含 `remainQty ≤ 0` 禁用逻辑
- ✅ 提交时仅发送勾选行（`selectedIndices` 过滤）
- ✅ `orderQuantity` 列改为只读 `<span>`（不再可编辑 InputNumber）
- ✅ 新增 `materialCode`、`receivedQty`、`remainQty` 三列
- ✅ "手动添加行" 按钮重命名 + 已选行数展示

**存在的 Bug 和遗漏：**

#### 🔴 Bug 1: rowKey 与 selectedRowKeys 不匹配

```javascript
// 表格 rowKey="lineNo"，lineNo = idx + 1 → 值为 "1", "2", "3"
items.value = orderItems.map((it: any, idx: number) => ({
    lineNo: idx + 1,  // ← 表格用这个做 rowKey
    ...
}));

// 但 selectedRowKeys 用的是数组下标！
selectedRowKeys.value = items.value
    .filter((it: any) => it.remainQty > 0)
    .map((_: any, i: number) => String(i));  // ← "0", "1", "2" 与表格的 "1", "2", "3" 不匹配！
```

**后果：** Ant Design Vue 的 rowSelection 通过 rowKey 匹配选中行。表格行 key 是 `"1"` (lineNo)，但 selectedRowKeys 里是 `"0"` (数组下标)。复选框永远无法正确显示选中状态。

**修复：** `.map((it: any) => String(it.lineNo))` 或改用 `record.lineNo` 做 key。

#### 🔴 Bug 2: 选择采购订单后未自动填充 supplierId 和 warehouseId

```javascript
async function onOrderSelected(selected: { value: string; label: string; record: any }) {
    // record 来自 JPurchaseOrderSelect 的 emit
    // record 应包含 supplierId, warehouseId 等订单字段
    // 但 onOrderSelected 完全没有 setFieldsValue！
}
```

**后果：** 用户选了采购订单后，明细行加载了，但供应商和仓库字段仍为空。保存时 `validateReceipt` 会因 supplierId/warehouseId 为空而报错。

**修复：** 在 onOrderSelected 中调 `methods.setFieldsValue({ supplierId: selected.record.supplierId, warehouseId: selected.record.warehouseId })`。

#### 🟡 Gap: materialId 列在自动加载场景下应只读

自动加载的物料来自采购订单，不应允许用户在入库环节改动物料。当前 `JMaterialSelect` 仍可编辑。

#### 🟡 Gap: 缺少前端数量校验（receiptQuantity ≤ remainQty）

虽然后端 `validateReceipt` 有校验，但前端应在 `InputNumber` 上设 `:max="record.remainQty"` 提供即时反馈。

---

## 三、关联文件未修改的遗留问题

### 🔴 P0: orderItemId 未落库

**`MesPurchaseReceiptItem.java` 无 `orderItemId` 字段。**

当前 `saveItems()` (L272-284) 只设置 `receiptId/lineNo/审计字段`，不设置任何订单行关联。DTO 携带的 `itemId` 在前端以 `_itemId` 存储（带下划线前缀表示"不提交"），但即使提交到后端，`MesPurchaseReceiptItem` 实体也没有对应字段接收。

**影响链：**
1. 入库行无法追溯到具体订单行 → 同物料多行时无法区分
2. `audit()` 取价用 `get(0)` 可能取错单价（同物料多行场景）
3. `atomicReceive` 用 materialId 做 WHERE → 同物料多行全部被更新

### 🔴 P0: atomicReceive SQL 同物料多行缺陷

```sql
UPDATE c_mes_purchase_order_item 
SET received_qty = received_qty + #{qty} 
WHERE order_id = #{orderId} 
  AND material_id = #{materialId}     -- ← 匹配所有同物料行！
  AND received_qty + #{qty} <= quantity
```

**攻击场景：**
```
订单行A: material=M001, qty=100, received=0
订单行B: material=M001, qty=50,  received=0
→ 入库行A 30个 M001 → atomicReceive(orderId, M001, 30)
→ 订单行A received=30 AND 订单行B received=30 （B 被误更新！）
```

**修复：** WHERE 条件改为 `AND id = #{orderItemId}`（需要入库行先有 orderItemId）。

---

## 四、端到端流程走查

以"用户新建入库单→选采购订单→自动加载明细→勾选→填数量→保存→审核"为例：

```
1. 点击"新增" → Drawer 打开 → getNextCode 获取编码 ✅
2. 选择采购订单 → JPurchaseOrderSelect @change 触发
   2a. ✅ onOrderSelected 调 loadOrderItemsForReceipt API
   2b. ✅ items 填充（materialId/orderQty/receivedQty/remainQty 等）
   2c. ❌ 未 setFieldsValue({ supplierId, warehouseId }) → 保存时校验失败
   2d. ✅ items 替换（旧行清理）
   2e. ❌ materialCode 始终为空（Service 未填充）
   2f. ⚠️ materialId 列仍可编辑（应只读）
   2g. ❌ 行选择 Bug：rowKey(lineNo) vs selectedRowKeys(数组下标) 不匹配
3. 用户勾选行 + 填数量 → 提交
   3a. ✅ 仅提交勾选行
   3b. ❌ saveItems() 不保存 orderItemId（实体缺少字段）
   3c. ✅ validateReceipt() 拦截订单外物料（null→报错）
   3d. ⚠️ validateReceipt() orderQtyMap merge 用 (a,b)→a（同物料多行数量被低估）
4. 审核
   4a. ✅ 先改状态再执行副作用（顺序已修正）
   4b. ❌ atomicReceive 用 materialId 做 WHERE（同物料多行全部被更新）
   4c. ❌ audit() 取价 get(0)（同物料多行取错单价）
   4d. ✅ 税率从订单行取（不再硬编码 13%）
   4e. ✅ 订单状态回写（markPartiallyReceived/markFullyReceived）
```

---

## 五、问题汇总与优先级

| 优先级 | 编号 | 问题 | 文件 | 类型 |
|:--:|------|------|------|:--:|
| **🔴 P0** | B1 | **rowKey 不匹配**：表格用 lineNo 做 key，selectedRowKeys 用数组下标 | ReceiptDrawer.vue | Bug |
| **🔴 P0** | B2 | **未自动填充 supplierId/warehouseId**：选择订单后未 setFieldsValue | ReceiptDrawer.vue | 功能缺失 |
| **🔴 P0** | G1 | **orderItemId 未落库**：Entity 缺字段，saveItems 不保存，atomicReceive 无法精确匹配 | Entity+ServiceImpl+Mapper | 数据完整性 |
| **🔴 P0** | G2 | **atomicReceive 同物料多行缺陷**：WHERE 用 materialId 而非 id | Mapper | 数据破坏 |
| **🟡 P1** | G3 | **materialCode/materialName 未填充**：DTO 声明但 Service 不 set | ServiceImpl | UX |
| **🟡 P1** | G4 | **loadOrderItemsForReceipt 不过滤 remainQty≤0** | ServiceImpl | 后端优化 |
| **🟡 P1** | G5 | **loadOrderItemsForReceipt 无订单状态校验** | ServiceImpl | 防御性 |
| **🟡 P1** | G6 | **validateReceipt orderQtyMap merge 用 (a,b)→a** 而非 BigDecimal::add | ServiceImpl | 校验准确 |
| **🟢 P2** | G7 | **audit() 取价 get(0)**：同物料多行场景可能取错单价 | ServiceImpl | 数据准确 |
| **🟢 P2** | G8 | **物料列在自动加载场景下应只读** | ReceiptDrawer.vue | UX |
| **🟢 P2** | G9 | **前端缺少 receiptQuantity ≤ remainQty 即时校验** | ReceiptDrawer.vue | UX |

---

## 六、与 v3 评审的对比

| 维度 | v3 评审 | v4 本评审 |
|------|------|------|
| 验证方式 | 代码级验证 + 交叉复验 | **完整 git diff 阅读** + 逐文件代码级验证 |
| 前端文件存在性 | ✅ 确认存在（纠正 v2 误报） | ✅ 确认存在且代码完整 |
| P0-1 (orderItemId) | 维持 | **维持**，确认 Entity 未修改 |
| P0 (atomicReceive) | 维持 | **维持**，确认 Mapper 未修改 |
| P1-1 (ReceiptDrawer 接线) | "缺少 change handler" | **接线已实现**，但发现 2 个新 Bug |
| **新发现** | 4 个 | 2 个关键 Bug (rowKey 不匹配 + 未 setFieldsValue) |
| v2 误报 | "前端文件不存在需撤销" | 同意撤销 |
| 总体判定 | ADJUST | **ADJUST**（一致） |

**v4 的关键差异：**
- v3 评审时 `ReceiptDrawer.vue` 的 autoload 接线**尚未实现**（v3 称其"缺少 change handler"）
- v4 评审时接线**已实现**但存在 2 个可复现的 Bug（rowKey 不匹配 + 未 setFieldsValue）
- 这意味着实施进度从 v3 到 v4 有实质性推进，但接线质量需要修复

---

## 七、最终判定

**🔶 ADJUST — 方案方向正确，骨架已就位，但存在 4 个 P0 必须修复后才能合并。**

### 必须修复（阻塞合并）：
1. **B1 (rowKey 不匹配)** — 前端 Bug，复选框选中状态完全不工作
2. **B2 (未 setFieldsValue)** — 前端功能缺失，选择订单后供应商/仓库为空，保存必失败
3. **G1 (orderItemId 未落库)** — 需要 DDL + Entity + saveItems + atomicReceive 联动修改
4. **G2 (atomicReceive 同物料多行)** — 依赖 G1 修复后改 WHERE 条件

### 建议修复（非阻塞但影响 UX/健壮性）：
- G3-G6（materialCode 填充、过滤、状态校验、orderQtyMap merge）
- G7-G9（取价、物料只读、前端即时校验）

---

## 八、修复建议顺序

```
第一轮：B1(rowKey) + B2(setFieldsValue) → 前端可工作，能保存入库单
第二轮：G1(orderItemId) + G2(atomicReceive) → 数据完整性修复，需要 DDL
第三轮：G3-G6 → UX 完善 + 防御性加固
```

**注意：** G1 涉及 DDL（`ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN order_item_id ...`），需新增 SQL 迁移文件。G2 依赖 G1 完成后修改 `atomicReceive` 的 WHERE 条件。

---

*报告结束*
