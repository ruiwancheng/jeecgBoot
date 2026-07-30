# 销售订单/发货单/销售出库 — 黄金模板对齐方案评审

> 评审日期：2026-07-30 | 评审对象：pi 草案（销售链路三模块 UX 对齐黄金模板）
> 判定：**NEEDS WORK**（5 项需调整后方可执行，无阻塞）

---

## 一、架构/实施可行性

**结论：可行但有 2 项遗漏。**

### 文件清单核查

| 模块 | 文件 | 数 | 有 ItemsSubTable? | 有 expandedRowRender? |
|------|------|:--:|:--:|:--:|
| 订单 order | index.vue, data.ts, api.ts, Drawer, ItemsSubTable | 5 | ✅ | ✅ |
| 发货单 delivery | index.vue, data.ts, api.ts, Drawer | 4 | ❌ | ❌ |
| 销售出库 outbound | index.vue, data.ts, api.ts, Drawer | 4 | ❌ | ❌ |

**计划 13 个文件数正确。** 发货单和出库无展开行明细子表——这是合理设计（发货单明细仅 4 列、出库明细含批次/库位现场录入字段），不与黄金模板的"必含模式 3"冲突。

### ❌ 需调整项 #1：图片中 13 文件清单与文字描述不一致

> 已补 ItemsSubTable for outbound、delivery?

草案 Step 4 说"ItemsSubTable（1 文件，仅 order）"，正确。但方案开头说 13 文件 = 5(订单)+4(发货单)+4(出库)=13。文字和图片实质一致，无遗漏。

### ❌ 需调整项 #2：搜索区缺发货单/订单筛选下拉

三个模块的 searchFormSchema 均缺关键关联字段：

| 模块 | 现有搜索 | 缺失（UX 基线要求） |
|------|---------|----------|
| 发货单 delivery | code + status | **缺 salesOrderId 订单下拉**（ApiSelect） |
| 销售出库 outbound | code + status | **缺 deliveryNoteId 发货单下拉** + **salesOrderId 订单下拉** |
| 订单 order | code + customerId + status | ✅ 已有客户下拉 |

> `frontend.md` line 101 要求"搜索栏有字典下拉，涉及仓库的有 ApiSelect 下拉"。发货单查了订单、出库单查了发货单——这些关联查询下拉是业务必需品，不是"额外改进"。

**处理**：纳入本次，在 data.ts 搜索 schema 中加 ApiSelect 下拉（delivery.data.ts 已 import `querySalesOrderSelect`，搜索栏直接用即可）。

---

## 二、R3 风险——真实情况与草案不同 ⚠️

### 草案说

> "发货单 Entity 只有 sales_order_id（无 sales_order_code 字段），Drawer 显示订单号必须后端带出或列表加列。本次按用户决议'不动后端'，仅展示 ID。"

### 实际情况

**发货单 Entity 已有 `@Dict` 注解，后端已带出订单编码：**

```java
// MesDeliveryNote.java
@Dict(dictTable = "c_mes_sales_order", dicText = "code", dicCode = "id")
private String salesOrderId;
```

同理，**出库单 Entity 已有关联字典：**

```java
// MesSalesOutbound.java
@Dict(dictTable = "c_mes_delivery_note", dicText = "code", dicCode = "id")
private String deliveryNoteId;

@Dict(dictTable = "c_mes_sales_order", dicText = "code", dicCode = "id")
private String salesOrderId;
```

`@Dict` 注解会让 queryById 返回的 JSON 自动带上 `salesOrderId_dictText`（值为订单编码如 `SO-20260730-001`）和 `deliveryNoteId_dictText`（值为发货单编码如 `DN-20260730-001`）。

**结论：无需改后端。** Alert 文案直接用 record 中的 `_dictText` 字段即可实现"由订单 SO-xxx 创建"的展示。

### ❌ 需调整项 #3：Alert 文案必须用响应式数据，不能硬编码字符串

草案的 Alert 文案设计有误。以下是修正方案：

| 模块 | ❌ 草案（不生效） | ✅ 正确 |
|------|---------|------|
| 销售订单 | "审核后自动生成发货单" | ✅ 无问题（不需要关联单据引用） |
| 发货单 | "由订单 SO-xxx 创建" | `const alertText = \`由订单 ${record.salesOrderId_dictText} 创建；出库后订单自动置'已发货'\`` |
| 销售出库 | "由发货单 DN-xxx 出库" | `const alertText = \`由发货单 ${record.deliveryNoteId_dictText} 出库；审核后扣库存、生成应收单\`` |

