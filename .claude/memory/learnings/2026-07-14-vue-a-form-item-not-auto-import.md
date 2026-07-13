---
date: 2026-07-14
category: 前端
tags: [unplugin-vue-components, ant-design-vue, a-form-item, 自动导入]
---

# a-form-item 不会被 unplugin-vue-components 自动导入

## 触发条件
在 Vue 模板中使用 `<a-form-item>` 标签，组件完全不渲染，静默失败无报错。

## 根因
`unplugin-vue-components` + `AntDesignVueResolver` 只自动导入 Ant Design Vue 的**顶层组件**（如 `a-select`、`a-button`、`a-input`）。子组件（如 `a-form-item`、`a-tab-pane`）不会被自动导入，渲染时直接消失。

这和处理 `TabPane` 是一样的坑。

## 正确做法
**方案 A（推荐）：用纯 HTML 替代**
```html
<!-- ❌ 不渲染 -->
<a-form-item label="所属仓库">
  <a-select ... />
</a-form-item>

<!-- ✅ 正常渲染 -->
<div style="margin-bottom: 8px">
  <span>所属仓库：</span>
  <a-select ... />
</div>
```

**方案 B：显式导入**
```typescript
import { Form } from 'ant-design-vue';
// 模板用 <Form.Item> 而非 <a-form-item>
```

## JeecgBoot 标准做法
用 BasicForm + formSchema 渲染表单，避免直接在模板中使用 a-form-item。自定义控件放在 BasicForm 外面。
