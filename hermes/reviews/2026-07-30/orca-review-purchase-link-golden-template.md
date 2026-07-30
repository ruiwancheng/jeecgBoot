# 采购申请/采购订单/采购收货 — 黄金模板对齐方案评审

> 评审日期：2026-07-30 | 评审对象：pi 草案（采购链路三模块 UX 对齐黄金模板）
> 判定：**NEEDS WORK**（7 项需调整，含 1 项阻塞）

---

## 一、架构/实施可行性

### 文件清单核查

| 模块 | 文件 | 数 | 有 ItemSubTable? | 有 expandedRow? |
|------|------|:--:|:--:|:--:|
| 采购申请 apply | index, data, api, Drawer, ItemsSubTable | 5 | ✅ | ✅ |
| 采购订单 order | index, data, api, Drawer, ItemsSubTable | 5 | ✅ | ✅ |
| 采购收货 receipt | index, data, api, Drawer, ItemsSubTable | 5 | ✅ | ✅ |
| **小计源码** | | **15** | | |
| 新建 | purchase/shared/statusColor.ts | 1 | | |
| **合计** | | **16** | | |

✅ **16 文件数正确。** 补充说明：order 目录下 7 个文件含 `JPurchaseOrderSelect.vue` 和 `PurchaseOrderSelectModal.vue`（业务组件），本任务不改。

---

## 二、🔴 阻塞级发现

### ❌ 阻塞 #1：采购订单 + 采购收货的关联字段缺少 @Dict 注解 → Alert 文案无法显示编码

草案的 Alert 文案设计依赖 `_dictText` 显示关联编码：

| 模块 | 草案 Alert 文案 | 需要的字段 | 后端是否有 @Dict？ |
|------|---------|------|:--:|
| 订单 | "由申请创建" | `purchaseApplyId` | ❌ **无 @Dict** |
| 收货 | "由采购订单入库" | `purchaseOrderId` | ❌ **无 @Dict** |

后端验证：

```java
// MesPurchaseOrder.java — purchaseApplyId 无 @Dict
@Excel(name = "申请单号", width = 15)
@Schema(description = "采购申请单ID")
private String purchaseApplyId;  // ← 没有 @Dict(dictTable = "c_mes_purchase_apply", ...)

// MesPurchaseReceipt.java — purchaseOrderId 无 @Dict
@Excel(name = "采购订单", width = 15)
@Schema(description = "关联采购订单ID")
private String purchaseOrderId;  // ← 没有 @Dict(dictTable = "c_mes_purchase_order", ...)
```

**后果**：`queryById` 返回的 JSON 不含 `purchaseApplyId_dictText` 和 `purchaseOrderId_dictText`。Alert 中的"由订单 PO-xxx 入库"完全无法实现——`record.purchaseOrderId_dictText` 是 `undefined`，show 出来的是一个长 UUID 而非编码。

**销售链路为什么可行**：销售链路的关联字段全都有 `@Dict`（如 `MesDeliveryNote.salesOrderId` 有 `@Dict(dictTable = "c_mes_sales_order", dicText = "code", dicCode = "id")`）。采购链路这里有两个字段没有。

### 三选项

| 选项 | 内容 | 复杂度 | 推荐 |
|------|------|:--:|:--:|
| A | 给两个字段加 `@Dict` 注解 + 重新编译后端 | 1 行 × 2 文件 | ⭐ 推荐 |
| B | Alert 只显示 ID（如 "由订单 d3f4a… 入库"） | 无改后端 | 不推荐（ID 对业务人员无意义） |
| C | 不显示关联编码，改通用文案 | 无改后端 | 不推荐（失去链路视图价值） |

**推荐 A**。实现方式：在 `MesPurchaseOrder.java` 的 `purchaseApplyId` 上加 `@Dict(dictTable = "c_mes_purchase_apply", dicText = "code", dicCode = "id")`；在 `MesPurchaseReceipt.java` 的 `purchaseOrderId` 上加 `@Dict(dictTable = "c_mes_purchase_order", dicText = "code", dicCode = "id")`。纯注解加一行，不加 update-begin/end（注解无业务逻辑）。

**但这违反草案"不动后端"**。需要用户决策。

---

## 三、🟡 状态机颜色映射

### 三模块状态值与推荐色彩

| 模块 | 状态值 | 状态名 | 推荐色 | 阶段 |
|------|:--:|------|:--:|------|
| apply | 1 | 草稿 | orange | 可编辑 |
| apply | 2 | 已提交 | blue | 流转中 |
| apply | 3 | 已通过 | green | 完成 |
| apply | 4 | 已驳回 | gray | 失败终态 |
| order | 1 | 草稿 | orange | 可编辑 |
| order | 2 | 待确认 | blue | 流转中 |
| order | 3 | 已确认 | green | 执行中 |
| order | 4 | 部分到货 | cyan | 进行中(特殊) |
| order | 5 | 已到货 | green | 完成 |
| order | 6 | 已关闭 | gray | 终止 |
| receipt | 1 | 草稿 | orange | 可编辑 |
| receipt | 2 | 已入库 | green | 完成 |

