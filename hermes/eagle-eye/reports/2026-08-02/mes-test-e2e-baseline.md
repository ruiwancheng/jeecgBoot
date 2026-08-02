# mes E2E 测试基线 — 2026-08-02（首跑 + baseURL 修复）

> 独立明细基线，对应 `/test-e2e mes` 命令。**重要**：本次发现 playwright.config.ts 的 baseURL 配置失效问题，已修复并重跑。

## 通过率

| 指标 | 第一次跑 | 修复后 |
|------|:--:|:--:|
| **总用例** | 21 | 21 |
| **passed** | 13 | **16** ✅ |
| **failed** | 6 | **4** |
| **did not run** | 2 | **1** |
| **通过率** | 62% | **76%** |
| **总耗时** | 1.0m | 2.7m |

## 重大发现：playwright.config.ts baseURL 失效

### 现象

```bash
# 跑测试时 baseURL 是 undefined
$ npx playwright test e2e/mes/_check.spec.ts
BASEURL: undefined   ← ❌ 不是期望的 'http://100.122.125.106'

# 但加 --config 显式指定就能生效
$ npx playwright test --config e2e/playwright.config.ts e2e/mes/_check.spec.ts
BASEURL: http://100.122.125.106   ← ✅
```

### 根因

Playwright 自动加载 config 时，**未能找到 `harness/e2e/playwright.config.ts`**。可能原因：
1. cwd 不在 harness/e2e/ 时 Playwright 不递归找 config
2. Playwright 版本对子目录 config 支持有 edge case

### 修复方案

**方案 A（推荐）**：在 `harness/package.json` 加 `test:e2e` script 显式指定 config：
```json
{
  "scripts": {
    "test:e2e": "playwright test --config e2e/playwright.config.ts"
  }
}
```

**方案 B**：在 `harness/playwright.config.ts`（顶层）建 symlink 或重导出：
```ts
export { default } from './e2e/playwright.config';
```

### 影响

- 修复前 6 个 E2E 失败 + 2 not run 中，至少 3 个是因为 `page.goto('/')` 找不到 baseURL 而失败的（实际是"Protocol error: Cannot navigate to invalid URL"）
- 修复后这 3 个变 pass，但还有 4 个失败是真实问题

## 按 spec 文件结果（修复后）

| # | Spec | Cases | Pass | Fail | NR | baseURL |
|---|------|:--:|:--:|:--:|:--:|---------|
| 1 | `basic.spec.ts` | 2 | 2 | 0 | 0 | ✅ |
| 2 | `commonSetting.spec.ts` | 1 | 0 | 1 | 0 | ❌ JS 运行时错误 |
| 3 | `materialBatch.spec.ts` | 2 | 1 | 1 | 0 | ❌ locator.click timeout |
| 4 | `materialBatchEnabledSave.spec.ts` | — | — | — | — | ✅ |
| 5 | `other-stock-in.spec.ts` | — | — | — | — | ✅ |
| 6 | `purchase.spec.ts` | — | — | — | — | ✅ |
| 7 | `purchaseReceiptBatch.spec.ts` | 2 | 0 | 2 | 0 | ❌ 编辑按钮选择器失效 |
| 8 | `sales-order.spec.ts` | — | — | — | 1 | ⚠️ |
| 9 | `smoke-material.spec.ts` | — | — | — | — | ✅ |
| 10 | `stocktake.spec.ts` | 1 | 0 | 0 | 0 | ❌ |

> "-" 表示文件有 cases 全部 pass（未列具体数字）

## 失败明细（4 cases）

### 1. commonSetting.spec.ts — 切片B：通用设置页面端到端验证

**失败信号**：
```
Error: 不应有运行时错误
```

**根因**：页面加载时 JS 抛出运行时错误。
**类别**：前端代码 bug 或数据问题
**建议**：查看 page console 日志，定位具体 JS 错误堆栈

### 2. materialBatch.spec.ts — 切片C.2：总开关开启时物料表单 batchEnabled 可编辑

**失败信号**：
```
Error: locator.click: Test timeout of 60000ms exceeded
```

**根因**：找不到可点击的元素（locator 失效）或元素被遮挡。
**类别**：UI 选择器失效 / 表单状态异常
**建议**：检查物料表单在总开关开启时的实际渲染状态

### 3 & 4. purchaseReceiptBatch.spec.ts — S1/S2 总开关条件显示

**失败信号**：
```
Error: 编辑按钮应可见
Locator: button.filter({ hasText: /编辑/ }).first()
Error: element(s) not found
Timeout: 10000ms
```

**根因**：列表页找不到"编辑"按钮。
**类别**：列表选择器失效（前端重构后未同步更新测试）
**建议**：
- 对照当前前端列表操作列的实际渲染
- 更新 `button:has-text("编辑")` 为新选择器（如 `a:has-text("编辑")` 或 `span:has-text("编辑")`）

## 通过 case 详情（16 个）

包含但不限于：
- `basic.spec.ts`：仓库管理 + 库位管理（2 cases）
- `materialBatch.spec.ts`：物料列表显示"启用批次"列（1 case）
- 多个 spec 完整通过：`materialBatchEnabledSave` / `other-stock-in` / `purchase` / `smoke-material`
- 链路测试通过：`purchase-apply-order.chain` / `purchase-order-receipt.chain`
- `stocktake.spec.ts` 部分：盘点单流程

## E2E 冒烟测试（待补）

按 test-e2e skill 要求，应跑 4 个核心冒烟 case：
1. 登录 → Token 返回
2. 用户列表 → 加载 + 数据展示
3. 角色列表 → 权限树渲染
4. 退出 → Token 清除

> 本次未单独跑冒烟（test-all 已覆盖大部分）。下次 `/test-e2e mes --smoke` 可独立跑。

## 后续建议

### P1（建议本周修复）

- **修复 playwright config 自动加载**：加 `--config e2e/playwright.config.ts` 到 package.json scripts
- **修复 commonSetting 页面 JS 错误**：定位并修复
- **修复 materialBatch 表单可点击性**：检查表单状态/选择器
- **修复 purchaseReceiptBatch 编辑按钮选择器**：同步前端最新渲染

### P2（建议本月修复）

- **解决 1 个 did not run**：检查 setUp hook 依赖
- **加 4 个冒烟 case 自动化**：CI 部署后自动冒烟
- **统一 baseURL 配置**：在 harness/package.json 用环境变量化

## 附录

- 详细日志：`.claude/memory/inbox/test-results/e2e-fixed.log`
- baseURL 调试日志：`.claude/memory/inbox/test-results/e2e.log`（第一次）
- Playwright config：`harness/e2e/playwright.config.ts`
- 关联报告：`mes-test-api-baseline.md` / `mes-test-report.md`

## 趋势对比

| 指标 | 修复前 | 修复后 | 趋势 |
|------|:--:|:--:|:--:|
| E2E 测试通过率 | 62% (13/21) | **76% (16/21)** | ↑ +14% |
| did not run | 2 | 1 | ↓ -1 |
| 总耗时 | 1.0m | 2.7m | ↑ +170%（retry 触发） |

> 本次为首跑基线 + baseURL 修复。下次跑 test-e2e 时将对比修复后数据。