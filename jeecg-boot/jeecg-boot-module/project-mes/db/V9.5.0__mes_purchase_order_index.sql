-- MES V9.5.0 — 采购订单索引补齐（铁拳团审计 P1-7）
-- create_time 排序索引（列表 ORDER BY create_time DESC 走全表扫描）
-- status 过滤索引（搜索区按状态筛选）

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_order' AND column_name = 'create_time');
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_order' AND index_name = 'idx_po_create_time');
SET @sql = IF(@col_exists = 1 AND @idx_exists = 0, 'CREATE INDEX idx_po_create_time ON c_mes_purchase_order (create_time)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_order' AND index_name = 'idx_po_status');
SET @sql = IF(@idx_exists = 0, 'CREATE INDEX idx_po_status ON c_mes_purchase_order (status)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
