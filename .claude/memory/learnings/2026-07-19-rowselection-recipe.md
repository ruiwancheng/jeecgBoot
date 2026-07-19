---
date: 2026-07-19
category: 前端组件
tags: [BasicTable, rowSelection, useListPage, checkbox, 批量操作]
---

# BasicTable rowSelection 复选框列的正确配置方法（绕过 useListPage 内部机制）

## 触发条件
需要在 JeecgBoot 列表页添加批量操作栏（勾选行→顶部出现批量按钮），使用 `useListPage` 的 `rowSelection` 机制，经历了 4 次提交尝试均失败。

## 根因
`useListPage` → `useListTable` 内部虽然创建了 `defaultRowSelection` 反应式对象，但 `delete defaultTableProps.rowSelection` 将其从传给 `useTable` 的 props 中移除。BasicTable 的 `useRowSelection` 从 props 读取 `rowSelection`，如果 props 中没有，checkbox 列不会渲染。同时 `columnSetting.vue` 的"行选择"开关需要手动在表格设置面板中勾选才能启用——不是默认打开的。

## 正确做法
完全绕过 `useListPage` 的内部机制，手动创建 reaction 对象并直接绑定在 BasicTable 上：

```typescript
// 手动创建选中状态
const selectedRowKeys = reactive<string[]>([]);
const selectedRows = reactive<Recordable[]>([]);

const rowSelection = {
  type: 'checkbox' as const,
  columnWidth: 50,
  selectedRowKeys,
  onChange(keys: string[], rows: Recordable[]) {
    selectedRowKeys.length = 0;
    selectedRowKeys.push(...keys);
    selectedRows.length = 0;
    selectedRows.push(...rows);
  },
};

// tableProps 中不需要配 rowSelection
// BasicTable 上直接绑定 :rowSelection="rowSelection"
```

注意：
- `useListPage` 的 `tableProps` 中**不要**配置 `rowSelection`
- `tableContext` 也**不要**解构第三个元素
- 直接用 `reactive([])` 而非 `ref([])` —— `onChange` 回调中 push 操作需要 reactive 才能触发模板更新
