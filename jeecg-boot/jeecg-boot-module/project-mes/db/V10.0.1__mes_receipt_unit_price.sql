-- ============================================================
-- V10.0.1  采购入库明细：税率字段 + unit_price 注释修正
-- 作者:ruiwancheng  日期:2026-08-03
-- 涉及表:
--   c_mes_purchase_receipt_item
--     + tax_rate DECIMAL(5,2) DEFAULT 0.13  COMMENT '税率(0~1)'
--     * unit_price COMMENT 由"单价"改为"单价(不含税)"（语义对齐 Entity @Schema）
-- 兼容 MySQL 5.7：用 information_schema + PREPARE 实现幂等 ADD/MODIFY COLUMN
-- ============================================================

SET @db = DATABASE();

-- 1) 采购入库明细：税率字段
SET @col_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='c_mes_purchase_receipt_item' AND COLUMN_NAME='tax_rate');
SET @sql := IF(@col_exists=0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN tax_rate DECIMAL(5,2) DEFAULT 0.13 COMMENT ''税率(0~1)'' AFTER unit_price',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) 修正 unit_price 列注释（V9.0.1 注释"单价"语义模糊，统一改为"单价(不含税)"）
SET @col_exists := (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA=@db AND TABLE_NAME='c_mes_purchase_receipt_item' AND COLUMN_NAME='unit_price');
SET @sql := IF(@col_exists=1,
  'ALTER TABLE c_mes_purchase_receipt_item MODIFY COLUMN unit_price DECIMAL(18,2) DEFAULT NULL COMMENT ''单价(不含税)''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) 历史数据回填：已有入库明细的税率默认按 0.13 计算（不修改 unit_price，避免影响既有审核逻辑）
UPDATE c_mes_purchase_receipt_item
SET tax_rate = 0.13
WHERE tax_rate IS NULL;