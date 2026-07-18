-- MES 销售模块 V7.0.4 — 审计P0修复：补充缺失数据库索引
-- 日期: 2026-07-18
-- 审计: 铁拳团10人审计，研发大牛1号+测试牛马3号共识发现

-- ============================================================
-- 1. c_mes_sales_order — 按客户查询 + 按创建时间排序
-- ============================================================
-- 先检查列存在再建索引（MySQL 5.7 不支持 IF NOT EXISTS for INDEX）
-- customer_id
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_sales_order' AND index_name = 'idx_order_customer_id');
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE c_mes_sales_order ADD INDEX idx_order_customer_id (customer_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- create_time
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_sales_order' AND index_name = 'idx_order_ctime');
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE c_mes_sales_order ADD INDEX idx_order_ctime (create_time)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 2. c_mes_sales_order_item — 按物料查询
-- ============================================================
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_sales_order_item' AND index_name = 'idx_item_material_id');
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE c_mes_sales_order_item ADD INDEX idx_item_material_id (material_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 3. c_mes_delivery_note — 按创建时间排序
-- ============================================================
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_delivery_note' AND index_name = 'idx_delivery_ctime');
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE c_mes_delivery_note ADD INDEX idx_delivery_ctime (create_time)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 4. c_mes_delivery_note_item — 按物料查询
-- ============================================================
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_delivery_note_item' AND index_name = 'idx_de_item_material_id');
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE c_mes_delivery_note_item ADD INDEX idx_de_item_material_id (material_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 5. c_mes_sales_outbound_item — 按物料查询
-- ============================================================
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_sales_outbound_item' AND index_name = 'idx_obi_material_id');
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE c_mes_sales_outbound_item ADD INDEX idx_obi_material_id (material_id)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 6. c_mes_price — 价格重叠校验复合索引
-- ============================================================
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_price' AND index_name = 'idx_price_overlap');
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE c_mes_price ADD INDEX idx_price_overlap (material_id, status, customer_id, begin_date, end_date)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