**技术细节**：Alert 文字在 Drawer 中定义，但 `record` 数据在 `useDrawerInner` 回调中才能拿到。需要 `alertText` 用 ref 存为响应式值，在 open 回调中通过 `setFieldsValue` 或直接赋值更新。

---

## 三、状态机复杂度设计权衡

### 三模块状态对比

| 模块 | 状态值 | 数量 | 含义 |
|------|--------|:--:|------|
| order | 1/2/3/4/5/6 | 6 | 草稿→已审核→已下达→已发货→已关闭/已取消 |
| delivery | 0/1/2/3/4 | 5 | 已取消/草稿→待出库→已出库→已签收 |
| outbound | 0/1/2/3 | 4 | 已取消/草稿→待审核→已审核 |

### pi 问题逐一回答

**Q1：阶段映射 vs 字典全色映射？**

**评审结论：用阶段映射。** 原因：
1. 6 个订单状态如果每个不同色，颜色调板不够用且视觉噪声大
2. 业务人员只需区分"还能操作吗"（草稿 orange / 流转中 blue / 已完成 green / 已取消 gray）
3. 与其它出入库一致——颜色含义跨模块统一（orange=小心别误改，green=已完成，blue=进行中）

**Q2：getStatusColor() 通用函数能覆盖 3 个模块吗？**

**评审结论：用一个共享函数 + 3 个模块映射表。**

```typescript
// 文件位置：src/views/project/mes/sales/shared/statusColor.ts
export type StatusModule = 'order' | 'delivery' | 'outbound';

const STATUS_COLOR_MAP: Record<StatusModule, Record<string, string>> = {
  order:     { '1': 'orange', '2': 'blue', '3': 'blue', '4': 'green', '5': 'green', '6': 'default' },
  delivery:  { '0': 'default', '1': 'orange', '2': 'blue', '3': 'green', '4': 'green' },
  outbound:  { '0': 'default', '1': 'orange', '2': 'blue', '3': 'green' },
};

export function getStatusColor(module: StatusModule, status: string): string {
  return STATUS_COLOR_MAP[module]?.[status] || 'default';
}
```

**不推荐合并全映射**：3 个模块 state value 含义完全不同——order 的 '2' 是"已审核"（blue），但 delivery 的 '2' 是"待出库"（blue，含义不同），outbound 的 '2' 是"待审核"（blue，含义也不同）。合并用同一个 Map 容易写出 `'2': 'blue'` 然后忘记 delivery 的 '2' 含义完全不同——虽然值巧合相同，但维护者看不懂。分模块映射表**语义清晰**。

**Q3：阶段颜色一致性？**

✅ 与上次其它出入库评审结论一致——orange/green/blue 三色系。交付物：`order/index.vue` + `delivery/index.vue` + `outbound/index.vue` 各加 statusTag 槽位，引用各自模块的映射。

---

## 四、页面跳转按钮——优先级评估

### 草案设计

| 从 | 到 | query 参数 |
|------|----|------|
| 订单 | 发货单列表 | `?salesOrderId={id}` |
| 订单 | 出库列表 | `?salesOrderId={id}` |
| 发货单 | 出库列表 | `?deliveryNoteId={id}` |
| 出库 | 发货单详情 | 需跳转 Drawer |
| 出库 | 订单详情 | 需跳转 Drawer |

### ❌ 需调整项 #4：页面跳转是黄金模板范围外的新功能，应降级为独立 task

黄金模板 10 模式中**没有任何跨页面跳转**。该功能属于链路视图增强，不是模板对齐。

| 理由 | 说明 |
|------|------|
| 复杂度高 | query 参数要求目标页面在 onMounted 中读 `route.query.xxx` 做过滤——这是新功能不是模板对齐 |
| 3 个列表页都得改 | 订单列表加 `?salesOrderId=` 过滤逻辑、出库列表加 `?deliveryNoteId=` 过滤逻辑、出库列表加 `?salesOrderId=` 过滤逻辑 |
| 测试范围大 | 4 条跳转链路 × 3 个状态的页面状态 = 12 个测试场景 |
| 回退风险 | 如果 query 过滤逻辑有 bug，列表页默认加载全量（退化），看起来"正常"但实际上隐藏了问题 |

