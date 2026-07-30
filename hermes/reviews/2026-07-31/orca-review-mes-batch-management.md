# MES 生产批次管理模块（3 Phase 完整方案）— 评审

> 评审日期：2026-07-30 | 评审对象：pi 草案（MES 批次管理 3 Phase 方案，69 文件，10-13h）
> 判定：**PASS**（7 项需调整，无阻塞——但在 Phase 3 开始前必须解决成本冲突问题）

---

## 一、架构可行性——3 Phase 拆分评审

### 阶段依赖关系

```
Phase 1 (1.5h)     Phase 2 (4-6h)     Phase 3 (4-6h)
 前端模板对齐         批次基础建设         整合点
     │                   │                   │
     │  ✅ 无依赖         │  ✅ 无依赖         │  ⚠️ 依赖 Phase 2
     │                   │                   │
     └─────── 独立交付 ──┴────── 独立交付 ────┴────── 依赖 Phase 2
```

### ✅ 拆分合理。三点确认

1. **Phase 1 可独立交付**：纯前端 UI 对齐，不影响后端，可随时合并。
2. **Phase 2 可独立交付**：批次三表+四前端模块独立运行，不与现有模块联动。可先上线积累数据。
3. **Phase 3 必须等 Phase 2**：整合点需要批次表存在。这是正确的依赖顺序。

---

## 二、关键事实纠正

### ❌ 需调整项 #1：生产订单没有 Item 实体 → 不需要 ItemsSubTable

草案说"order + picking 缺 ItemsSubTable"。实际情况：

| 模块 | 有 Item Entity? | 有 Item DDL? | 前端应有 ItemsSubTable? |
|------|:--:|:--:|:--:|
| bom | ✅ MesBomItem | ✅ `c_mes_bom_item` | ❌ BOM 是配置表，不是单据——无展开行需求 |
| order | ❌ 无 | ❌ 无 | ❌ 生产订单是**单表**（无明细行） |
| picking | ✅ MesProductionPickingItem | ✅ `c_mes_production_picking_item` | ✅ 应有 |
| completion | ✅ MesCompletionReceiptItem | ✅ `c_mes_completion_receipt_item` | ✅ 应有 |

**订单 DDL 确认**：`c_mes_production_order` 只有 12 个字段（code/product_id/bom_id/plan_qty/completed_qty/start_date/end_date/warehouse_id/status/remark + 审计字段），无明细行子表。`queryById` 也是直接 `service.getById(id)`，不查 items。

**对 Phase 1 的影响**：
- ✅ picking + completion 补 ItemsSubTable→正确（2 个文件增加）
- ❌ order 不需要 ItemsSubTable→从文件清单中移除
- Phase 1 文件数修正：17→16（减去 order ItemsSubTable）+2（picking/completion ItemsSubTable）= **18**

---

## 三、库存接口分析——R5 成本冲突

### 现状

```java
// IMesInventoryService
void stockIn(materialId, warehouseId, qty, unitCost, amount, bizType, bizId);
void stockOut(materialId, warehouseId, qty, unitCost, amount, bizType, bizId);

// IMesMaterialService
BigDecimal updateMovingAvgCostOnStockIn(materialId, inQty, unitCost, warehouseId, bizType, bizId);
```

当前 4 个调用点：

| 模块 | 操作 | unitCost 传参 | updateMovingAvgCost? | 涉及 ADR |
|------|------|:--:|:--:|------|
| 其它入库 | stockIn | ✅ 传入 | ✅ 调用 | 无 |
| 其它出库 | stockOut | ✅ 传入 | 不适用 | 无 |
| 采购收货 | stockIn | ✅ 传入 | ✅ 调用 | 无 |
| 销售出库 | stockOut | **`null`** | 不适用 | ADR 0001 |
| 完工入库 | stockIn | **`null`** | ❌ 不调用 | ADR 0001 |

### R5 分析

**核心问题**：`stockIn/stockOut` 的 `unitCost` 参数就是批次成本的入口。当前销售出库传 `null`（ADR 0001 锁定出库不传成本），完工入库也传 `null`（完工成本由生产订单可知）。

**批次成本 vs 物料移动平均成本——如何共存：**

1. **入库**：批次入库时传具体的批次单价（来自采购价）。`updateMovingAvgCostOnStockIn` 同时更新物料移动平均成本（物料级聚合）。
2. **出库**：批次出库时，传该批次的批次成本作为 `unitCost`。——这**不影响** ADR 0001 锁定成本逻辑（ADR 说的是销售出库锁定不重算物料平均成本，但批次出库仍需要 cost 传到 `stockOut` 写台账）。
3. **台账差异**：入库/出库的 `unitCost` 参数最终写入 `MesInventoryLedger`（台账表），但当前 `stockOut` 只用 `amount` 写台账 `outAmount`。批次出库的 `unitCost` 需要单独存到批次台账。

