-- V9.7.0: MES 物料成本价体系 MVP
-- ============================================================
-- 1. c_mes_material 新增成本价字段
-- ============================================================
DROP PROCEDURE IF EXISTS add_material_cost_columns;
DELIMITER //
CREATE PROCEDURE add_material_cost_columns()
BEGIN
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_material' AND COLUMN_NAME = 'moving_avg_cost') THEN
    ALTER TABLE c_mes_material ADD COLUMN moving_avg_cost decimal(18,4) DEFAULT 0.0000 COMMENT '移动平均成本';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_material' AND COLUMN_NAME = 'last_purchase_price') THEN
    ALTER TABLE c_mes_material ADD COLUMN last_purchase_price decimal(18,4) DEFAULT NULL COMMENT '最近采购价(含税)';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_material' AND COLUMN_NAME = 'last_purchase_date') THEN
    ALTER TABLE c_mes_material ADD COLUMN last_purchase_date datetime DEFAULT NULL COMMENT '最近采购日期';
  END IF;
END//
DELIMITER ;
CALL add_material_cost_columns();
DROP PROCEDURE IF EXISTS add_material_cost_columns;

-- ============================================================
-- 2. c_mes_inventory_ledger 新增金额字段
-- ============================================================
DROP PROCEDURE IF EXISTS add_ledger_amount_columns;
DELIMITER //
CREATE PROCEDURE add_ledger_amount_columns()
BEGIN
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_inventory_ledger' AND COLUMN_NAME = 'unit_cost') THEN
    ALTER TABLE c_mes_inventory_ledger ADD COLUMN unit_cost decimal(18,4) DEFAULT NULL COMMENT '单位成本';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_inventory_ledger' AND COLUMN_NAME = 'in_amount') THEN
    ALTER TABLE c_mes_inventory_ledger ADD COLUMN in_amount decimal(18,2) DEFAULT NULL COMMENT '入库金额';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_inventory_ledger' AND COLUMN_NAME = 'out_amount') THEN
    ALTER TABLE c_mes_inventory_ledger ADD COLUMN out_amount decimal(18,2) DEFAULT NULL COMMENT '出库金额';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_inventory_ledger' AND COLUMN_NAME = 'beginning_amount') THEN
    ALTER TABLE c_mes_inventory_ledger ADD COLUMN beginning_amount decimal(18,2) DEFAULT 0.00 COMMENT '期初金额';
  END IF;
  IF NOT EXISTS (SELECT * FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_inventory_ledger' AND COLUMN_NAME = 'ending_amount') THEN
    ALTER TABLE c_mes_inventory_ledger ADD COLUMN ending_amount decimal(18,2) DEFAULT 0.00 COMMENT '期末金额';
  END IF;
END//
DELIMITER ;
CALL add_ledger_amount_columns();
DROP PROCEDURE IF EXISTS add_ledger_amount_columns;

-- ============================================================
-- 3. 新建成本变动日志表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_cost_log (
    id varchar(32) NOT NULL COMMENT 'ID',
    material_id varchar(32) NOT NULL COMMENT '物料ID',
    warehouse_id varchar(32) DEFAULT NULL COMMENT '仓库ID',
    biz_type varchar(50) NOT NULL COMMENT '业务类型(采购入库/采购退货/完工入库/成本调整)',
    biz_id varchar(100) NOT NULL COMMENT '业务单号',
    qty decimal(18,2) NOT NULL COMMENT '变动数量(+入库/-出库)',
    unit_cost decimal(18,4) NOT NULL COMMENT '本次单位成本',
    amount decimal(18,2) NOT NULL COMMENT '本次金额',
    cost_before decimal(18,4) NOT NULL COMMENT '变动前移动平均成本',
    cost_after decimal(18,4) NOT NULL COMMENT '变动后移动平均成本',
    qty_before decimal(18,2) NOT NULL COMMENT '变动前库存总数量',
    qty_after decimal(18,2) NOT NULL COMMENT '变动后库存总数量',
    create_by varchar(50) DEFAULT NULL COMMENT '操作人',
    create_time datetime DEFAULT NULL COMMENT '操作时间',
    PRIMARY KEY (id),
    INDEX idx_cost_log_material (material_id),
    INDEX idx_cost_log_biz (biz_id),
    INDEX idx_cost_log_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-成本变动日志';
