# 其它出库页面 — 黄金模板优化方案评审

> 评审日期：2026-07-30 | 评审对象：pi 草案（其它出库/入库 UX 对齐黄金模板）
> 判定：**PASS**（4 项需调整，无阻塞）

---

## 一、架构/实施可行性

**结论：可行。文件清单完整，依赖已查证。**

对比黄金模板 `harness/templates/mes-doc-page/master-detail` v1.0.0 与实际代码，现有页面已完成 9/10 模式，仅缺：

| 缺失项 | 影响文件 |
|--------|---------|
| statusTag 槽位（列表页状态 tag 渲染） | `index.vue` + `.data.ts`（4 文件） |
| 模式 8 Alert（抽屉顶部口径提示） | `Drawer.vue`（2 文件） |
| `@generated-from` 溯源注释 | 全部 8 文件 |

**文件清单准确，遗漏为 0。**

### ⚠️ 需调整项 #1：`.data.ts` 状态列改造方案不完整

草案说"status 列改用 statusTag 槽位"，但未说明具体代码变化。实际两步不可拆：

1. **列定义**：`{ dataIndex: 'status_dictText', width: 80 }` → `{ dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } }`
   - `dataIndex` 从 `status_dictText` 改为 `status`（槽位接收原始值 `'1'` / `'2'`）
   - 字典翻译 `_dictText` 字段不再用于表格列，改为模板内 `record.status_dictText` 取值
2. **模板**：`index.vue` 加 `<template #statusTag="{ record }">` 槽位，渲染 `<a-tag>`

如果只改槽位不改 dataIndex，tag 拿到的是"草稿"/"已审核"字符串而非 `'1'`/`'2'`，颜色判定失效 → 所有 tag 同色。

---

## 二、pi 拿不准的 6 个问题——逐项回答

### Q1: 状态 tag 颜色映射

**当前草案**：`status === '2' ? 'green' : 'orange'`

**评审结论：可行，无需修改。**

- 字典值 `1=草稿` / `2=已审核`，绿/橙与模板一致，对比度足够
- 已验证 `c_mes_other_stock_in/out` 主表 status 列是 `VARCHAR`，`'2'` 比较正确
- 柔和色（如 `#87d068`）反而会让"草稿"和"已审核"区分度下降

### Q2: Alert 文案差异化

**评审结论：入库/出库应该差异化。**

| 页面 | 推荐文案 |
|------|---------|
| 其它出库 OtherOutDrawer | `成本按移动平均预填，可手工修改。确认后库存减少。` |
| 其它入库 OtherInDrawer | `成本按移动平均预填，可手工修改。入库后库存增加。` |

原因：两类操作对库存的影响相反，出库业务人员需要明确"会减少"以防误操作。加一句 7 个字，成本为零。

### Q3: 修改顺序

**评审结论：按维度切，不要按页面切。**

```jsonc
// 顺序：data.ts → index.vue → drawer.vue → subtable.vue（姐妹页并行改同维度）
Step 1: otherOut.data.ts + otherIn.data.ts  // status 列改造（同模式）
Step 2: otherOut/index.vue + otherIn/index.vue  // statusTag 槽位 + @generated-from
Step 3: OtherOutDrawer.vue + OtherInDrawer.vue  // a-alert 模式 8 + @generated-from
Step 4: 2 个 ItemsSubTable.vue  // @generated-from 注释
```

收益：Step 1 两文件几乎一模一样（差 inType/outType），并列改可互校；改完后立即验证列表页颜色效果。

### Q4: 遗漏的 UI 细节

**抽屉宽度 1000px — ✅ 够用，不改。** 明细 5 列（物料 240 + 数量 110 + 单价 130 + 金额 110 + 操作 70）= 660px，基础信息 3 列 span:8 = ~550px。1000px 有 15% 余量。

**批量添加去重 — ✅ 不改，但加注释。** 批量添加后重复物料出现在两行，用户可手动删除。当前数据量下不是 UX 瓶颈。在 `handleBatchAddMaterials` 上方加 `// 批量添加不自动去重——操作员可手工删除多余行`。

**保存后清空 — ✅ 已处理。** 抽屉有 `destroyOnClose`（line 2），关闭后组件销毁重建，不会残留旧数据。

### Q5: statusTag 槽位 + status_dictText 共存

**评审结论：不冲突，模板写法正确处理。**

