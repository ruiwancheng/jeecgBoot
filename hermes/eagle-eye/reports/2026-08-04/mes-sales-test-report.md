# MES Sales 模块回归测试报告

**日期**：2026-08-04
**模块**：sales（销售）
**Controller 数**：4
**测试类型**：API + E2E

## 一、测试概况

| 指标 | 数值 |
|---|---:|
| API 测试用例 | 54 |
| 通过 | 54 |
| 失败 | 0 |
| E2E 测试 | 2 |
| 通过 | 1 |
| 失败 | 1 |

## 二、API 测试详情

| 测试 | 通过/总数 |
|---|:-:|
| sales-api.test.mjs | 24/24 ✅ |
| sales-order.test.mjs | 30/30 ✅ |

## 三、P2 — sales-order.spec.ts E2E-01 失败

```
Error: 销售订单 › E2E-01: 页面加载 + 列表渲染
```

**症状**：列表/搜索无响应

详见 `harness/test-results/mes-sales-order-销售订单-E2E-01-页面加载-列表渲染-retry1/`。

## 四、明早优先排查

1. **🟡 P2-1**: sales-order E2E 页面加载 — 看截图 + trace

## 五、原始日志

`hermes/eagle-eye/state/api-logs/sales-api.log`
`hermes/eagle-eye/state/api-logs/sales-order.log`
`hermes/eagle-eye/state/e2e-20260804.log`（grep sales）