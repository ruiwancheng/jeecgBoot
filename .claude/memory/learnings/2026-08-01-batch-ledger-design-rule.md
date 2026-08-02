# 批次 ledger 设计规则：库存变动流水 vs 档案创建记录，**绝不混写**

**场景**：同一次入库 audit 触发 2 条同 `occur_time` / 同 `in_qty` 的 ledger 记录：
- 1 条 "批次创建"（warehouseId=''）
- 1 条 "批次入库"（warehouseId=仓库1）

**根因**：
- `MesBatchServiceImpl.createBatchWithManualNo` 调 `writeLedger`（"批次创建"）
- `MesBatchInventoryServiceImpl.stockIn` 调 `writeLedger`（"批次入库"）
- 同一事务内两次写 → 用户看到 2 条

**ledger 表设计语义**：
- **库存变动流水**（in_qty / out_qty / warehouse_id / biz_id / biz_no 全部必填）
- 唯一职责：**溯源**——任何"某批次在某时某仓库增减了多少"都能查到

**批次档案创建（createBatch）不属于库存变动**：
- 无 warehouse（创建时未入库）
- 无 biz_id（来源单据是"创建"行为，不是"入库"行为）
- 写 ledger 等于在库存表里塞了一条"无意义数据"

**正确分工**：
| 操作 | 写 batch 主档 | 写 batch_inventory | 写 ledger |
|------|:--:|:--:|:--:|
| `createBatch`（批次档案创建）| ✅ | ❌ | ❌ |
| `stockIn`（入库）| 已存在 | ✅ | ✅ "批次入库" |
| `stockOutFifo`（出库 FIFO）| 已存在 | ✅ | ✅ "批次出库" |
| `freeze/unfreeze`（冻结/解冻）| 改 status | ❌ | ❌ |

**触类旁通**：
- 凡是"档案状态变更"vs"数量变更"两件事，**只对"数量变更"写流水**
- 一笔业务动作只产生一条 ledger——这是溯源的基础假设
- 写两条同 `biz_id + biz_type` 的 ledger = 业务事件被记两次 = 未来按"批次追溯某笔入库"会出现 2 条记录 → 重复扣减、重复对账等连锁 bug

**预防**：
- Code review 看到 `writeLedger` 调用立刻想：warehouse_id 是空吗？是空就不该写
- 表设计时把 `warehouse_id NOT NULL` 加上（让架构约束自动拦截错误写入）——这个项目 c_mes_batch_ledger 当前允许 warehouse_id NULL 是漏洞

**实证**：
- 2026-08-01 修复：`MesBatchServiceImpl.createBatchWithManualNo` 删除 `writeLedger` 调用
- 修复后验证：单笔入库 → ledger 数从 2 条降到 1 条
