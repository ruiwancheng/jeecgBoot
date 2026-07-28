---
name: testing
description: 测试标准——关键业务流 100% 覆盖 + 新模块三件套 + 5 断言锚点
glob: "**/*.test.*,**/*.spec.*"
version: 2.0
---

# 测试标准 v2（2026-07-29 重构，orca-review 定稿）

> 历史教训：盘点单交付时 API 14/14 + E2E 12/12 全绿，人工测试仍发现 4 个 bug（显示ID/payload形状/审核未生效/明细过多）。
> 根因：测试不在关键路径、金字塔错位（API强E2E弱渲染零）、环境脆弱失信。v2 对症下药。

## L0：规则（必须遵守）

### 覆盖目标：关键业务流 100%（不是行覆盖率）

- 每个业务链路在 `hermes/business-chains.json` 注册 `criticalPaths`，**只增不减**
- `/deploy-verify` 逐路径验证，遗漏路径 → WARN

### 新模块交付三件套（/plan 固定一栏，缺一则不算完成）

1. **API 业务流测试** `harness/tests/<项目>/<模块>.test.js`（创建→审核→状态→副作用）
2. **1 条 E2E 完整业务流** `harness/e2e/<项目>/<模块>.spec.ts`（创建→编辑→审核→结果页，用 helpers/auth 登录）
3. **关键 payload 从浏览器 DevTools 抓包保真**（禁止手工想象构造）

### 5 断言锚点（每个模块测试必含，防水测试）

| # | 锚点 | 示例 |
|---|------|------|
| 1 | 创建断言 | code 非空 + status='1' |
| 2 | 状态流转断言 | 草稿→审核→已审核 + 审核后不可编辑/删除 |
| 3 | 数据传递断言 | 审核后库存变化量 = 申报量 |
| 4 | **显示值断言** | 物料列显示编码/名称（如 `MAT-` 前缀），**裸 ID 判负** |
| 5 | 清理断言 | 测试后无残留（fixture 唯一编码 + 清理） |

### 工具规范

- **登录**：统一 `harness/e2e/mes/helpers/auth.ts` 的 `loginViaApi(page, path?)`（token 双层包装注入），禁止各 spec 重复写注入逻辑、禁止 UI 填验证码
- **共享 helper**：`harness/tests/helpers/api.js`（client+断言带根因输出）+ `fixtures.js`（建仓/料/供应商/期初/清理）
- **清理**：优先 API 清理；DB 清理必须走 SQL 文件（fixtures.dbCleanup），**禁止 execSync 内联 mysql 命令**（Windows 引号必炸）
- **唯一编码**：所有 fixture 用时间戳后缀，测试必须可重复运行（幂等）
- API 测试需 `enableLoginCaptcha: false` 或直接用 mes_admin token

## L1：模板

- API 测试模板：参考 `harness/tests/mes/stocktake.test.js`（14 场景：快照/盘亏/盘盈/守卫/回写）
- 链路测试模板：参考 `harness/tests/mes/purchase-apply-order.chain.test.js`（helper 版）
- E2E 模板：参考 `harness/e2e/mes/other-stock-in.spec.ts`

## L2：实践案例（4 bug × 4 盲区，2026-07-28）

| Bug | 盲区 | 对策 |
|-----|------|------|
| 物料显示 ID | API 测试只断数值不断显示值 | 锚点 #4 显示值断言 |
| 账面数取值有误 | payload 手工想象 ≠ 前端真实形状 | 三件套 #3 抓包保真 |
| 审核未生效 | 无 E2E 完整业务流 | 三件套 #2 |
| 明细过多（UX） | 自动化测不出 UX 权衡 | plan 阶段 UX 决策点显式化 |

## Bug 反哺 gen-tests 推导规则

```
Bug修复 → /debug 分析根因 → 判断gen-tests是否漏了此类场景
  → 是：询问用户确认 → 追加规则到 .claude/rules/gen-tests-rules.json
  → 否（架构/环境问题）：记录到 learnings/
```

规则存储：`.claude/rules/gen-tests-rules.json`，内置规则 + 自定义规则合并，自定义优先。
