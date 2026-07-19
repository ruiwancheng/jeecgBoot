---
date: 2026-07-19
category: 数据持久化
tags: [calcTotal, save, 金额, 事务]
---

# calcTotal 必须在 save/resurrect/updateById 之前调用，否则 totalAmount 不持久化

## 触发条件
发货单和出库单在新增/编辑时，`calcTotal(entity)` 放在 `super.save(entity)` 或 `baseMapper.resurrect(entity)` 之后调用。此时 entity 已写入数据库，calcTotal 只在 Java 内存中设置了 totalAmount，从未 UPDATE 回数据库。结果：total_amount 列永远为 NULL。

## 根因
直觉上"先落库再算合计"是合理的——但 calcTotal 修改的是 entity 对象的字段，save/resurrect 之后 entity 与数据库已断开。MyBatis-Plus 的 save/updateById 不会自动追踪后续字段变更。

## 正确做法
参照 MesSalesOrderServiceImpl 的正确模式：
```java
validate(entity);
calcTotal(entity);  // ← 必须在 save 之前
super.save(entity);
```

如果是 resurrect 场景：
```java
calcTotal(entity);  // ← 在 resurrect 之前
baseMapper.resurrect(entity);
```
