-- ============================================================
-- BOM 同父项一生效索引 + 老数据兜底
-- Plan: .claude/.last-plan.json (slice-6)
-- Impl: commit a07ec59 + this fix
-- ============================================================
-- BOM 状态机 approve 校验依赖索引（slice-1 MesBomMapper.countActiveByProductForUpdate FOR UPDATE）
ALTER TABLE c_mes_bom ADD INDEX idx_bom_product_status (product_id, status);

-- 老数据兜底：未审/未下达订单默认草稿（status='1'）
UPDATE c_mes_production_order SET status = '1' WHERE status IS NULL OR status = '';
UPDATE c_mes_production_picking SET status = '1' WHERE status IS NULL OR status = '';
UPDATE c_mes_completion_receipt SET status = '1' WHERE status IS NULL OR status = '';
