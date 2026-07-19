-- MES V9.3.0 — 库存预警
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema = DATABASE() AND table_name = 'c_mes_material' AND column_name = 'safety_stock');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_material ADD COLUMN safety_stock DECIMAL(18,4) DEFAULT NULL COMMENT ''安全库存''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema = DATABASE() AND table_name = 'c_mes_material' AND column_name = 'max_stock');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_material ADD COLUMN max_stock DECIMAL(18,4) DEFAULT NULL COMMENT ''最高库存''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
