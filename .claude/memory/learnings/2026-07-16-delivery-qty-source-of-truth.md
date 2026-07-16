---
date: 2026-07-16
category: 后端
tags: [主子表, 数据来源, deliveryQty, 前端只读, P0-10]
---

# 主子表明细中的"来源字段"必须后端强制覆盖，前端只读

## 触发条件
出库单明细的 `deliveryQty`（发货数量）前端标记为只读展示，但后端 `validate()` 没有强制从发货单来源覆盖。攻击者可通过 API 传任意值。

## 根因
字段同时存在于 Entity（接受 JSON 绑定）但逻辑上应该来自关联表。如果不加 `item.setDeliveryQty(src.getDeliveryQty())`，前端虽然只读但 API 请求可以随意写入。

## 正确做法
源代码字段（如从发货单继承的 deliveryQty）在 Service 中强制覆盖：
```java
item.setDeliveryQty(src.getDeliveryQty() != null ? src.getDeliveryQty() : BigDecimal.ZERO);
```
不做 if-null-then-set，而是无条件覆盖。前端只读只是 UI 层的防线，不是数据层的。
