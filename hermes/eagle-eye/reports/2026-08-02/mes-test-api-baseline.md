# mes API 测试基线 — 2026-08-02（首跑）

> 独立明细基线，对应 `/test-api mes` 命令。包含每个文件的 case 级数据 + 失败根因。

## 通过率

| 指标 | 数值 |
|------|:--:|
| **总文件数** | 12 |
| **通过文件** | 9 (75%) |
| **失败文件** | 3 (25%) |
| **总耗时** | ~10 秒 |
| **Runner** | 原生 `node file.test.js` |

## 按文件结果

| # | 文件 | 状态 | 耗时 | baseURL |
|---|------|:--:|:--:|---------|
| 1 | `basic.test.js` | ❌ | 1s | localhost |
| 2 | `batch-global-switch.test.js` | ✅ | 0s | localhost |
| 3 | `batch-manual-e2e.test.js` | ✅ | 1s | localhost |
| 4 | `manufacturing.test.js` | ✅ | 1s | **100.122.125.106** |
| 5 | `other-stock-in.test.js` | ❌ | 0s | localhost |
| 6 | `purchase.test.js` | ✅ | 1s | **100.122.125.106** |
| 7 | `purchase-apply-order.chain.test.js` | ❌ | 1s | HARNESS_BASE/localhost |
| 8 | `purchase-order-receipt.chain.test.js` | ✅ | 0s | HARNESS_BASE/localhost |
| 9 | `stocktake.test.js` | ✅ | 1s | localhost |
| 10 | `codeRule.test.mjs` | ✅ | 1s | **100.122.125.106** |
| 11 | `sales-api.test.mjs` | ✅ | 1s | **100.122.125.106** |
| 12 | `sales-order.test.mjs` | ✅ | 1s | **100.122.125.106** |

## baseURL 分布（重要发现）

| baseURL | 文件数 | 备注 |
|---------|:--:|------|
| `http://localhost:8080/jeecg-boot` | 7 | 开发环境 |
| `http://100.122.125.106:8080/jeecg-boot` | 5 | 生产/远程环境 |
| `process.env.HARNESS_BASE \|\| localhost` | 2 | 可切换 |

> ⚠️ **baseURL 不统一**导致测试结果可比性下降：
> - 开发环境（localhost）测试的是本地 dev 后端
> - 生产/远程环境（100.122.125.106）测试的是生产 API
>
> 建议统一为 `process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot'`，CI 环境注入 HARNESS_BASE。

## 失败明细（3 文件）

### 1. basic.test.js

**失败信号**：
```
❌ 仓库列表(空): total=6
```

**根因**：DB 残留 6 条历史仓库数据，测试期望"空仓库"列表。
**类别**：数据残留（不是代码 bug）
**建议**：测试前清理数据 / 测试断言改为 `total >= 0` / 或在 fixture 里接受"非空"路径

### 2. other-stock-in.test.js

**失败信号**：
```
❌ 手工出库差异=6.75: costDiff=undefined
```

**根因**：手工出库接口未返回 `costDiff` 字段（或字段命名不一致）。
**类别**：接口字段缺失
**建议**：检查后端 Controller 返回字段，确认是 `costDiff` 还是 `costDifference` / `diff`

### 3. purchase-apply-order.chain.test.js

**失败信号**：
```
❌ 审核申请: 交货日期不能早于订单日期
❌ [链路] 审核后状态=已审核(3): 实际=1
❌ 加载明细: code=500
❌ [链路] 返回2行明细: 实际=undefined
```

**根因**：
- 申请单审核时校验了"交货日期不能早于订单日期"（业务校验过严或测试数据日期错）
- 审核后状态机期望=3（已审核），实际=1（草稿）— 状态机未推进
- 加载明细接口 500 — 后端报错

**类别**：业务规则变更 + 接口异常
**建议**：
1. 对照最新业务规则文档，确认申请单状态机定义
2. 检查后端日志 `/tmp/jeecg-backend.log` 看 500 报错根因

## 通过的 case 详情（无失败，仅摘要）

- **manufacturing.test.js**：BOM 管理 + 生产订单 + 生产领料 + 完工入库全过（含 3.x P0 修复验证）
- **purchase.test.js**：采购订单链路通过
- **batch-global-switch.test.js / batch-manual-e2e.test.js**：批次总开关测试通过（V8.0.0 P0-1~4 修复后）
- **stocktake.test.js**：盘点单链路通过
- **sales-api / sales-order**：销售链路通过
- **codeRule.test.mjs**：编码规则测试通过

## 后续建议

### P1（建议本周修复）

- **统一 baseURL**：所有 API 测试改用 `process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot'`
- **清理 DB 残留数据**：建立 pre-test 清理 fixture 或隔离测试 schema
- **purchase-apply 状态机/接口 500 排查**：检查后端日志

### P2（建议本月修复）

- **costDiff 字段命名统一**：手工出库接口字段命名规则化
- **业务规则回归测试**：建立业务规则变更触发器，自动跑链路测试

## 附录

- 详细日志：`.claude/memory/inbox/test-results/*.log`
- CSV 汇总：`.claude/memory/inbox/test-results/_summary.csv`
- 关联报告：`mes-test-e2e-baseline.md` / `mes-test-report.md`（test-all 总基线）

## 趋势对比

| 指标 | 本次 (2026-08-02) | 历史 |
|------|:--:|:--:|
| API 测试通过率 | 75% (9/12) | — |
| 平均单文件耗时 | 0.83s | — |
| baseURL 一致性 | 7/12 = 58% | — |

> 本次为首跑基线，无历史对比。下次跑 test-api 时将自动对比本次数据。