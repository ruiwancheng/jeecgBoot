# 跨模块外键假设陷阱——批次/业务表关联走 origin_bill_id 反向引用

**触发条件：** 评审涉及批次表（c_mes_batch）与业务表（采购入库/完工入库/领料/销售出库）的关联查询。

**处理方式：**
- 业务表**没有** `batch_id` 列——不要写 `WHERE batch_id IS NOT NULL`
- 批次通过 `c_mes_batch.origin_bill_id` + `c_mes_batch.origin_type` 反向引用业务单据
- 查"某业务单据有没有关联批次"应通过 `c_mes_batch` 反向查：`SELECT * FROM c_mes_batch WHERE origin_bill_id IN (SELECT id FROM 业务表 WHERE ...)`
- 查"有库存的批次"应直接查 `c_mes_batch_inventory WHERE qty > 0`，不需要关联业务表

**实证：** 2026-08-01 两轮批次评审都踩到此陷阱。第一次（总开关）L3 检查写 `mes_completion_receipt WHERE batch_id IS NOT NULL`——4 个业务表都无此列。第二次（手工录入）复查确认关联机制是 `c_mes_batch.origin_bill_id`。read 了 4 个 Service 的 audit 代码才确认 createBatch 调用传的是 `e.getId()`（业务单据 ID）作为 originBillId。
