---
date: 2026-07-20
category: 数据一致性
tags: [跨模块, 审计, fail-fast, 静默跳过]
---

# 跨模块查不到关键数据时应抛异常而非静默跳过

## 触发条件
采购入库审核时，从采购订单行取单价。如果某物料在订单行中找不到对应记录或无单价，代码用 `if (!orderItems.isEmpty())` 保护，**静默跳过该行的金额计算**，但仍然执行了 `stockIn` 入库。结果：库存增加但应付金额未包含该行，财务数据不一致。

## 根因
防御性编程过度——用"找不到就跳过"代替"找不到就报错"，导致数据在部分正确的状态下继续流转。

## 正确做法
跨模块查关键数据时，查不到应抛出明确异常：
```java
if (orderItems.isEmpty()) throw new JeecgBootException(
    "第" + (i+1) + "行物料在采购订单中未找到，无法确定单价，请联系管理员");
if (orderItems.get(0).getUnitPrice() == null) throw new JeecgBootException(
    "第" + (i+1) + "行采购订单单价为空，无法计算入库金额");
```

## 预防
审计检查项：搜索 `if (!xxx.isEmpty() && xxx.get(0))` 模式，确认 `else` 分支是否有明确的错误处理。
