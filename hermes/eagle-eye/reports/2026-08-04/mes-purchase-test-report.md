# MES Purchase 模块回归测试报告

**日期**：2026-08-04
**模块**：purchase（采购）
**Controller 数**：5
**测试类型**：API + E2E

## 一、测试概况

| 指标 | 数值 |
|---|---:|
| API 测试用例 | 78 |
| 通过 | 70 |
| 失败 | 8 |
| 失败率 | 10.3% |
| E2E 测试 | 6 |
| 通过 | 3 |
| 失败 | 3 |

## 二、API 测试详情

| 测试 | 通过/总数 | 通过率 |
|---|:-:|:-:|
| purchase.test.js | 26/26 ✅ | 100% |
| purchase-apply-order.chain.test.js | 10/18 ⚠️ | 55.6% |
| purchase-order-receipt.chain.test.js | 16/16 ✅ | 100% |

## 三、P2 — purchase-apply-order.chain 失败

### 根因：审核申请时日期校验冲突

**调用**：
```javascript
// Step 3: 审核申请
PUT /mes/purchase/apply/audit?id=...
```

**期望**：申请状态 → 已审核(3)
**实际**：返回 "交货日期不能早于订单日期"，申请状态仍为草稿(1)

**影响链路**：
- Step 4 加载明细（因为状态没变）→ code=500
- Step 5/6 后续链路全断

**根因方向**：
- 测试数据准备阶段 applyDate = today，requiredDate = today+1，但实际跑时 today 已变（凌晨3点 → 新的一天）
- 或后端日期校验逻辑对"requiredDate < today" 错误地拒绝
- 或前端日期格式与后端期望不一致

## 四、P2 — E2E 页面加载失败

| # | 测试 | 错误 |
|---|---|---|
| 1 | purchase.spec.ts E2E-04 | 采购订单页面加载失败 |
| 2 | purchase.spec.ts E2E-05 | 采购入库页面加载失败 |

**共性**：两个测试都是"页面加载"，可能是：
- 列表页空数据（不符合测试前提）
- token 注入失败（auth 失效）
- 菜单权限问题

详见 `harness/test-results/` 截图。

## 五、明早优先排查

1. **🟡 P2-1**: purchase-apply-order 日期校验 — 修测试数据日期计算
2. **🟡 P2-2/3**: purchase E2E 页面加载 — 看截图 + trace

## 六、原始日志

`hermes/eagle-eye/state/api-logs/purchase.log`
`hermes/eagle-eye/state/api-logs/purchase-apply-order.chain.log`
`hermes/eagle-eye/state/api-logs/purchase-order-receipt.chain.log`
`hermes/eagle-eye/state/e2e-20260804.log`（grep purchase）