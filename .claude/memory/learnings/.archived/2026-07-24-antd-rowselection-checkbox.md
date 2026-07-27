# [2026-07-24] [Vue/AntDesign] useListPage 的 rowSelection 需显式绑定且用 reactive 非 ref

## 触发条件
采购申请页面配置了 `rowSelection: { type: 'checkbox' }` 但表格不显示复选框。

## 根因
两层问题：
1. `useListPage` 内部 delete 了 `rowSelection` 再返回，必须手动 `:rowSelection` 绑定到 BasicTable
2. `selectedRowKeys` 用 `ref<string[]>([])` 时报错——antd 的 rowSelection 需要原生数组，`ref` 包裹了一层

## 处理方式
```typescript
// ❌ 错误
const selectedRowKeys = ref<string[]>([]);
const rowSelection = { selectedRowKeys, onChange: (keys) => { selectedRowKeys.value = keys; } };

// ✅ 正确
const selectedRowKeys = reactive<string[]>([]);
const rowSelection = { selectedRowKeys, onChange: (keys) => { selectedRowKeys.length = 0; selectedRowKeys.push(...keys); } };
// 模板：<BasicTable :rowSelection="rowSelection">
```

## 关联
- 参照：销售订单 index.vue 的正确写法
- `reactive` 数组清空用 `.length = 0`，不能用 `= []`
