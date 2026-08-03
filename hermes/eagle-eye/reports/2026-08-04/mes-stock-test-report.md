# MES Stock 模块回归测试报告

**日期**：2026-08-04
**模块**：stock（库存：其它入库、盘点）
**测试类型**：API + E2E

## 一、测试概况

| 指标 | 数值 |
|---|---:|
| API 测试用例 | 37 |
| 通过 | 37 |
| 失败 | 0 |
| E2E 测试 | 2 |
| 通过 | 1 |
| 失败 | 1 |

## 二、API 测试详情

| 测试 | 通过/总数 |
|---|:-:|
| other-stock-in.test.js | 9/9 ✅ |
| stocktake.test.js | 28/28 ✅ |

## 三、P2 — other-stock-in.spec.ts 失败

```
Error: 其它入库 › 新增入库单-物料选中后自动预填移动平均成本
```

**症状**：物料选中后未自动预填移动平均成本

详见 `harness/test-results/`。

## 四、明早优先排查

1. **🟡 P2-1**: 其它入库物料预填 — 看截图 + trace

## 五、原始日志

`hermes/eagle-eye/state/api-logs/other-stock-in.log`
`hermes/eagle-eye/state/api-logs/stocktake.log`
`hermes/eagle-eye/state/e2e-20260804.log`（grep stock|other）