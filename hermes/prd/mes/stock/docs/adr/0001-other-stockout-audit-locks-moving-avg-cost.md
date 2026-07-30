# 其它出库金额按物料移动平均成本锁定（audit 强制重算）

其它出库单审核（audit）时，强制用物料当前移动平均成本重算明细的 unit_cost 和 amount，并持久化到 `c_mes_other_stock_out_item`，不采用用户在草稿态录入的成本。**出库不改变移动平均成本**（物料 `c_mes_material.moving_avg_cost` 在出库前后保持不变），但记账金额必须按"出库时的物料成本"对齐，否则总账（出库金额）与库存账（数量 × 物料成本）持续偏离，每次出库都会少记/多记金额。

> Status: accepted (2026-07-30)

## Context

之前实现里 audit 把草稿态用户录入的 `unit_cost` 直接传给 `inventoryService.stockOut(...)` 计算出库金额。结果：

| 场景 | 出库前库存 | movingAvgCost | 出库数量 | 出库金额（应） | 出库金额（实） | 差异 |
|---|---|---|---|---|---|---|
| MAT-0004 / 仓库1 | 3 × 177.7778 = 533.33 | 177.7778 | 1 | **177.78** | 160（用户改） | **17.78** |

总账比库存账少 17.78。每月做账不平。修复实测：改 unitCost=177.7778 + amount=177.78 后，台账、主表、库存金额三处一致。

## Decision

`MesOtherStockOutServiceImpl.audit()` 在调用 `inventoryService.stockOut(...)` 前：

1. 读物料 `moving_avg_cost`（无锁读，因为出库不改变它，不与入库并发冲突）
2. 重算明细 `unit_cost = movingAvgCost`，`amount = qty × unit_cost`（保留 2 位小数，HALF_UP）
3. 持久化到 `c_mes_other_stock_out_item`（`itemMapper.updateById(item)`）
4. 同步刷新主表 `total_amount`（明细金额合计）
5. 用锁定值调 `inventoryService.stockOut(...)`（台账 `out_amount` 同步锁定）

`MesOtherStockOutServiceImpl.unaudit()` **不动**——已用明细表的 unit_cost/amount 作为红冲值，自动继承锁定语义。

入库 audit/unaudit **不动**——用户录入 unitCost 是"新入库成本"（设计如此），`stockIn` 内部按用户值重算 `moving_avg_cost`，逻辑自洽。

## Considered Options

| # | 方案 | 拒绝原因 |
|---|---|---|
| **A** | audit 强制锁定物料 movingAvgCost（**采纳**） | — |
| B | 前端 unitCost 字段只读 | 失去报废残值等场景的灵活性；不解决后端信任问题 |
| C | 保留用户录入 + 强校验（差异>5% 必填备注） | UX 复杂；规则需业务方反复确认 |
| D | 标记为已知特性，不修复 | 持续产生账实差异，数据不可信 |

## Consequences

- ✅ 总账与库存账一致（修复后的 QT-OUT20260730-0007 测试：out_amount 177.78 = 库存减少 177.77，差异仅四舍五入）
- ✅ unaudit 红冲用同一锁定值，账实仍一致（不重新查物料，避免被期间入库改动导致偏差）
- ⚠️ 用户录入的 unitCost 仅在草稿态有显示意义，audit 后被覆盖（前端提示"自动锁定只读"待补）
- ⚠️ 历史出库单可能存在 unit_cost 偏离（未回算），需跑核对清单手工处理：见 `hermes/prd/mes/stock/CONTEXT.md` 中"成本锁定"术语的查询示例
- ⚠️ 出库 audit 并发与入库 audit 同时改 movingAvgCost 时，出库读到的成本可能略滞后（无锁读），但账实差异 ≤ 一次入库金额量级（业务可接受）

## References

- 修复代码：`jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/stock/service/impl/MesOtherStockOutServiceImpl.java` audit() 方法（含 `update-begin/end` 痕迹）
- 业务术语：`hermes/prd/mes/stock/CONTEXT.md` 中"入库金额""出库金额""成本锁定"（v1.1 修订）
- 入库侧对称实现：`MesOtherStockInServiceImpl.audit()` 不动（用户录入 = 新成本）
- 反审核验证：`inventoryService.stockIn(...)` 红冲参数取自明细表 `unit_cost`/`amount`（自动继承锁定）