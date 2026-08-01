-- ============================================================
-- V8.0.3 生产批次号手工录入 + 唯一索引隔离
-- 背景：原 c_mes_batch.batch_no 唯一索引 uk_batch_no_del (batch_no, del_flag)
--       跨物料不允许重号，与实际业务脱节（不同商品可能用相同批次号）。
-- 改：按 (material_id, batch_no, del_flag) 组合唯一；批次号改为手工录入。
-- 幂等性：所有 DDL 用 information_schema + PREPARE 模式包装，重跑不报错
--       （与 V9.0.1 同款模式）。
-- ============================================================

-- 1) 清空历史数据（用户要求"历史数据直接删除"）
DELETE FROM c_mes_batch_ledger;
DELETE FROM c_mes_batch_inventory;
DELETE FROM c_mes_batch;

-- 2) 删旧的全表唯一索引（幂等：先查索引是否存在）
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_batch' AND index_name = 'uk_batch_no_del');
SET @sql = IF(@idx_exists > 0,
  'ALTER TABLE c_mes_batch DROP INDEX uk_batch_no_del',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) 加新的组合唯一索引（幂等：先查索引是否不存在）
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_batch' AND index_name = 'uk_batch_material_no_del');
SET @sql = IF(@idx_exists = 0,
  'ALTER TABLE c_mes_batch ADD UNIQUE INDEX uk_batch_material_no_del (material_id, batch_no, del_flag)',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4) 改 c_mes_batch.batch_no 字段注释（从"系统生成"改为"手工录入"）
ALTER TABLE c_mes_batch
  MODIFY COLUMN batch_no VARCHAR(50) NOT NULL COMMENT '批次号(手工录入，不同物料可重号)';

-- 5) c_mes_purchase_receipt_item 加 batch_no + production_date 字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'batch_no');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN batch_no VARCHAR(50) DEFAULT NULL COMMENT ''生产批次号(手工录入)''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'production_date');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN production_date DATE DEFAULT NULL COMMENT ''生产日期''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 6) c_mes_completion_receipt_item 加 batch_no + production_date 字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_completion_receipt_item' AND column_name = 'batch_no');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_completion_receipt_item ADD COLUMN batch_no VARCHAR(50) DEFAULT NULL COMMENT ''生产批次号(手工录入)''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_completion_receipt_item' AND column_name = 'production_date');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_completion_receipt_item ADD COLUMN production_date DATE DEFAULT NULL COMMENT ''生产日期''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
