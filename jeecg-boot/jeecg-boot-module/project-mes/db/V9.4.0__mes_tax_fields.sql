-- MES V9.4.0 — 税率字段补齐
-- c_mes_sales_order_item
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema = DATABASE() AND table_name = 'c_mes_sales_order_item' AND column_name = 'tax_rate');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_sales_order_item ADD COLUMN tax_rate DECIMAL(5,2) DEFAULT 0.13 COMMENT ''税率''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema = DATABASE() AND table_name = 'c_mes_sales_order_item' AND column_name = 'tax_amount');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_sales_order_item ADD COLUMN tax_amount DECIMAL(18,2) DEFAULT NULL COMMENT ''税额''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- c_mes_receivable
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema = DATABASE() AND table_name = 'c_mes_receivable' AND column_name = 'tax_amount');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_receivable ADD COLUMN tax_amount DECIMAL(18,2) DEFAULT NULL COMMENT ''税额''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- c_mes_payable
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema = DATABASE() AND table_name = 'c_mes_payable' AND column_name = 'tax_amount');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_payable ADD COLUMN tax_amount DECIMAL(18,2) DEFAULT NULL COMMENT ''税额''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
