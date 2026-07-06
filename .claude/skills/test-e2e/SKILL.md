---
name: test-e2e
description: 端到端浏览器测试，模拟真实用户操作（登录、导航、表单填写），使用 Playwright。E2e browser testing with Playwright simulating real user flows.
---

# 端到端浏览器测试

## 测试文件命名

`harness/e2e/<项目名>/<功能名>.spec.ts`

## 运行命令

```bash
npx playwright test
```

## 错误诊断与修复映射表

| 报错类型 | 诊断方法 | 自动修复方案 |
|---------|---------|------------|
| 页面找不到（404） | 检查路由文件 `router/routes/modules/` 是否存在，组件路径是否正确 | 确保路由 path 与菜单 URL 一致，确保组件文件存在 |
| 输入框不存在 | 检查 `BasicTable` 组件渲染，`searchFormSchema` 配置 | 确认 formSchema 字段定义完整，组件 import 正确 |
| 按钮不可见 | 检查按钮权限配置和 `tableTitle` 模板 | 确认操作按钮在 columns 或 tableTitle 中定义，权限码匹配 |
| 登录失败 | 检查 Token key 和登录页面选择器 | 确认登录接口返回的 token 字段名，确认登录表单的 input 选择器 |
| 页面一直 loading | 检查 API 是否返回数据，表格配置是否正确 | 确认后端接口返回数据，确认 columns 的 dataIndex 与返回字段匹配 |

## JeecgBoot 特定组件引用

- 表格组件：`BasicTable`（来自 `/@/components/Table`）
- 搜索表单配置：`searchFormSchema`（在 `.data.ts` 中定义）
- 操作按钮模板：`tableTitle`（在 `index.vue` 中使用）

## 最大重试次数

3 次
