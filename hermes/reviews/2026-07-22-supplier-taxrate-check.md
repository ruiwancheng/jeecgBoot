# 采购订单列表 — 供应商列 & 税率列检查报告

> 检查时间：2026-07-22 | 检查范围：只读 | 涉及文件：4 个

---

## 1. 供应商列 ✅ 正常

### 前端（列表列定义）

**文件：** `jeecgboot-vue3/src/views/project/mes/purchase/order/order.data.ts`

```ts
{ title: '供应商', dataIndex: 'supplierId_dictText', width: 150 },
```

- 列 `dataIndex` 使用 `supplierId_dictText`，符合 JeecgBoot 字典翻译机制。
- 表单中供应商使用 `ApiSelect`（API：`querySupplierSelect`），组件存入 `supplierId`，后端返回时字典切面自动追加 `supplierId_dictText` 翻译字段。

### 后端（实体字典注解）

**文件：** `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/purchase/order/entity/MesPurchaseOrder.java`

```java
@Dict(dictTable = "c_mes_supplier", dicText = "name", dicCode = "id")
private String supplierId;
```

- 注解配置：查 `c_mes_supplier` 表，取 `name` 字段作为显示文本。
- 与前端 `supplierId_dictText` 完全对号入座。

### 合规检查

| 规则 | 状态 |
|------|:--:|
| 禁止 `JSearchSelect` + `dict="c_mes_*"` 模式 | ✅ 使用 `ApiSelect` |
| `dataIndex` 与字典翻译后缀一致 | ✅ `supplierId_dictText` |
| 字典注解 `@Dict` 与前端 `_dictText` 匹配 | ✅ |

**结论：供应商列显示正常，无需修改。**

---

## 2. 税率列 ⚠️ 需要确认需求

### 当前前端列表

**文件：** `jeecgboot-vue3/src/views/project/mes/purchase/order/order.data.ts`

```ts
export const columns: BasicColumn[] = [
  // ...
  { title: '不含税金额', dataIndex: 'totalAmount', width: 100 },
  { title: '含税总额', dataIndex: 'totalWithTax', width: 100 },
  // ...
];
```

**现象：列表有"不含税金额"和"含税总额"，但没有"税率"列和"税额"列。**

### 后端实体字段

**采购订单头部** (`MesPurchaseOrder.java`)：

| 字段 | Java 类型 | 说明 | 前端是否展示 |
|------|-----------|------|:--:|
| `totalAmount` | BigDecimal | 不含税金额 | ✅ |
| `taxAmount` | BigDecimal | 税额 | ❌ 未展示 |
| `totalWithTax` | BigDecimal | 含税总额 | ✅ |
| (无 taxRate) | — | 税率不在头部 | — |

**采购订单行** (`MesPurchaseOrderItem.java`)：

| 字段 | Java 类型 | 说明 |
|------|-----------|------|
| `taxRate` | BigDecimal | 税率（行级） |

### 关键结论

1. **税率(`taxRate`)在行项目上，不在订单头部。** 列表页展示的是订单头部的汇总数据，不展示行级税率是合理的。

2. **税额(`taxAmount`)在订单头部有字段，但前端列表没有显示。** 如果业务需要展示，可以直接加一列即可，无需改后端：
   ```ts
   { title: '税额', dataIndex: 'taxAmount', width: 80 },
   ```

3. 当前展示逻辑是自洽的：`totalAmount`(不含税) + `taxAmount`(税额) = `totalWithTax`(含税)，只是缺了中间的 `taxAmount` 列。

### 对比：销售订单

**文件：** `jeecgboot-vue3/src/views/project/mes/sales/order/order.data.ts`

销售订单列表**完全没有税率相关列**（无 taxRate、无 taxAmount、无 totalWithTax），只有一个 `totalAmount`。后端 `MesSalesOrder.java` 实体也没有 `taxAmount` / `taxRate` 字段。

结论：销售订单不可作为"带税率的列定义"参考——它自己就没有税率体系。

---

## 3. 总结

| 检查项 | 状态 | 说明 |
|--------|:--:|------|
| 供应商列 `supplierId_dictText` | ✅ 正常 | ApiSelect + 字典翻译，完全正确 |
| 税率列 `taxRate` | ⚠️ 不适用 | 税率在行项目上，头部列表不展示是合理的 |
| 税额列 `taxAmount` | 💡 可优化 | 后端有字段，前端可选择性展示 |
| 含税总额 `totalWithTax` | ✅ 正常 | 已展示 |

**建议：如果业务要求在采购订单列表展示税额，加一列 `{ title: '税额', dataIndex: 'taxAmount', width: 80 }` 即可，零后端改动。税率本身不适合在订单列表展示（它在行项目上），应在订单详情/行项目列表里展示。**
