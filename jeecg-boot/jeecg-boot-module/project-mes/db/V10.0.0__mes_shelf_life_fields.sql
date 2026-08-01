-- ============================================================
-- V10.0.0  物料/批次/采购入库：保质期(天) + 采购入库明细增加有效期至
-- 作者:ruiwancheng  日期:2026-08-02
-- 涉及表:
--   c_mes_material                + shelf_life
--   c_mes_batch                   + shelf_life
--   c_mes_purchase_receipt_item   + shelf_life, + expiry_date
-- 兼容 MySQL 5.7：用 information_schema + PREPARE 实现幂等 ADD COLUMN
-- ============================================================

SET @db = DATABASE();

-- 1) 物料主数据：保质期(天)
SET @col_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='c_mes_material' AND COLUMN_NAME='shelf_life');
SET @sql := IF(@col_exists=0,
  'ALTER TABLE c_mes_material ADD COLUMN shelf_life INT NULL COMMENT ''保质期(天)'' AFTER batch_enabled',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) 批次主档：保质期(天)
SET @col_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='c_mes_batch' AND COLUMN_NAME='shelf_life');
SET @sql := IF(@col_exists=0,
  'ALTER TABLE c_mes_batch ADD COLUMN shelf_life INT NULL COMMENT ''保质期(天)'' AFTER production_date',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) 采购入库明细：保质期(天)
SET @col_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='c_mes_purchase_receipt_item' AND COLUMN_NAME='shelf_life');
SET @sql := IF(@col_exists=0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN shelf_life INT NULL COMMENT ''保质期(天)'' AFTER production_date',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4) 采购入库明细：有效期至
SET @col_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='c_mes_purchase_receipt_item' AND COLUMN_NAME='expiry_date');
SET @sql := IF(@col_exists=0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN expiry_date DATETIME NULL COMMENT ''有效期至'' AFTER shelf_life',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