**结论**：批次成本与物料移动平均成本可以共存——两者是不同颗粒度的聚合。**但 Phase 3 整合时 current stockOut API 需要能传 unitCost**——销售出库目前传 `null`（ADR 0001），批次出库需要传批次的具体成本。

### ❌ 需调整项 #2：Phase 3 销售出库批次整合需要同时传 `unitCost`

当前销售出库 audit 传 `stockOut(materialId, warehouseId, actualQty, null, null, "销售出库", code)`。批次出库时不应该传 null——应该传该批次的成本（从批次表查）。这个问题在 Phase 3 设计时需要解决，当前草案未涉及。

**建议**：在 Phase 2 中设计 `c_mes_batch_inventory` 表时，预留 `unit_cost` 字段（入库时从采购收货获取）。Phase 3 出库时从批次库存获取 `unitCost` 传到 `stockOut`。

---

## 四、逐问题回答

### Q1: 3 Phase 拆分粒度

**评审结论：合理。** 但 Phase 1 不是"必须"在 Phase 2 之前完成——两者没有数据依赖。如果优先需要批次功能，可以先做 Phase 2。当前建议的 Phase 1→2→3 顺序对用户体验最好（先让制造模块更好用，再加批次功能）。

### Q2: 批次粒度

**评审结论：按批次号。** 草案的正确方向。按单据号的方案在以下场景会出问题：
- 一个生产订单分两批次采购原料 → 不同成本 → 需要两个批次
- 一个生产批次产出物需要分不同入库 → 批次号保留一致

**但需要补充设计**：批次号生成规则。建议用 `BT-{物料编码}-{YYYYMMDD}-{序号}` 格式，由系统自动生成。

### Q3: 批次状态机

| 状态 | 含义 | 颜色 | 说明 |
|:--:|------|:--:|------|
| 1 | 在用 | green | 库存>0，正常可用 |
| 2 | 冻结 | orange | 质检不合格或其他原因禁止使用 |
| 3 | 已耗尽 | gray | 库存=0 |
| 4 | 过期 | red | 超过效期 |

### ❌ 需调整项 #3：批次状态机不需要"待入库"中间态

采购收货时直接创建批次（状态=1 在用），不需要"待入库"中间态。理由：
- 如果收货后审核才入库→"待入库"是收货的 status='1' 草稿，不是批次的
- 如果收货即创建批次→status='1' 在用，简单直接
- 6 状态版本多出来的"即将过期"不是批次状态，而是告警触发器（Phase 2 范围外）

**结论**：4 状态足够。

### Q4: R5 成本冲突

已在上方详细分析。总结：共存可行，Phase 2 表设计时预埋 `unit_cost`，Phase 3 读取。

### Q5: 物料未启用批次时如何降级

### ❌ 需调整项 #4：完工入库强制创建批次的降级策略

草案说"强制创建生产批次"。但物料可能未启用 `batch_enabled`。

**建议**：三阶段降级：
```
完工入库 audit
  ├── 物料 batch_enabled=1 → 强制创建新批次（系统生成批次号）
  ├── 物料 batch_enabled=0 → 不创建批次，直接 stockIn（不传 unitCost，与当前行为一致）
  └── 物料 batch_enabled 字段为 null → 等同 0（向后兼容）
```

**不要默认创建**——每个完工入库都创建一个无用的空批次，数据库膨胀。

### Q6: 字典 4 vs 6 状态

已确认：4 状态（在用/冻结/已耗尽/过期）。"待激活"不是批次状态（是质检状态），"即将过期"是告警触发器。

### Q7: 批次追溯深度

### ❌ 需调整项 #5：批次追溯不应在当前 Phase 做

批次追溯链（采购→收货→入库→出库→销售）是全链路功能，需要每个环节写入批次台账。当前 4 整合点只覆盖了 3 个（收货/领料/完工入库/销售出库），缺少采购申请追溯（供应商批次号映射）。

**建议**：Phase 2 只做"批次号反查"（按批次号查哪些单据用了它），不做完整追溯图。完整追溯图在后续独立 Phase。

### Q8: 采购收货整合——批次号来源

**评审结论：系统生成，映射供应商批次号。**

| 字段 | 来源 | 说明 |
|------|------|------|
| `batch_no` | 系统生成 `BT-{物料编码}-{YYYYMMDD}-{序号}` | 系统内部批次号 |
| `supplier_batch_no` | 采购收货时手工填写（可选） | 供应商批次号映射 |

采购收货时：选择采购订单→`loadOrderItemsForReceipt`→每个可入库行的物料如果 `batch_enabled=1`→自动创建批次行，批次号系统生成。

### Q9: FIFO 实现复杂度

