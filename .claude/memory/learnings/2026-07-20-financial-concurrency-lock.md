---
date: 2026-07-20
category: 并发安全
tags: [收付款, FOR UPDATE, 行锁, 资损, 应收应付]
---

# 收付款操作必须用 FOR UPDATE 锁 AR/AP 行——否则并发超收超付

## 触发条件
收款保存时先 `getById` 查应收（无锁），校验 `收款金额 ≤ 未结金额` 后 `updateById`。两个并发收款可同时通过校验，合计收款超过应收总额。

## 根因
收款/付款的"读-校验-写"三步操作未使用行锁，存在 TOCTOU 竞态窗口。

## 正确做法
```java
// 1. 在 AR/AP Mapper 加行锁查询
@Select("SELECT * FROM c_mes_receivable WHERE id = #{id} FOR UPDATE")
MesReceivable selectByIdForUpdate(@Param("id") String id);

// 2. 收款保存时用行锁读取
MesReceivable ar = receivableMapper.selectByIdForUpdate(entity.getReceivableId());
if (entity.getAmount().compareTo(ar.getUnsettledAmount()) > 0) throw ...
ar.setReceivedAmount(ar.getReceivedAmount().add(entity.getAmount()));
receivableService.updateById(ar);
```

## 预防
所有涉及金额读-校验-写的操作（收款/付款/库存扣减），必须在 Mapper 层提供 `selectByIdForUpdate` 方法，Service 层使用行锁读取。
## 关联
- ✅ 已覆盖: code-style.md ServiceImpl FOR UPDATE行锁