**建议**：本任务中**删除所有跳转按钮**，专注黄金模板 10 模式对齐。跳转功能在后续独立 PR 中实现（带 API 级别的 query 过滤 + E2E 测试）。

---

## 五、其它发现

### ⚠️ 需调整项 #5：发货单搜索 Schema 已 import querySalesOrderSelect 但未使用

`delivery.data.ts` line 4 已经 `import { querySalesOrderSelect }`，但 searchFormSchema 中没有用它。这是一个已引入但未接入的依赖——加订单下拉时直接用这个既有的 import。

### 发货单/出库单明细无物料详情补齐

对比订单的 `enrichItems()`（补齐 spec/unitText），发货单和出库单的 Drawer 只做 `updateItem(index, 'materialId', v?.value ?? v)`，不补齐 spec/unitText。这导致选物料后明细行不显示规格/单位——但这是业务设计差异（发货单/出库单明细不需要展示这些字段）。**不修。**

### 出库单 Drawer 含批次/库位字段

`OutboundDrawer.vue` 的明细包含 `batch` 和 `location` 字段——这是销售出库特有的，黄金模板中没有。**不改**——属于业务扩展，不是模板变更。

### 订单 status 变更按钮状态守卫合理性

`order/index.vue` 批量操作按钮的 `allStatus != '1'` 守卫只针对草稿执行批量审核/关闭/取消，这是正确的——只允许操作草稿态单据。`batchRelease` 的 `allStatus != '2'` 守卫针对已审核执行下达，也是正确的。

---

## 六、修正后的实施步骤

```
Step 1: data.ts（3 文件并行）
  order.data.ts:   status 列 { dataIndex:'status', width:80, slots:{customRender:'statusTag'} }
                   + // @generated-from
  delivery.data.ts: 同上 + searchForm 加 salesOrderId 下拉（已有 import）
                   + // @generated-from
  outbound.data.ts: 同上 + searchForm 加 deliveryNoteId 下拉 + salesOrderId 下拉
                   + // @generated-from

Step 2: shared/statusColor.ts（新建1文件）
  三模块状态颜色映射表 + getStatusColor() 导出

Step 3: index.vue（3 文件并行）
  各加 statusTag 槽位（引用 shared/statusColor）
  文件第一行加 <!-- @generated-from -->
  ❌ 不加页面跳转按钮

Step 4: Drawer.vue（3 文件并行）
  各加 a-alert 模式 8（文案差异化，用 record._dictText）
  文件第一行加 <!-- @generated-from -->

Step 5: OrderItemsSubTable.vue（1 文件）
  文件第一行加 <!-- @generated-from -->
  无业务逻辑变更

Step 6: 验证
  ESLint + Prettier（全 11+1 文件）
  curl /mes/sales/order/list → status 列含 _dictText
  curl /mes/sales/delivery/list → 同上
  curl /mes/sales/outbound/list → 同上
  Playwright 6 张截图：
    订单列表（含 statusTag 有色 tag）
    发货单列表、出库列表
    订单新增抽屉（Alert: "审核后自动生成发货单"）
    发货单新增抽屉（Alert: 含订单编码）
    出库新增抽屉（Alert: 含发货单编码）
```

---

## 七、总判定

| 标准 | 评分 | 说明 |
|------|:--:|------|
| 文件清单完整性 | ✅ | 13→14（+shared/statusColor.ts） |
| 依赖查证 | ⚠️ | R3 发现 @Dict 已带出编码，但草案未用到 |
| 状态机设计 | ✅ | 阶段映射方案正确，三模块分表 |
| 实施风险 | ⚠️ | 跳转按钮是范围外新功能，应独立 task |
| Alert 实现可行性 | ⚠️ | 需用 record._dictText 而非硬编码字符串 |
| 搜索 Schema 完整性 | ⚠️ | 发货单/出库缺关联单据下拉 |

**判定：NEEDS WORK — 5 项需调整后执行。无阻塞问题。**

| # | 调整项 | 影响 |
|---|--------|------|
| 1 | 文件计数修正：13→14（加 shared/statusColor.ts） | 低 |
| 2 | searchFormSchema 补关联单据下拉 | 中 |
| 3 | Alert 文案改用 record._dictText 响应式数据 | 中 |
| 4 | 页面跳转按钮降级为独立 task | 高 |
| 5 | getStatusColor 分模块映射表 | 低 |
