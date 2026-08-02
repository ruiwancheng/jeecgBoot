-- ============================================================
-- V10.0.3  MES批次追溯-批次级列表改造
-- 作者:ruiwancheng  日期:2026-08-03
--
-- 业务改动：
--   - 批次追溯页面(/mes/batch/traceability/list) 改为批次级（V10.0.2 误为流水级）
--   - 实体 MesBatchTraceabilityVO 聚合自 c_mes_batch + c_mes_batch_ledger
--   - 复用现有 idx_bl_batch (batch_id) 索引 + 新增 (batch_id, del_flag) 复合索引
--   - 不新建独立表，不改字段
--
-- 设计意图留痕：
--   - 列表粒度 = 批次级（每个 batch_id 一行）
--   - 累计 in_qty/out_qty 聚合自 ledger
--   - 抽屉详情仍用 ledger 模块 listByBatchId 端点
-- ============================================================

-- 1. 复合索引（MySQL 5.7 兼容：存储过程判定）
-- 加速 LEFT JOIN c_mes_batch_ledger ON l.batch_id = b.id AND l.del_flag = 0
-- 同时惠及 ledger 模块的 listByBatchId 查询
DROP PROCEDURE IF EXISTS mes_add_batch_ledger_idx;
DELIMITER //
CREATE PROCEDURE mes_add_batch_ledger_idx()
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.statistics
                   WHERE table_schema = DATABASE()
                     AND table_name = 'c_mes_batch_ledger'
                     AND index_name = 'idx_bl_batch_del') THEN
        CREATE INDEX idx_bl_batch_del ON c_mes_batch_ledger(batch_id, del_flag);
    END IF;
END //
DELIMITER ;
CALL mes_add_batch_ledger_idx();
DROP PROCEDURE IF EXISTS mes_add_batch_ledger_idx;

-- 2. 版本锚点（无 DDL/DML）
SELECT 1;
