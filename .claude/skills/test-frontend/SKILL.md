---
name: test-frontend
description: 前端静态检查，验证组件完整性、路由正确性、TypeScript 类型和构建是否通过。Frontend static check: component integrity, routes, TypeScript types, and build.
---

# 前端静态检查

## 组件完整性检查

- `index.vue` 中 import 的 Drawer/Modal/子组件文件必须存在
- `.api.ts` 接口路径格式：`/jeecg-boot/<模块>/<路径>`，使用 `defHttp.get/post/put/delete`
- `.data.ts` 的 `columns` 定义表格列，`formSchema` 定义表单字段结构

## 路由检查

- 前端路由目录：`router/routes/modules/`
- 路由文件指向的 `component: () => import('/@/views/...')` 路径必须真实存在

## TypeScript 类型检查命令

```bash
cd jeecgboot-vue3 && npx vue-tsc --noEmit 2>&1 | head -30
```

## 构建验证命令

```bash
cd jeecgboot-vue3 && pnpm build 2>&1 | tail -5
```

## 输出格式

每项检查显示 ✓（通过）或 ✗（失败），失败时列出具体文件名和原因。
