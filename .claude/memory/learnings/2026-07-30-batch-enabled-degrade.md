# 物料启用批次管理用降级策略（防数据库膨胀）

**场景**：新增"物料启用批次管理"功能（material.batch_enabled 字段），但业务员不能一次性把所有物料启用（成本/管理压力）。

**反例（错误实现）**：
- ❌ 物料默认 batch_enabled=1
- ❌ 完工入库时强制创建批次，不管物料是否启用
- ❌ 所有物料都创建批次（可能 1000+ 物料，每个完工入库都建 1 个批次，几个月后批次表几十万行无用数据）

**正例（降级策略）**：

```java
// 1. 物料表加 batch_enabled 字段（默认 0 = 不启用）
ALTER TABLE c_mes_material ADD COLUMN batch_enabled INT DEFAULT 0;

// 2. Service 端先做主库存事务（无论是否启用都跑）
inventoryService.stockIn(materialId, warehouseId, qty, unitCost, costAmount, ...);

// 3. 再判断是否创建批次（仅 batch_enabled=1 时）
MesMaterial mat = materialMapper.selectById(materialId);
if (mat != null && Integer.valueOf(1).equals(mat.getBatchEnabled())) {
    String batchId = batchService.createBatch(...);
    batchInventoryService.stockIn(batchId, ...);
}
```

**关键点**：
- 物料档案单独勾选启用，不批量默认（避免一夜之间数据爆炸）
- 主库存事务永远先跑（保证库存一致性与物料启用状态解耦）
- 批次创建是"附加"而非"前置"（即使批次创建失败，主库存事务已提交）

**避免**：
- 默认 batch_enabled=1（业务上等于"强制启用"）
- 强制创建批次（让用户决定）
- 物料类型自动启用（同一类型物料可能只有部分需要批次）

**实证**：2026-07-31 批次管理 Phase 3 整合。完工入库、领料、销售出库 4 个集成点全部用此降级策略。测试时设 MAT-0004 batch_enabled=1 验证集成，测试完清回 0 避免后续影响。

**关联设计**：
- 物料档案页加 batch_enabled 字段（前端 checkbox）
- 物料列表批量启用功能（运营需要时一键启用）
- 批次追溯功能：所有 batch_enabled=1 的物料自动可追溯

**判断信号**：
- 某功能是"可选"还是"必选"——可选必用降级
- 涉及历史数据迁移——降级兼容老数据
- 性能/成本敏感——降级避免无谓开销