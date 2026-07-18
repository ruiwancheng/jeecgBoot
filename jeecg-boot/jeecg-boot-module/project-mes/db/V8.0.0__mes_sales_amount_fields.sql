-- MES 销售模块 V8.0.0 — Phase2 金额字段补齐
-- 出库单+发货单 增加 单价/金额/合计 字段
-- MySQL 5.7 兼容：INFORMATION_SCHEMA + 预处理语句，可重复执行

-- ============================================================
-- 1. c_mes_sales_outbound — 总金额
-- ============================================================
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_sales_outbound' AND column_name = 'total_amount');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_sales_outbound ADD COLUMN total_amount DECIMAL(18,2) DEFAULT NULL COMMENT ''总金额''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 2. c_mes_sales_outbound_item — 单价
-- ============================================================
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_sales_outbound_item' AND column_name = 'unit_price');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_sales_outbound_item ADD COLUMN unit_price DECIMAL(18,2) DEFAULT NULL COMMENT ''单价''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 3. c_mes_sales_outbound_item — 金额
-- ============================================================
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_sales_outbound_item' AND column_name = 'amount');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_sales_outbound_item ADD COLUMN amount DECIMAL(18,2) DEFAULT NULL COMMENT ''金额''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 4. c_mes_delivery_note — 总金额
-- ============================================================
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_delivery_note' AND column_name = 'total_amount');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_delivery_note ADD COLUMN total_amount DECIMAL(18,2) DEFAULT NULL COMMENT ''总金额''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 5. c_mes_delivery_note_item — 单价
-- ============================================================
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_delivery_note_item' AND column_name = 'unit_price');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_delivery_note_item ADD COLUMN unit_price DECIMAL(18,2) DEFAULT NULL COMMENT ''单价''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 6. c_mes_delivery_note_item — 金额
-- ============================================================
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_delivery_note_item' AND column_name = 'amount');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_delivery_note_item ADD COLUMN amount DECIMAL(18,2) DEFAULT NULL COMMENT ''金额''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
