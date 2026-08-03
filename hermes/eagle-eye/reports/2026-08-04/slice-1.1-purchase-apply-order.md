# Slice 1.1 — purchase-apply-order.chain 跑测报告

- **报告路径**：`hermes/eagle-eye/reports/2026-08-04/slice-1.1-purchase-apply-order.md`
- **生成时间**：2026-08-04 02:41 (Asia/Shanghai)
- **测试文件**：`harness/tests/chains/purchase-apply-order.chain.test.js`
- **测试目标**：采购申请 → 采购订单 链路（创建→草稿拦截→审核→加载明细→建单→审单→反审单）
- **后端**：localhost:8080/jeecg-boot，✅ 存活（200 OK）
- **数据库**：MySQL:13306 ✅ Redis ✅
- **分支**：fix/regression-2026-08-04

---

## 切片信息

| 字段 | 值 |
|---|---|
| sliceId | 1.1 |
| name | purchase-apply-order（采购申请→采购订单 链路） |
| type | chain-integration |
| risk | P0（影响审核主链路） |
| effort | S |
| assertions | 18（10 通过 / 8 失败） |
| passRate | 55.6% |
| duration | ~1s（含 fixture） |

---

## 跑测结果

```
━━━ 链路测试: 采购申请 → 采购订单 ━━━
✅ 登录成功
✅ fixture: 供应商=SUP_T_1785782449221 物料=MAT_T_...a/b

Step 1: 创建申请
  ✅ 创建申请: 添加成功
  ✅ 申请已出现在列表
  ✅ [链路] 新申请状态=草稿(1): 实际=1

Step 2: 草稿申请不可用于生成订单
  ✅ [链路] 草稿申请被拦截: 仅已审核的申请可生成订单

Step 3: 审核申请
  ❌ 审核申请: 交货日期不能早于订单日期
  ❌ [链路] 审核后状态=已审核(3): 实际=1

Step 4: 已审核申请加载到订单
  ❌ 加载明细: code=500（仅已审核的申请可生成订单，因审核回滚）
  ❌ [链路] 返回2行明细: 实际=undefined
  ❌ [链路] 第1行物料=m1
  ❌ [链路] 第1行数量=50: 实际=undefined
  ❌ [链路] 第2行物料=m2

Step 5: 用申请明细创建订单
  ✅ 从申请明细创建订单: 添加成功
  ✅ 订单已创建

Step 6: 审核订单
  ✅ 审核订单: 审核成功
  ✅ [链路] 订单状态=已确认(3): 实际=3
  ❌ [链路] 申请状态仍为已审核(3)，未被订单联动: 实际=1
     （根因同上：申请从未真正审核）

Step 7: 订单反审核
  ✅ 反审核订单: 反审核成功
  ✅ [链路] 反审核后订单状态=草稿(1): 实际=1

━━━ 清理 ━━━
✅ 清理完成

===== 链路: 申请→订单: 10 通过, 8 失败 =====
```

---

## 失败明细

| # | 断言 | 实际错误 |
|---|---|---|
| 1 | `审核申请` | `PUT /mes/purchase/apply/audit` → `code=500 "交货日期不能早于订单日期"` |
| 2 | `[链路] 审核后状态=已审核(3)` | 实际=1（事务回滚） |
| 3 | `加载明细` | `code=500 "仅已审核的申请可生成订单"` |
| 4 | `[链路] 返回2行明细` | 实际=undefined |
| 5 | `[链路] 第1行物料=m1` | — |
| 6 | `[链路] 第1行数量=50` | 实际=undefined |
| 7 | `[链路] 第2行物料=m2` | — |
| 8 | `[链路] 申请状态仍为已审核(3)，未被订单联动` | 实际=1（与 #2 同根因） |

**所有 8 个失败 = 同一个根因**：申请审核时自动生成订单逻辑触发了「交货日期不能早于订单日期」校验，事务回滚 → 申请状态未更新。

---

## 根因分析

### 复现现场

- 测试机本地时区：Asia/Shanghai（UTC+8），系统时间 **2026-08-04 02:41 AM**
- 同一时刻 UTC 时间：**2026-08-03 18:41**
- 测试 fixture（已修复过的版本）：
  ```js
  const TODAY    = new Date().toISOString().slice(0, 10);    // → "2026-08-03"（UTC）
  const TOMORROW = new Date(Date.now() + 86400000).toISOString().slice(0, 10); // → "2026-08-04"（UTC）
  ```