### ❌ 需调整项 #2：订单 status=4 部分到货是"进行中"特殊状态，应独立颜色

草案将所有 "3/4/5" 映射为 green，但 `部分到货(4)` 是过渡态——不是完成。业务场景：
- 采购员看到"部分到货"应该知道还要继续收货
- 如果和"已到货"同色 → 扫一眼列表看不出哪些订单还欠货

**推荐**：`4: 'cyan'`（或 `'#1890ff'`，antd blue 的浅变体）。语义：进行中但已完成部分收货，不是最终状态。

修正映射：

```typescript
order: {
  '1': 'orange',    // 草稿
  '2': 'blue',      // 待确认
  '3': 'green',     // 已确认
  '4': 'cyan',      // 部分到货 ← 独立颜色
  '5': 'green',     // 已到货
  '6': 'default',   // 已关闭
}
```

### ❌ 需调整项 #3：apply 的 已驳回(4) 与 order 的 已关闭(6) 颜色一致性

✅ 草案正确——两者都是终态（非正常完成），都映射 `'default'`（灰色）。一致。

---

## 四、Alert 文案评审

### 修正的 Alert 文案（基于阻塞 #1 解决的前提下）

| 模块 | 修正文案 | 修改说明 |
|------|---------|---------|
| 采购申请 | `审核通过后自动生成采购订单。状态：草稿→已提交→已通过/已驳回` | 草案原文正确，只加状态流转说明 |
| 采购订单 | `由申请 PR-xxx 创建。收货后订单自动到货。状态：草稿→待确认→已确认→部分到货→已到货` | 待 @Dict 加好后 `purchaseApplyId_dictText` 可用 |
| 采购收货 | `由订单 PO-xxx 入库。审核后增加库存、重算物料移动平均成本。` | "重算成本"比"重算物料移动平均成本"更简洁，保持一致 |

### ❌ 需调整项 #4：receipt.data.ts 中有两处代码 bug

**Bug 1 — formSchema status 用错字典码**：

```typescript
// receipt.data.ts line 29 — 错误！
{ field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 },
  componentProps: { dictCode: 'yn' }, defaultValue: '1', show: false },
```

`dictCode: 'yn'` 是通用是/否字典，不是采购收货状态字典。应改为 `dictCode: 'mes_purchase_receipt_status'`。

**Bug 2 — receipt.data.ts searchFormSchema 缺状态下拉**：

```typescript
// receipt.data.ts — searchFormSchema 只有 code + purchaseOrderId + warehouseId
// 缺 { field: 'status', label: '状态', component: 'JDictSelectTag', ... dictCode: 'mes_purchase_receipt_status' }
```

两个都是本次对齐中应该修复（`data.ts` 改 status 列时会自然暴露）。

---

## 五、页面间跳转按钮

### ❌ 需调整项 #5：同上次销售评审结论——降级为独立 task

理由与销售链路评审一致：黄金模板 10 模式无跨页面跳转。加上目标页面需要 query 过滤逻辑 + 3 条链路测试 → 超过模板对齐范围。

**处理**：本任务删除所有跳转按钮，专注 statusTag + Alert + @generated-from。

---

## 六、其它发现

### ❌ 需调整项 #6：采购订单无 rowSelection + 无批量审核按钮

`order/index.vue` 现状：
```html
<BasicTable @register="registerTable">  <!-- 没有 :rowSelection -->
```
没有复选框列，没有批量审核/反审核按钮。对比采购申请和采购收货——两者都有 rowSelection。

黄金模板模式 2（复选框 rowSelection + 批量审核/反审核）要求所有列表页具备批量操作能力。采购订单的缺失导致采购员需要逐条点开操作。

**处理**：本任务中加 rowSelection + 批量审核/关闭按钮。方案与 sales/order 的批量操作一致（`allStatus` computed + `batchAudit`/`batchClose` 函数）。

### ❌ 需调整项 #7：采购收货也缺 rowSelection

同理。收货列表页也没有复选框列和批量审核按钮。一并加入。

### 采购申请 index.vue 已有 rowSelection 但无批量状态流转

`apply/index.vue` 有 `rowSelection` + `批量删除` 按钮，但没有"批量审核"按钮。对比销售订单和采购订单的批量审核设计（`allStatus != '1'` 守卫 + `batchAudit` 函数），采购申请也应该补上。

### 采购订单 Drawer vs 销售订单 Drawer 差异

采购订单 Drawer (`OrderDrawer.vue`) 对比销售订单 Drawer (`OrderDrawer.vue`)：
- 采购订单：无 `enrichItems()` 方法 → 编辑时明细行不补齐 spec/unitText → 用户看不到物料规格
- 销售订单：有 `enrichItems()` → 补齐 spec/unitText

