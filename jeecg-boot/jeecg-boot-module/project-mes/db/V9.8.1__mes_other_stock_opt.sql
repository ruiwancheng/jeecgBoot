-- MES 其它出入库优化 V9.8.1
-- 1. 明细删库位/仓库（库位属上架下架，单仓单仓库上主表）
-- 2. 主表加仓库/总金额，明细加成本单价/金额（手工录入成本单价，审核按快照改库存金额）
-- 存储过程守卫保证幂等（MySQL 5.7 无 ADD COLUMN IF NOT EXISTS）

DELIMITER //
DROP PROCEDURE IF EXISTS alter_other_stock_tables//
CREATE PROCEDURE alter_other_stock_tables()
BEGIN
  -- 主表：+仓库 +总金额
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_in' AND COLUMN_NAME = 'warehouse_id') THEN
    ALTER TABLE c_mes_other_stock_in ADD COLUMN warehouse_id VARCHAR(32) COMMENT '仓库ID(单据级,单仓单)' AFTER in_type;
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_in' AND COLUMN_NAME = 'total_amount') THEN
    ALTER TABLE c_mes_other_stock_in ADD COLUMN total_amount DECIMAL(18,2) DEFAULT 0.00 COMMENT '总金额';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_out' AND COLUMN_NAME = 'warehouse_id') THEN
    ALTER TABLE c_mes_other_stock_out ADD COLUMN warehouse_id VARCHAR(32) COMMENT '仓库ID(单据级,单仓单)' AFTER out_type;
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_out' AND COLUMN_NAME = 'total_amount') THEN
    ALTER TABLE c_mes_other_stock_out ADD COLUMN total_amount DECIMAL(18,2) DEFAULT 0.00 COMMENT '总金额';
  END IF;

  -- 明细：-库位 -仓库 +成本单价 +金额
  IF EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_in_item' AND COLUMN_NAME = 'location_id') THEN
    ALTER TABLE c_mes_other_stock_in_item DROP COLUMN location_id;
  END IF;
  IF EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_in_item' AND COLUMN_NAME = 'warehouse_id') THEN
    ALTER TABLE c_mes_other_stock_in_item DROP COLUMN warehouse_id;
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_in_item' AND COLUMN_NAME = 'unit_cost') THEN
    ALTER TABLE c_mes_other_stock_in_item ADD COLUMN unit_cost DECIMAL(18,4) DEFAULT 0.0000 COMMENT '成本单价(手工录入,审核快照)';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_in_item' AND COLUMN_NAME = 'amount') THEN
    ALTER TABLE c_mes_other_stock_in_item ADD COLUMN amount DECIMAL(18,2) DEFAULT 0.00 COMMENT '金额(qty*unit_cost)';
  END IF;

  IF EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_out_item' AND COLUMN_NAME = 'location_id') THEN
    ALTER TABLE c_mes_other_stock_out_item DROP COLUMN location_id;
  END IF;
  IF EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_out_item' AND COLUMN_NAME = 'warehouse_id') THEN
    ALTER TABLE c_mes_other_stock_out_item DROP COLUMN warehouse_id;
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_out_item' AND COLUMN_NAME = 'unit_cost') THEN
    ALTER TABLE c_mes_other_stock_out_item ADD COLUMN unit_cost DECIMAL(18,4) DEFAULT 0.0000 COMMENT '成本单价(手工录入,审核快照)';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_other_stock_out_item' AND COLUMN_NAME = 'amount') THEN
    ALTER TABLE c_mes_other_stock_out_item ADD COLUMN amount DECIMAL(18,2) DEFAULT 0.00 COMMENT '金额(qty*unit_cost)';
  END IF;
END//
DELIMITER ;
CALL alter_other_stock_tables();
DROP PROCEDURE IF EXISTS alter_other_stock_tables;