- 申请入库：applyDate=2026-08-03, requiredDate=2026-08-04
- 审核触发 `MesPurchaseApplyServiceImpl.generateDraftPurchaseOrder`：
  ```java
  order.setOrderDate(new Date());              // 2026-08-04 02:41:22.279 +0800
  order.setDeliveryDate(apply.getRequiredDate()); // 2026-08-04 00:00:00（仅日期，无时）
  ```
- `MesPurchaseOrderServiceImpl.validateOrder`：
  ```java
  if (entity.getDeliveryDate().before(entity.getOrderDate()))
      throw new JeecgBootException("交货日期不能早于订单日期");
  ```
- 比较：`2026-08-04 00:00:00` < `2026-08-04 02:41:22` → **true** → 抛错 → `@Transactional` 回滚 → 申请审核也回滚。

### 三方时区错位

| 角色 | "今天" |
|---|---|
| Node 测试端（UTC ISO 切片） | 2026-08-03 |
| 浏览器/前端用户视角（local date） | 2026-08-04 |
| 服务端 `new Date()`（JVM 时区） | 2026-08-04 02:41 +0800 |
| `requiredDate` 反序列化（前端发"YYYY-MM-DD"） | 2026-08-04 00:00 +0800 |

→ server 端认为「订单日期 04-04 02:41」晚于「交货日期 04-04 00:00」，校验不过。

### 新发现 Bug（建议 P1）

> **`BUG-PURCHASE-AUDIT-DATE-TZ`**：审核申请时自动生成草稿订单，因 `orderDate` 含时分秒而 `deliveryDate`（requiredDate）仅到日，导致「同日但跨小时」场景被错误判定为 `deliveryDate < orderDate`，事务回滚使申请审核失败。

修复建议（二选一或叠加）：

1. **服务端对齐日精度**（推荐）：`generateDraftPurchaseOrder` 中 `orderDate` 改为与 `requiredDate` 同粒度，例如
   ```java
   order.setOrderDate(apply.getApplyDate() != null ? apply.getApplyDate() : DateUtils.truncate(new Date(), Calendar.DAY_OF_MONTH));
   ```
   或直接 `DateUtils.truncate(new Date(), Calendar.DAY_OF_MONTH)`。

2. **比较时去时分秒**（兜底）：`validateOrder` 用 `DateUtils.isSameDay` 或 `org.apache.commons.lang3.time.DateUtils.truncate` 后再 `before` 比较。

3. **测试端兜底**：fixture 改用 `new Date().toLocaleDateString('sv-SE')`（瑞典 locale 输出 `YYYY-MM-DD`）拿到**系统本地日期**，避免 UTC 切片错位。但这只是掩盖问题，应优先修服务端。

---

## 通过项（验证通过的能力）

- ✅ 登录链路
- ✅ Fixture 创建（供应商 + 物料 × 2）
- ✅ 申请创建 + 列表回查 + 初始草稿状态
- ✅ 草稿申请被订单加载端点拦截（业务约束正确）
- ✅ 手工创建订单（含完整订单头 + 2 行明细）+ 列表回查
- ✅ 订单审核 + 状态=3 已确认
- ✅ 订单反审核 + 状态=1 草稿
- ✅ 清理（申请/订单/供应商/物料软删除）

---

## 下一步建议

1. **P1 修复**：`BUG-PURCHASE-AUDIT-DATE-TZ` —— 修 `validateOrder` 或 `generateDraftPurchaseOrder` 中的日期精度问题。
2. **回归**：修后重跑 `purchase-apply-order.chain.test.js`，预期全绿。
3. **横向扩散**：同链路上下游 `purchase-order-receipt.chain.test.js` / `purchase-payment-flow.test.js` 同样走审核+自动生成链路，可能命中同类问题，跑一遍验证。
4. **CI 钩子**：把 `harness/tests/chains/purchase-*.test.js` 接入定时回归，避免该 bug 再次潜伏到上线前夜。

---

**reportPath**：`hermes/eagle-eye/reports/2026-08-04/slice-1.1-purchase-apply-order.md`
**filesModified**：无（本次纯验证任务，未改动代码）