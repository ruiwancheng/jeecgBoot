# MES Finance 模块回归测试报告

**日期**：2026-08-04
**模块**：finance（业财管控）
**Controller 数**：8
**测试类型**：API（新增）+ 前端类型检查

## 一、测试概况

| 指标 | 数值 |
|---|---:|
| API 测试用例 | 119 |
| 通过 | 113 |
| 失败 | 6 |
| 失败率 | 5.0% |
| 前端 TS 错误 | 18（8 个 .data.ts 文件） |

## 二、Controller 端点覆盖矩阵

| Controller | list | queryById | queryAll | exportXls | add | edit | delete | deleteBatch | audit | tree | selectPage |
|---|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| collection | ✅ | ✅ | ✅ | ✅ | ✅ | — | — | — | — | — | — |
| salesInvoice | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — | — | — |
| payable | ✅ | ✅ | ✅ | ✅ | — | — | — | — | — | — | — |
| payment | ✅ | ✅ | ✅ | ✅ | ✅ | — | — | — | — | — | — |
| purchaseInvoice | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — | — | — |
| receivable | ✅ | ✅ | ✅ | ✅ | — | — | — | — | — | — | — |
| subject | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | ✅ | ✅ |
| voucher | ✅ | — | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |

## 三、模块级通过率

| Controller | 通过/总数 | 通过率 |
|---|:-:|:-:|
| collection | 12/13 | 92.3% |
| salesInvoice | 14/15 | 93.3% |
| payable | 14/14 | 100% |
| payment | 12/13 | 92.3% |
| purchaseInvoice | 14/15 | 93.3% |
| receivable | 14/14 | 100% |
| subject | 17/18 | 94.4% |
| voucher | 16/17 | 94.1% |

## 四、失败明细

### P3 — 测试代码 bug（统一模式）

**6 个失败全部是同一类**：测试断言要求 `add` 空 body 时 `code !== 500`，但后端实际返回 `500 + 业务校验消息`（如"凭证号不能为空"、"科目编码不能为空"）。

实际**业务校验生效**（message 含中文业务校验），不是真 bug。

**修复**：测试断言改为 `code === 200 || (code === 500 && message && /不能为空|为空|不能为空|不存在/.test(message))`。

| # | 模块 | 错误信息 |
|---|---|---|
| 1 | collection | `code=500 msg=...` |
| 2 | salesInvoice | `code=500 msg=...` |
| 3 | payment | `code=500 msg=...` |
| 4 | purchaseInvoice | `code=500 msg=...` |
| 5 | subject | `code=500 msg=科目编码不能为空` |
| 6 | voucher | `code=500 msg=凭证号不能为空` |

### R002 越权测试（跳过）

无权限账号 `guest` 不存在，全部跳过 8 模块 × 1 = 8 个 R002 用例。

## 五、前端 TS 错误（18 个）

详见 [mes-frontend-test-report.md](./mes-frontend-test-report.md) 的 P1-1。

8 个 controller 的 `.data.ts` 用了反模式的 `dictTable` / `dictCode` 字段。

## 六、明早优先排查

1. **P1（前端）**：finance 8 个 `.data.ts` — 批量修复或升级 BasicColumn 类型
2. **P3（测试）**：调整 finance.test.js 的断言条件

## 七、原始日志

`hermes/eagle-eye/state/api-logs/finance.log`
`hermes/eagle-eye/state/typecheck-20260804.log`（grep 'src/views/project/mes/finance'）