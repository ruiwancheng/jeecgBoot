# 业务设计规则

> MES 批次/库存/单据领域的设计规范（2026-08-01 起从 learnings 沉淀）

## 批次台账设计（batch-ledger-design-rule）

**核心表**：`c_mes_batch_ledger` —— 全局批次流水（跨模块、跨业务来源）

**字段约定**：
- `batch_no`：批次号（业务唯一）
- `material_id`：物料 ID（关联 `c_mes_material`）
- `qty`：数量（DECIMAL(18,4)）
- `unit_cost`：单位成本（移动平均或批次价）
- `source_bill_type`：来源单据类型（PO/InStock/Trans）
- `source_bill_id`：来源单据 ID
- `source_bill_no`：来源单据号
- `in_time`/`out_time`：入库/出库时间
- `remain_qty`：剩余数量（用于 FIFO/LIFO 跟踪）

**强制规则**：
- ✅ **不删除批次记录**（即使数量为 0，加 `remain_qty=0` + `status='depleted'` 标记）
- ✅ **所有批次变动走 SQL 触发器或 Service 层**，不直接 UPDATE
- ✅ **成本计算**用 `c_mes_batch_ledger.unit_cost` 字段，不用物料表的 `moving_avg_cost`（避免双源数据）

详见 `learnings/2026-08-01-batch-ledger-design-rule.md`。

---

## 跨模块 FK + 批次 + 来源单据（cross-module-fk-batch-origin-bill）

**模式**：MES 业务单据**多对一关联批次**，单据项**多对一关联来源单据项**。

**例**：
```
采购入库单 (c_mes_purchase_receipt)
  └─ 明细项 (c_mes_purchase_receipt_item)
       ├─ batch_id → c_mes_batch_ledger.id（批次）
       ├─ material_id → c_mes_material.id（物料）
       └─ source_order_item_id → c_mes_purchase_order_item.id（来源采购订单明细）
```

**强制规则**：
- ✅ 跨模块 FK 加 `ON DELETE RESTRICT`（防止误删）
- ✅ 批次变更追溯：保留 `source_bill_*` 三件套
- ✅ 物料-批次-单据联动查询用 LEFT JOIN（兼容批次未生成场景）

详见 `learnings/2026-08-01-cross-module-fk-batch-origin-bill.md`。