-- MES 财务模块 V9.0.1 — 审计P0修复
-- P0-01 采购入库明细补金额字段 + P0-06 应收应付补唯一索引

-- ============================================================
-- P0-01: 采购入库明细补 unit_price / amount
-- ============================================================
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'unit_price');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN unit_price DECIMAL(18,2) DEFAULT NULL COMMENT ''单价''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'amount');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN amount DECIMAL(18,2) DEFAULT NULL COMMENT ''金额''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- P0-06: 应收/应付 source_bill_id 唯一索引（防重复生成）
-- ============================================================
SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_receivable' AND index_name = 'uk_rec_source_bill');
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE c_mes_receivable ADD UNIQUE INDEX uk_rec_source_bill (source_bill_id, del_flag)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.STATISTICS
    WHERE table_schema = DATABASE() AND table_name = 'c_mes_payable' AND index_name = 'uk_pay_source_bill');
SET @sql = IF(@idx_exists = 0, 'ALTER TABLE c_mes_payable ADD UNIQUE INDEX uk_pay_source_bill (source_bill_id, del_flag)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
