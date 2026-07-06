---
name: frontend
description: 前端组件规范——表单、表格、路由、字典
glob: "**/*.{vue,ts}"
version: 1.0
---

# 前端组件规范

## 页面结构
- 列表页：`<BasicTable>` + `useListPage` Hook
- 详情/编辑：`BasicDrawer` + `BasicForm`
- 搜索：`searchFormSchema` 在 `.data.ts` 定义
- **Hook 配对：** `BasicDrawer` → `useDrawer()`，`BasicModal` → `useModal()`。混用会报 `setModalProps is not a function` 错误

## 表单
- 搜索区：3-4 字段一行（`span: 6`）
- 详情区：2 列布局
- 必填字段 `required: true`

## 字典
- 平台字典：`JDictSelectTag` + `dictCode`
- 表字典：`@Dict(dictTable, dicText, dicCode)`

## 路由
- 一级菜单 `LAYOUT` + `redirect`
- 子页面懒加载 `() => import('/@/views/...')`
- 项目页面加前缀 `/project/{项目名}/`

## 路由匹配
- 数据库菜单 url 和前端路由 path 必须一致
- **层级必须对应：** 数据库菜单中每一层 `component=layouts/default/index` 的父级，前端路由必须有一层 `component: LAYOUT` + `children` 对应。缺失中间层会报"路径不存在"404
- 新增 Vue 组件后必须重启 Vite（`import.meta.glob` 缓存）

## 接口
- `defHttp.get/post/put/delete`
- DELETE 请求必须加 `{ joinParamsToUrl: true }`，否则参数在请求体，后端 `@RequestParam` 收不到
- 路径枚举在 `.api.ts`
