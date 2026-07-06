---
name: gen-tests
description: 测试用例生成 — 根据后端 Controller 代码自动推导 API 测试和 E2E 测试用例。Generate test cases from backend Controller code.
---

# gen-tests — 测试用例自动推导

## Playwright 配置模板

```ts
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './e2e',
  timeout: 30000,
  use: { headless: true },
});
```

## 环境初始化命令

```bash
mkdir -p harness/tests harness/e2e
cd harness
[ ! -f package.json ] && npm init -y
npm install @playwright/test
```

## API 测试推导规则

| 接口注解 | 必测场景 |
|---------|---------|
| `@GetMapping` | 正常查询 + 空数据 |
| `@PostMapping` | 新增成功 + 必填字段缺失 |
| `@PutMapping` | 更新成功 + 记录不存在 |
| `@DeleteMapping` | 删除成功 + 删除后查不到 |
| 自定义接口 | 验证返回结果（code/result/message） |

## E2E 测试推导规则

| 页面类型 | 必测场景 |
|---------|---------|
| 列表页 | 页面正常加载 + 列头正确显示 |
| 搜索表单 | 各搜索字段可用 |
| 新增弹窗 | 打开弹窗 + 填写必填项 + 保存成功 |
| 编辑弹窗 | 点击编辑 + 修改字段 + 保存成功 |
| 删除 | 点击删除 + 确认弹窗 + 列表刷新 |

## 测试目录结构

- API 测试输出：`harness/tests/<项目名>/<功能名>.test.js`
- E2E 测试输出：`harness/e2e/<项目名>/<功能名>.spec.ts`

## 自定义规则合并逻辑

1. 读取 `.claude/rules/gen-tests-rules.json`
2. 按 `trigger` + `httpMethod` 匹配当前 Controller 方法
3. 命中则追加对应 `addCase`（`api` 和 `e2e`）到内置推导结果
4. 自定义规则优先于内置规则 — 相同的场景描述以自定义规则为准