模板 `index.vue.template` line 18：
```html
<a-tag :color="record.status === '2' ? 'green' : 'orange'">
  {{ record.status_dictText || (record.status === '2' ? '已审核' : '草稿') }}
</a-tag>
```

逻辑链：优先取字典翻译 `record.status_dictText`（后端 join 填充）；如果字典未加载则 fallback 到硬编码字符串。两套不会同时出现——`status_dictText` 存在就用它，不存在才 fallback。列定义中 `dataIndex: 'status'` 传给槽位的 record 仍包含 `status_dictText`（queryAll 返回了它），槽位内可正常访问。

### Q6: @generated-from 注释格式

**评审结论：分文件类型。**

| 文件类型 | 格式 | 位置 |
|---------|------|------|
| `.vue` 文件 | `<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->` | 文件第一行（`<template>` 之前） |
| `.ts` 文件 | `// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0` | 文件第二行（import 之后） |

来源依据：模板 README line 47-49 明确写明用 `<!-- ... -->` HTML 注释格式。TS 文件不能用 HTML 注释语法，用 JS 单行注释替代。

---

## 三、姊妹页一致性审查

**出库 4 文件 vs 入库 4 文件对比：**

| 维度 | other-out | other-in | 对称？ |
|------|-----------|----------|:--:|
| index.vue 结构 | BasicTable + rowSelection + batchAudit/Unaudit | 同 | ✅ |
| data.ts columns | outType_dictText / warehouseId_dictText / status_dictText | inType_dictText / warehouseId_dictText / status_dictText | ✅ |
| data.ts searchForm | code + outType + status | code + inType + status | ✅ |
| data.ts formSchema | code + outType + warehouseId + stockDate + reason + status + remark | code + inType + warehouseId + stockDate + reason + status + remark | ✅ |
| Drawer 自动编码 | `MES_BIZ_CODE.OTHER_STOCK_OUT` | `MES_BIZ_CODE.OTHER_STOCK_IN` | ✅ |
| Drawer 明细列 | materialId/qty/unitCost/amount/action | 同 | ✅ |
| ItemsSubTable | material/spec/qty/unitCost/amount | 同 | ✅ |
| api.ts | import 了 queryLocationSelect？ | **otherIn 有 queryLocationSelect (line 14)，otherOut 没有** | ⚠️ |

### ⚠️ 需调整项 #2：otherIn.api.ts 有 queryLocationSelect 但未使用

`otherIn.api.ts` line 14 定义了一个 `queryLocationSelect` 导出，但在 `otherIn.data.ts` 中并未 import 此函数。这是一个**死导出**——otherIn 的 formSchema 只有 `ApiSelect + queryWarehouseSelect`，没有库位选择器。

**处理建议**：本任务范围外（清理死代码），但应记录到技术债列表。不要在对齐优化中顺手删除——后续可能有库位功能需求。

---

## 四、潜在 bug 排查

### 🔍 已排查，无问题

| 检查项 | 结果 | 说明 |
|--------|:--:|------|
| 空值保护 — status undefined | ✅ | 模板 `status === '2'` 的 else 分支 cover 了空值 → fallback 到 `'草稿'` + orange |
| 状态守卫 — batchAudit disabled | ✅ | `allStatus` computed 用 `every()` 校验全选同状态，没有全选时返回 `''` → 按钮 disabled |
| 保存后清空 | ✅ | `destroyOnClose` 确保抽屉关闭后组件销毁 |
| 并发重复点击 | ✅ | `confirmLoading` 在 handleSubmit 中设置，finally 中恢复 |
| 明细空行拦截 | ⚠️ | `addLine` 允许加空行，提交时后端校验会拒绝。前端不主动拦截不算 bug，但算体验欠佳——建议记录为 P3 |

### 🔍 发现一个真实问题

### ⚠️ 需调整项 #3：otherIn.data.ts 有 searchFormSchema warehouseId 但未添加

两个 data.ts 的 searchFormSchema 都只有 code + type + status 三个搜索字段，**都没有仓库下拉**。但黄金模板 UX 基线要求 "搜索栏涉及仓库的有 ApiSelect 下拉"（`frontend.md` line 101）。当前 other-in/other-out 的搜索区缺少仓库筛选——这是模板对齐中的遗漏。

**是否本次修复**：可做为独立 task。本任务聚焦黄金模板 10 模式对齐，仓库搜索是 UX 基线清单（frontend.md line 101）的要求，属于额外改进。

