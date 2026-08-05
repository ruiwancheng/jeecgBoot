-- ============================================================
-- V10.0.1  物料表/台账表补充缺失列（Docker 数据库未执行 V10.0.0 迁移）
-- 作者: ruiwancheng  日期: 2026-08-06
-- 问题1：c_mes_material 缺少 batch_enabled / shelf_life，导致 list 500
-- 问题2：c_mes_inventory_ledger 缺少 remark，导致台账 list 500
-- 兼容 MySQL 5.7：information_schema + PREPARE 幂等 ADD COLUMN
-- ============================================================

SET @db = DATABASE();

-- 1) batch_enabled：是否启用批次管理
SET @col_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='c_mes_material' AND COLUMN_NAME='batch_enabled');
SET @sql := IF(@col_exists=0,
  'ALTER TABLE c_mes_material ADD COLUMN batch_enabled INT DEFAULT 0 COMMENT ''是否启用批次管理(0否/1是,默认0)'' AFTER last_purchase_date',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) shelf_life：保质期(天)
SET @col_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='c_mes_material' AND COLUMN_NAME='shelf_life');
SET @sql := IF(@col_exists=0,
  'ALTER TABLE c_mes_material ADD COLUMN shelf_life INT DEFAULT NULL COMMENT ''保质期(天)'' AFTER batch_enabled',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 3) 台账备注 remark（c_mes_inventory_ledger 缺少 remark 导致 list 500）
-- ============================================================
SET @db = DATABASE();

SET @col_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='c_mes_inventory_ledger' AND COLUMN_NAME='remark');
SET @sql := IF(@col_exists=0,
  'ALTER TABLE c_mes_inventory_ledger ADD COLUMN remark VARCHAR(500) DEFAULT NULL COMMENT ''台账备注'' AFTER ending_amount',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