**这是既有设计差异。不改。** 但应在 PR 描述中注明——采购订单明细不显示规格是设计选择，非 bug。

### 采购收货 Drawer 有独特的"选择订单自动加载明细"流程

`ReceiptDrawer.vue` 包含 `JPurchaseOrderSelect` 组件 + `onOrderSelected` 回调，选订单后自动通过 `loadOrderItemsForReceipt` 加载可入库明细行。这是业务特性，与黄金模板无关。**不改。**

### `purchaseOrderId` 列的 `_dictText` 问题

`receipt.data.ts` columns[1] 显示的是 `dataIndex: 'purchaseOrderId'`（裸 ID），不是 `purchaseOrderId_dictText`。因为后端 `purchaseOrderId` 没有 `@Dict` 注解（阻塞 #1）。**加 @Dict 后这里也会自然修复。**

---

## 七、修正后的实施步骤

```
Step 0: 后端加 @Dict 注解（需用户确认）
  MesPurchaseOrder.java → purchaseApplyId 加
    @Dict(dictTable = "c_mes_purchase_apply", dicText = "code", dicCode = "id")
  MesPurchaseReceipt.java → purchaseOrderId 加
    @Dict(dictTable = "c_mes_purchase_order", dicText = "code", dicCode = "id")
  mvn compile -pl project-mes -am

Step 1: purchase/shared/statusColor.ts（新建 1 文件）
  三模块状态颜色映射表 + getStatusColor() 导出
  order 4: 'cyan'（部分到货独立颜色）

Step 2: data.ts（3 文件并行）
  apply.data.ts:   status 列 + // @generated-from
  order.data.ts:   同上
  receipt.data.ts: 同上 + fix dictCode: 'yn' → 'mes_purchase_receipt_status'
                   + searchForm 加状态下拉

Step 3: index.vue（3 文件并行）
  apply/index.vue:   statusTag 槽位（引用 shared/statusColor）
  order/index.vue:   statusTag + rowSelection + 批量审核/关闭
  receipt/index.vue: statusTag + rowSelection + 批量审核
  各加 <!-- @generated-from -->
  ❌ 不加页面跳转按钮

Step 4: Drawer.vue（3 文件并行）
  各加 a-alert 模式 8（文案差异化，用 record._dictText）
  apply:  "审核通过后自动生成采购订单"
  order:  "由申请 PR-xxx 创建；收货后订单自动到货"
  receipt: "由订单 PO-xxx 入库；审核后增库存、重算成本"
  各加 <!-- @generated-from -->

Step 5: ItemsSubTable.vue（3 文件并行）
  各加 <!-- @generated-from -->
  无业务逻辑变更

Step 6: 验证
  mvn compile + ESLint + Prettier（16+2 文件）
  curl /mes/purchase/apply/list → status 列含 _dictText + _dictText 含 PR-
  curl /mes/purchase/order/list → 同上 + purchaseApplyId_dictText 含 PR-
  curl /mes/purchase/receipt/list → 同上 + purchaseOrderId_dictText 含 PO-
  Playwright 6 张截图（三模块列表页含 statusTag + 三模块新增抽屉含 Alert）
```

---

## 八、总判定

| 标准 | 评分 | 说明 |
|------|:--:|------|
| 文件清单完整性 | ✅ | 16 文件正确 |
| 依赖查证 | 🔴 | 两个关联字段缺 @Dict 注解，Alert 文案无法实现 |
| 状态机颜色映射 | ⚠️ | 订单 status 4 应独立颜色（cyan） |
| Alert 文案 | ⚠️ | 待 @Dict 修复后可行 |
| 页面跳转按钮 | ⚠️ | 应降级为独立 task（同销售评审） |
| 既有 bug | 🔴 | receipt.data.ts dictCode 错误 + searchForm 缺状态下拉 |

**判定：NEEDS WORK — 7 项需调整后方可执行。**

| # | 调整项 | 严重度 | 影响 |
|---|--------|:--:|------|
| 1 | purchaseApplyId + purchaseOrderId 缺 @Dict 注解 | 🔴 阻塞 | Alert 文案无法显示编码 |
| 2 | order status 4 部分到货应独立颜色 (cyan) | 🟡 | 降低业务区分度 |
| 3 | receipt.data.ts dictCode 'yn' → 'mes_purchase_receipt_status' | 🟡 | 状态字典错误 |
| 4 | receipt searchFormSchema 缺状态下拉 | 🟡 | 与模板不一致 |
| 5 | 页面跳转按钮降级为独立 task | 🟡 | 范围越界 |
| 6 | order/index.vue 缺 rowSelection + 批量审核 | 🟡 | 与模板模式 2 不一致 |
| 7 | receipt/index.vue 缺 rowSelection + 批量审核 | 🟡 | 同上 |
