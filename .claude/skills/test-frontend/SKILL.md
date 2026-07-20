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

## 组件引用验证增强（Graph Component Reference Check）

使用 code-review-graph MCP 工具验证组件引用完整性，替代手动检查。

### 调用参数

| 步骤 | 工具 | 参数 | 用途 |
|------|------|------|------|
| 1. 导入验证 | `query_graph_tool` | `pattern="imports_of"`, `target="<页面文件>"` | 验证页面所有 import 的文件真实存在 |
| 2. 组件搜索 | `semantic_search_nodes_tool` | `query="<组件名>"`, `kind="File"` | 确认引用的组件文件在代码库中 |

### 判定规则

| 条件 | 动作 |
|------|------|
| import 路径在图谱中有对应节点 | ✓ 通过 |
| import 路径在图谱中找不到 | ✗ 标记"组件引用可能失效" |
| 路由 component 路径无对应文件 | ✗ 标记"路由指向的文件不存在" |

### 降级策略

图谱不可用 → 标准文件系统检查（`ls` 验证路径）
