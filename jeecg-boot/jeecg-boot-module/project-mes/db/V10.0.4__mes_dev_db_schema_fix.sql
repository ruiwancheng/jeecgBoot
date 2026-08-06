-- update-begin---author:pi---date:2026-08-06---for:【DEV-DB-FIX】回归测试发现的 dev DB 字段缺失补齐（c_mes_other_stock_in 系列表 + tax_rate + unit_cost）---
-- MES V10.0.4 — dev DB 字段/表补齐（回归测试发现）
--
-- 背景：
--   dev profile 下 flyway.enabled=false（见 application-dev.yml），所有 MES 项目专属 SQL
--   不会被自动执行。回归测试发现以下表/列缺失导致链路失败：
--   1. c_mes_other_stock_in / out / _item 四张表完全缺失（V9.8.0 + V9.8.1 未执行）
--   2. c_mes_purchase_receipt_item 缺 tax_rate 列（V9.4.0 只补了 sales_order_item 等）
--   3. c_mes_batch_inventory 缺 unit_cost 列（V10.0.2 已定义但 dev DB 未初始化）
--
-- 修复：
--   本文件用 idempotent ALTER 补齐上述 2 个缺失列，其他表通过手动执行 V9.8.0/V9.8.1/V10.0.2 补齐。
--   MySQL 5.7 兼容：不使用 DROP INDEX IF EXISTS / ADD COLUMN IF NOT EXISTS，用 information_schema 判断。

-- 1) c_mes_purchase_receipt_item + tax_rate
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'tax_rate');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN tax_rate DECIMAL(5,2) DEFAULT 0.13 COMMENT ''税率(0.13=13%)''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1b) c_mes_purchase_receipt_item + batch_no（V8.0.3 定义）
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'batch_no');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN batch_no VARCHAR(50) DEFAULT NULL COMMENT ''生产批次号(手工录入)''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1c) c_mes_purchase_receipt_item + production_date（V8.0.3 定义）
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'production_date');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN production_date DATETIME DEFAULT NULL COMMENT ''生产日期''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1d) c_mes_purchase_receipt_item + shelf_life（V10.0.0 定义）
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'shelf_life');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN shelf_life INT DEFAULT NULL COMMENT ''保质期(天)''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1e) c_mes_purchase_receipt_item + expiry_date（V10.0.0 定义）
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'expiry_date');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN expiry_date DATETIME DEFAULT NULL COMMENT ''有效期至''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) c_mes_batch_inventory + unit_cost
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_batch_inventory' AND column_name = 'unit_cost');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_batch_inventory ADD COLUMN unit_cost DECIMAL(18,4) DEFAULT 0.0000 COMMENT ''批次单位成本(冗余便于出库取值)''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) c_mes_other_stock_in/out 四张表（CREATE IF NOT EXISTS 已包含在 V9.8.0，可在此冗余声明以保证幂等）
CREATE TABLE IF NOT EXISTS c_mes_other_stock_in (
    id                VARCHAR(32)  NOT NULL COMMENT '主键',
    code              VARCHAR(50)  NOT NULL COMMENT '入库单号',
    in_type           VARCHAR(20)  COMMENT '入库类型(dict:mes_other_stock_in_type)',
    reason            VARCHAR(500) COMMENT '原因(手工填)',
    stock_date        DATETIME     COMMENT '出入库日期',
    status            VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_other_stock_status)',
    remark            VARCHAR(500) COMMENT '备注',
    create_by         VARCHAR(50)  COMMENT '创建人',
    create_time       DATETIME     COMMENT '创建时间',
    update_by         VARCHAR(50)  COMMENT '更新人',
    update_time       DATETIME     COMMENT '更新时间',
    del_flag          INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_other_stock_in_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-其它入库';

CREATE TABLE IF NOT EXISTS c_mes_other_stock_out (
    id                VARCHAR(32)  NOT NULL COMMENT '主键',
    code              VARCHAR(50)  NOT NULL COMMENT '出库单号',
    out_type          VARCHAR(20)  COMMENT '出库类型(dict:mes_other_stock_out_type)',
    reason            VARCHAR(500) COMMENT '原因(手工填)',
    stock_date        DATETIME     COMMENT '出入库日期',
    status            VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_other_stock_status)',
    remark            VARCHAR(500) COMMENT '备注',
    create_by         VARCHAR(50)  COMMENT '创建人',
    create_time       DATETIME     COMMENT '创建时间',
    update_by         VARCHAR(50)  COMMENT '更新人',
    update_time       DATETIME     COMMENT '更新时间',
    del_flag          INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_other_stock_out_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-其它出库';

-- 注：c_mes_other_stock_in_item / out_item 需要 V9.8.0 + V9.8.1 配套执行（带 unit_cost/amount/warehouse_id 列）
-- 本文件不重复声明，避免与 V9.8.0/V9.8.1 不一致
-- update-end---author:pi---date:2026-08-06---for:【DEV-DB-FIX】回归测试发现的 dev DB 字段缺失补齐---
