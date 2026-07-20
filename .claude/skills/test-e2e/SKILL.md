---
name: test-e2e
description: 端到端浏览器测试，模拟真实用户操作（登录、导航、表单填写），使用 Playwright。E2e browser testing with Playwright simulating real user flows.
version: 1.0.0
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

## 冒烟测试集（Smoke Test Suite）

部署后必跑的轻量级冒烟测试，覆盖核心用户流程，秒级出结果。

### 核心用例

| # | 流程 | 验证点 | 通过标准 |
|---|------|--------|----------|
| 1 | 登录 | 登录接口返回 Token | HTTP 200, `code=200`, `result.token` 非空 |
| 2 | 用户列表 | 列表加载 + 数据展示 | HTTP 200, `result.records` 长度 > 0 |
| 3 | 角色列表 | 权限树渲染 | HTTP 200, 无 JS Error |
| 4 | 退出 | Token 清除 | HTTP 200, 重定向到登录页 |

### 运行命令

```bash
npx playwright test harness/e2e/smoke/ --reporter=html
```

### 部署后自动冒烟（Orca 自动化）

每 5 分钟检查部署状态，部署成功后自动冒烟：

```bash
orca automations create \
  --cron "3 * * * *" \
  --prompt "检查最近一次部署是否成功。如果成功，运行 /test-e2e 冒烟测试集（4 核心用例），结果输出到 hermes/eagle-eye/reports/$(date +%Y-%m-%d)/smoke-test.md。如果冒烟失败率 > 20%，标记为 P0 告警。" \
  --recurring true \
  --durable true \
  --description "每小时检查部署状态，成功后自动冒烟"
```

### 冒烟失败判定

| 失败率 | 级别 | 动作 |
|:--:|:--:|------|
| 0% | ✅ | 部署正常 |
| ≤20% (1/4) | ⚠️ | 标记 P2，记录到报告 |
| >20% (≥2/4) | 🔴 | P0 告警，阻止后续部署 |

> 降级策略：Orca 不可用 → 手动运行 `npx playwright test harness/e2e/smoke/`

## 流程覆盖增强（Flow Coverage Enhancement）

使用 code-review-graph MCP 工具确保 E2E 测试覆盖受影响的用户流程。

### 调用参数

| 步骤 | 工具 | 参数 | 用途 |
|------|------|------|------|
| 1. 受影响流 | `get_affected_flows_tool` | 使用 HEAD~1 变更 | 列出受影响的用户可见功能 |
| 2. 页面追踪 | `query_graph_tool` | `pattern="importers_of"`, `target="<变更的API>"` | 找到引用了变更 API 的前端页面 |

### 判定规则

| 条件 | 动作 |
|------|------|
| 变更影响了 N 条执行流 | 确保 E2E 测试覆盖所有受影响的流 |
| API 变更影响了前端页面 | 对受影响页面追加 E2E 测试 |
| 无执行流受影响 | 仅跑已有 E2E 测试 |

### 降级策略

图谱不可用 → 标准 E2E 流程

## Orca Browser 可视化调试（推荐）

当 E2E 测试失败需要可视化调试时，使用 Orca Browser 替代 headless Playwright：

```bash
# 在 Orca Browser 中打开测试页面
orca goto --url http://localhost:3100

# 执行登录流程（可视化验证）
orca fill --element e5 --value "admin"
orca fill --element e7 --value "123456"
orca click --element e10

# 截图保存为测试证据
orca snapshot --format png
```

### Playwright vs Orca Browser 分工

| 场景 | 推荐工具 | 原因 |
|------|---------|------|
| CI/自动化批量回归 | Playwright headless | 快速、可并行、可脚本化 |
| 本地调试失败用例 | Orca Browser | 可视可交互、即时截图 |
| 生成测试证据 | Orca Browser snapshot | 真实浏览器渲染截图 |
| 全量 E2E 运行 | Playwright headless | 批量执行、报告自动化 |

> 降级策略：Orca 不可用时 → `npx playwright test --headed` 进行可视化调试。