### ⚠️ 需调整项 #4：ItemsSubTable 的 spec 列逻辑有缺陷

```typescript
// OtherOutItemsSubTable.vue line 51
items.value = items.value.map((i) => ({ ...i, spec: map[i.materialId]?.spec || '-' }));
```

当物料查询失败时 `spec` 为 `'-'`，但 `map[i.materialId]` 不存在时 `map[i.materialId]?.spec` 为 undefined，`|| '-'` 正确兜底。✅

**但存在时序问题**：`items.value.map()` 被调用在 `materialMap.value = map` **之后**（同一次 try 内），但如果 `Promise.all` 中某个物料查询失败返回 null，不影响其他物料——catch 为 null，map 中缺这个 key，spec 显示 `'-'`。✅ 正确。

**真正的问题**：`cols` 中 spec 列 dataIndex 为 `'spec'`，但后端返回的 item 对象不一定有 `spec` 字段——`spec` 是前端在 `onMounted` 中追加的。展开行首次渲染时 items 是先 set 的（`items.value = doc?.items || []`），此时 spec 尚未追加，短暂显示空白。不过由于后续 `items.value = items.value.map(...)` 会触发响应式更新，最终会正确显示。✅ 可接受。

---

## 五、实施风险评估

| 风险 | 等级 | 缓解 |
|------|:--:|------|
| status 列 dataIndex 改错导致列表页状态列空白 | 低 | 改完 data.ts 后立即 curl `/mes/stock/otherOut/list` 验证返回含 `status_dictText` |
| `@generated-from` 注释格式写错 | 极低 | 逐文件对照本文结论 |
| 姐妹页改不对称 | 低 | 按维度切步骤，每步改完出库→复制到入库→调类型字段 |
| Alert 文案差异化后入库/出库不对称 | 极低 | 两行不同的 alertText 值 |

**整体风险评估：低。** 改动是纯前端 UI 对齐，不改后端、不改接口、不改数据流。最坏情况是 tag 颜色不对——刷新页面即可发现。

---

## 六、改进的实施方案

```jsonc
// Step 1: data.ts（姐妹页并行）
otherOut.data.ts:
  - columns[6]: { dataIndex: 'status_dictText', width: 80 }
    → { dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } }
  - 文件顶部加 // @generated-from 注释
otherIn.data.ts:
  - 同上（改 inType_dictText 对应的 status_dictText 列）
  - 文件顶部加 // @generated-from 注释

// Step 2: index.vue（姐妹页并行）
otherOut/index.vue:
  - <BasicTable> 和 <template #action> 之间加 statusTag 槽位
  - 文件第一行加 <!-- @generated-from -->
otherIn/index.vue:
  - 同上

// Step 3: Drawer.vue（姐妹页并行）
OtherOutDrawer.vue:
  - BasicForm 和 a-divider 之间加 <a-alert>（文案含"库存减少"）
  - script 中加 const alertText = ref('成本按移动平均预填，可手工修改。确认后库存减少。')
  - 文件第一行加 <!-- @generated-from -->
OtherInDrawer.vue:
  - 同上（文案改为"入库后库存增加"）
  - 文件第一行加 <!-- @generated-from -->

// Step 4: ItemsSubTable.vue（姐妹页并行）
OtherOutItemsSubTable.vue:
  - 文件第一行加 <!-- @generated-from -->
OtherInItemsSubTable.vue:
  - 文件第一行加 <!-- @generated-from -->

// Step 5: 验证（并行）
curl /mes/stock/otherOut/list → 验证 status 列含 status_dictText
curl /mes/stock/otherIn/list  → 同上
Playwright 截图 other-out 列表页 → status 列显示有色 tag
Playwright 截图 other-in 列表页 → 同上
Playwright 截图 新增抽屉 → Alert 显示
```

---

## 七、总判定

| 标准 | 评分 |
|------|:--:|
| 文件清单完整性 | ✅ 8/8 |
| 依赖查证 | ✅ 后端/SQL/菜单均已完成 |
| 实施风险 | ✅ 低（纯 UI） |
| 姊妹页对称性 | ✅ 等高 |
| pi 6 问全部解答 | ✅ |
| 需调整项 | ⚠️ 4 项（非阻塞） |

**判定：PASS — 4 项需调整后执行。无阻塞问题。**
