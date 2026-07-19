---
date: 2026-07-20
category: 并发安全
tags: [库存, 对称操作, FOR UPDATE, stockIn, stockOut]
---

# 对称操作必须使用相同的并发保护——stockIn/stockOut 不对称的教训

## 触发条件
`stockOut()` 使用了 `selectForUpdate` 行锁，但 `stockIn()` 只用普通 `SELECT`（`findByMaterialAndWarehouse`）。全量审计发现：并发入库将导致台账数据不准（虽 `ON DUPLICATE KEY UPDATE` 保证最终库存正确）。

## 根因
开发时只关注了"出库并发超卖"这个显而易见的风险，忽视了入库也有并发写入问题。

## 正确做法
对称操作（入库/出库、收款/付款、应收/应付）的并发保护必须一致。新增操作时，先对照已有对称操作确保保护级别相同。

```java
// stockIn 和 stockOut 都必须使用 selectForUpdate
MesInventory inv = inventoryMapper.selectForUpdate(materialId, warehouseId);
```

## 预防
审计检查项：对照每个"读写"操作对（入/出、收/付、增/减），确认两端的锁机制一致。