**评审结论：Phase 3 中最复杂的部分。需要独立设计文档。**

与当前 `stockOut` 接口的关系：
- FIFO 只改变**选择哪个批次出库**的规则，不改变 `stockOut` 的调用方式
- 实现要点：查批次库存 → 按创建时间排序 → 从最早批次轮询扣除 → 批量出库后统一调 stockOut
- 不需要锁——`selectForUpdate` 在 `stockOut` 内部已经有了
- 不需要改 `stockOut` 接口——但需要能传 `unitCost`

**工作量**：FIFO 排序逻辑约 50 行。不涉及悲观锁。（前提是不用分布式锁——单服务情境下 FOR UPDATE 行锁足够）。

### Q10: ItemsSubTable 缺失补建

**已修正**（见上方需调整项 #1）：
- picking → 应补（有 Item entity + DDL）
- completion → 应补（有 Item entity + DDL）
- order → 不补（单表，无 Item entity）
- bom → 不补（配置表，非单据）

---

## 五、新增发现的问题

### ❌ 需调整项 #6：生产订单 7 状态颜色映射需修正

| 方案 | 颜色 | 阶段 |
|:--:|:--:|------|
| 1 草稿 | orange | 可编辑 |
| 2 已审核 | blue | 等待下达 |
| 3 已下达 | blue | 车间待生产 |
| 4 执行中 | **cyan** | 进行中 |
| 5 已完工 | green | 完成 |
| 6 已关闭 | default | 终止 |
| 7 已取消 | default | 终止 |

草案说 "4=青(执行中)"——正确。"5=绿/6=灰(关闭)/7=灰(取消)"——也正确。唯一问题是 2/3 都映射 blue 是否合适——3 已下达意味着车间已经知道要做了，应该和 2 区分吗？**建议不区分**——2 和 3 对 UI 来说都是"在流程中尚未生产"，区别是内部流程。

### ❌ 需调整项 #7：Phase 2 缺少批次库存的事务边界设计

`c_mes_batch_inventory` 的 `stockIn/stockOut` 需要和主库存 `c_mes_inventory` 的 `stockIn/stockOut` 在同一个事务内，否则会出现：
- 主库存增加了但批次库存未增加 → 物料汇总正确但批次追溯断链
- 反之亦然

**建议**：Phase 2 中 `MesBatchInventoryService` 的写入操作必须和 `MesInventoryServiceImpl` 共享事务。设计为在 Phase 3 整合点的 audit 方法中调用（`stockIn(main) + batchStockIn(batch)` in one @Transactional）。

---

## 六、修正后的文件统计

| Phase | 后端 | 前端 | SQL | 总计 | 变化 |
|---|:---:|:---:|:---:|:---:|------|
| 1 | 0 | 18 | 0 | 18 | +2（+statusColor +picking+completion ItemsSubTable） |
| 2 | 24 | 16 | 1 | 41 | 不变 |
| 3 | 5 | 5 | 1 | 11 | 不变 |
| **合计** | **29** | **39** | **2** | **70** | **71 files** |

---

## 七、总判定

| 标准 | 评分 | 说明 |
|------|:--:|------|
| 3 Phase 拆分 | ✅ | 依赖正确的，Phase 1/2 可独立交付 |
| 批次粒度 | ✅ | 按批次号，灵活且符合实际业务 |
| 状态机 | ✅ | 4 状态完整，不需要"待入库"中间态 |
| 成本冲突 | ⚠️ | Phase 2 表设计时预埋 unit_cost，Phase 3 传参 |
| 降级策略 | ⚠️ | batch_enabled=0 时不应创建批次（防数据库膨胀） |
| 文件统计 | ⚠️ | 订正为 71（+2 ItemSubTable，-1 order SubTable） |
| FIFO 复杂度 | ✅ | 约 50 行，不需要分布式锁 |
| Phase 3 事务边界 | ⚠️ | 主库存+批次库存需要同一事务 |

**判定：PASS — 7 项需调整后执行。无阻塞。**

| # | 调整项 | 严重度 | Phase |
|---|--------|:--:|:--:|
| 1 | 生产订单无 Item→不需要 ItemsSubTable，补 picking/completion 的 | 🟡 | 1 |
| 2 | Phase 2 批次库存表预埋 unit_cost 字段 | 🟡 | 2 |
| 3 | 批次状态机 4 状态，不要"待入库" | 🟡 | 2 |
| 4 | 完工入库降级：batch_enabled=0 不创建批次 | 🟡 | 3 |
| 5 | Phase 2 不做完整追溯图（降级为批次号反查） | 🟡 | 2 |
| 6 | 生产订单 7 状态颜色正确但需确认 | 🟡 | 1 |
| 7 | 主库存+批次库存事务边界需同 @Transactional | 🟡 | 3 |
