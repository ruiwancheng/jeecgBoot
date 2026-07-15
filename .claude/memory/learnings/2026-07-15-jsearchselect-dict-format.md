---
name: jsearchselect-dict-format
description: JSearchSelect 表字典配置用 dict: 'table,text,code' 合写格式，不是分立的 dictTable/dictText/dictCode
metadata:
  type: reference
---

# JSearchSelect 组件配置格式

## 问题

给 `JSearchSelect` 传了分立的 `dictTable`/`dictText`/`dictCode` 属性，选择器无数据，下拉框出不来。

```ts
// 错误 — 下拉无数据
{ component: 'JSearchSelect', componentProps: { dictTable: 'c_mes_material', dictText: 'name', dictCode: 'id' } }

// 正确 — dict 合写格式
{ component: 'JSearchSelect', componentProps: { dict: 'c_mes_material,name,id' } }
```

## 根因

`JSearchSelect` 组件只认 `dict` 属性（格式为 `table,text,code`），不是分立的三个属性。

## How to apply

formSchema 中需要从其他表搜索选择时：
- 物料：`dict: 'c_mes_material,name,id'`
- 客户：`dict: 'c_mes_customer,name,id'`
- 仓库：`dict: 'c_mes_warehouse,name,id'`

来源：价格模块前端选择器配置错误，服务端修复
