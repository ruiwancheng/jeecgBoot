-- V9.7.1: 采购链路补齐 — 申请↔订单关联
-- ============================================================
-- 1. c_mes_purchase_apply 新增 supplierId + purchaseType
-- ============================================================
DROP PROCEDURE IF EXISTS add_apply_link_columns;
DELIMITER //
CREATE PROCEDURE add_apply_link_columns()
BEGIN
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_purchase_apply' AND COLUMN_NAME = 'supplier_id') THEN
    ALTER TABLE c_mes_purchase_apply ADD COLUMN supplier_id varchar(32) DEFAULT NULL COMMENT '供应商ID';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_purchase_apply' AND COLUMN_NAME = 'purchase_type') THEN
    ALTER TABLE c_mes_purchase_apply ADD COLUMN purchase_type varchar(20) DEFAULT NULL COMMENT '采购类型(dict:mes_purchase_type)';
  END IF;
END//
DELIMITER ;
CALL add_apply_link_columns();
DROP PROCEDURE IF EXISTS add_apply_link_columns;

-- ============================================================
-- 2. c_mes_purchase_order 新增 purchaseApplyId
-- ============================================================
DROP PROCEDURE IF EXISTS add_order_apply_id;
DELIMITER //
CREATE PROCEDURE add_order_apply_id()
BEGIN
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_purchase_order' AND COLUMN_NAME = 'purchase_apply_id') THEN
    ALTER TABLE c_mes_purchase_order ADD COLUMN purchase_apply_id varchar(32) DEFAULT NULL COMMENT '采购申请单ID';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_purchase_order' AND INDEX_NAME = 'idx_po_apply_id') THEN
    CREATE INDEX idx_po_apply_id ON c_mes_purchase_order(purchase_apply_id);
  END IF;
END//
DELIMITER ;
CALL add_order_apply_id();
DROP PROCEDURE IF EXISTS add_order_apply_id;

-- ============================================================
-- 3. c_mes_purchase_apply_item 新增 taxRate
-- ============================================================
DROP PROCEDURE IF EXISTS add_apply_item_tax;
DELIMITER //
CREATE PROCEDURE add_apply_item_tax()
BEGIN
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_purchase_apply_item' AND COLUMN_NAME = 'tax_rate') THEN
    ALTER TABLE c_mes_purchase_apply_item ADD COLUMN tax_rate decimal(18,4) DEFAULT 0.1300 COMMENT '税率';
  END IF;
END//
DELIMITER ;
CALL add_apply_item_tax();
DROP PROCEDURE IF EXISTS add_apply_item_tax;
