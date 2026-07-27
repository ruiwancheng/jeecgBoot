---
date: 2026-07-19
category: 并发安全
tags: [audit, stockOut, 事务, 操作顺序]
---

# 审核操作中库存扣减必须先于状态变更执行——否则并发导致幻扣

## 触发条件
出库审核中，先执行 `stockOut()` 扣库存，后执行 `auditWithGuard()` 原子改状态。并发场景下 auditWithGuard 失败（返回0行），但 stockOut 库存已扣。虽同在一个 @Transactional 中会回滚，但如果库存服务使用了独立数据源或 REQUIRES_NEW 传播级别，则库存扣减无法回滚。

## 根因
操作顺序考虑不周——"先准备数据再确认"的直觉顺序在并发场景下是反的。应该先获取锁/确认状态变更成功，再执行副作用操作。

## 正确做法
```java
// 1. 先原子改状态（获取行锁，确认单据可操作）
int rows = mapper.auditWithGuard(id, user, now);
if (rows == 0) throw new JeecgBootException("状态已变更");

// 2. 状态确认后，再执行副作用（扣库存/写台账）
for (item : items) inventoryService.stockOut(...);
```

核心原则：**先获取资源/确认状态 → 再执行副作用**。获取失败则副作用不执行。
