-- V10.1.2  修复 c_mes_customer / c_mes_supplier / 4 子表 schema 漂移
-- 2026-08-04 渗透测试 slice-2.1 发现 (BUG-CUSTOMER-SCHEMA-DRIFT P0)
--
-- 背景: start-local-backend.sh 用 spring.flyway.enabled=false,
-- 导致 V1.0.0 / V1.4.0 等所有升级 SQL 在 dev/test 环境未跑过,
-- c_mes_customer 缺字段(早期 V1.0.0 部分跑过但新字段未补), 4 个 customer 子表若不存在则整个销售链路阻断。
--
-- 注意: MySQL 8.4 不支持 ADD COLUMN IF NOT EXISTS (这是 MariaDB/PostgreSQL 特性),
-- 所以本脚本用 information_schema 检查 + 动态 SQL 拼接, 每个列独立执行。
-- 重复跑不会报错, 安全可重入。

-- ============================================================
-- 1. c_mes_customer 补字段(若 dev DB 缺)
-- ============================================================
SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'invoice_title';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_customer ADD COLUMN invoice_title VARCHAR(200) COMMENT "发票抬头"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'tax_no';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_customer ADD COLUMN tax_no VARCHAR(50) COMMENT "税号"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'bank_name';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_customer ADD COLUMN bank_name VARCHAR(100) COMMENT "开户银行"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'bank_account';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_customer ADD COLUMN bank_account VARCHAR(50) COMMENT "银行账号"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'invoice_address';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_customer ADD COLUMN invoice_address VARCHAR(300) COMMENT "开票地址"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'invoice_phone';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_customer ADD COLUMN invoice_phone VARCHAR(30) COMMENT "开票电话"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'invoice_type';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_customer ADD COLUMN invoice_type VARCHAR(10) COMMENT "发票类型(dict:invoice_type)"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 同样补 c_mes_supplier 字段(以防某些 dev DB 没跑 V1.4.0)
SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_supplier' AND COLUMN_NAME = 'invoice_title';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_supplier ADD COLUMN invoice_title VARCHAR(200) COMMENT "发票抬头"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_supplier' AND COLUMN_NAME = 'tax_no';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_supplier ADD COLUMN tax_no VARCHAR(50) COMMENT "税号"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_supplier' AND COLUMN_NAME = 'bank_name';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_supplier ADD COLUMN bank_name VARCHAR(100) COMMENT "开户银行"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col := NULL;
SELECT COLUMN_NAME INTO @col FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = 'jeecg-boot' AND TABLE_NAME = 'c_mes_supplier' AND COLUMN_NAME = 'bank_account';
SET @sql := IF(@col IS NULL, 'ALTER TABLE c_mes_supplier ADD COLUMN bank_account VARCHAR(50) COMMENT "银行账号"', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 2. customer 4 个子表 CREATE TABLE IF NOT EXISTS
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_customer_contact (
    id          VARCHAR(36)  NOT NULL COMMENT '主键',
    customer_id VARCHAR(36)  NOT NULL COMMENT '客户ID',
    name        VARCHAR(50)  COMMENT '姓名',
    title       VARCHAR(50)  COMMENT '职务',
    phone       VARCHAR(20)  COMMENT '手机',
    email       VARCHAR(100) COMMENT '邮箱',
    social      VARCHAR(100) COMMENT 'QQ/微信',
    is_default  TINYINT(1)   DEFAULT 0 COMMENT '是否默认',
    remark      VARCHAR(200) COMMENT '备注',
    create_by   VARCHAR(50)  COMMENT '创建人',
    create_time DATETIME     COMMENT '创建时间',
    update_by   VARCHAR(50)  COMMENT '更新人',
    update_time DATETIME     COMMENT '更新时间',
    del_flag    INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_contact_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户联系人';

CREATE TABLE IF NOT EXISTS c_mes_customer_address (
    id           VARCHAR(36)  NOT NULL COMMENT '主键',
    customer_id  VARCHAR(36)  NOT NULL COMMENT '客户ID',
    address_type VARCHAR(20)  COMMENT '地址类型(dict:address_type)',
    contact      VARCHAR(50)  COMMENT '联系人',
    phone        VARCHAR(20)  COMMENT '联系电话',
    province     VARCHAR(50)  COMMENT '省',
    city         VARCHAR(50)  COMMENT '市',
    district     VARCHAR(50)  COMMENT '区',
    detail       VARCHAR(300) COMMENT '详细地址',
    is_default   TINYINT(1)   DEFAULT 0 COMMENT '是否默认',
    remark       VARCHAR(200) COMMENT '备注',
    create_by    VARCHAR(50)  COMMENT '创建人',
    create_time  DATETIME     COMMENT '创建时间',
    update_by    VARCHAR(50)  COMMENT '更新人',
    update_time  DATETIME     COMMENT '更新时间',
    del_flag     INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_address_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf4mb4 COMMENT='MES-客户地址';

CREATE TABLE IF NOT EXISTS c_mes_customer_follow_up (
    id             VARCHAR(36)  NOT NULL COMMENT '主键',
    customer_id    VARCHAR(36)  NOT NULL COMMENT '客户ID',
    follow_type    VARCHAR(20)  COMMENT '跟进方式(dict:follow_type)',
    follow_date    DATETIME     COMMENT '跟进日期',
    content        VARCHAR(2000) COMMENT '跟进内容',
    follower       VARCHAR(50)  COMMENT '跟进人',
    next_date      DATETIME     COMMENT '下次跟进日期',
    attachment     VARCHAR(500) COMMENT '附件路径',
    remark         VARCHAR(500) COMMENT '备注',
    create_by      VARCHAR(50)  COMMENT '创建人',
    create_time    DATETIME     COMMENT '创建时间',
    update_by      VARCHAR(50)  COMMENT '更新人',
    update_time    DATETIME     COMMENT '更新时间',
    del_flag       INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_followup_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户跟进记录';

CREATE TABLE IF NOT EXISTS c_mes_customer_price (
    id          VARCHAR(36)  NOT NULL COMMENT '主键',
    customer_id VARCHAR(36)  NOT NULL COMMENT '客户ID',
    product_id  VARCHAR(36)  NOT NULL COMMENT '产品ID',
    price       DECIMAL(18,2) COMMENT '协议单价',
    begin_date  DATETIME     COMMENT '生效日期',
    end_date    DATETIME     COMMENT '失效日期',
    min_qty     DECIMAL(18,2) COMMENT '起订数量',
    max_qty     DECIMAL(18,2) COMMENT '截止数量',
    remark      VARCHAR(200) COMMENT '备注',
    create_by   VARCHAR(50)  COMMENT '创建人',
    create_time DATETIME     COMMENT '创建时间',
    update_by   VARCHAR(50)  COMMENT '更新人',
    update_time DATETIME     COMMENT '更新时间',
    del_flag    INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_price_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户价格表';

-- ============================================================
-- 3. 字典注册(若 dev DB 缺)
-- ============================================================
INSERT IGNORE INTO sys_dict (id, dict_code, dict_name, description, create_by, create_time, del_flag)
VALUES
  (REPLACE(UUID(),'-',''), 'mes_customer_grade', '客户等级', 'MES客户等级字典', 'admin', NOW(), 0),
  (REPLACE(UUID(),'-',''), 'mes_customer_industry', '行业', 'MES客户行业字典', 'admin', NOW(), 0),
  (REPLACE(UUID(),'-',''), 'mes_customer_region', '区域', 'MES客户区域字典', 'admin', NOW(), 0),
  (REPLACE(UUID(),'-',''), 'mes_customer_scale', '企业规模', 'MES客户企业规模字典', 'admin', NOW(), 0),
  (REPLACE(UUID(),'-',''), 'mes_customer_type', '客户类型', 'MES客户类型字典', 'admin', NOW(), 0),
  (REPLACE(UUID(),'-',''), 'invoice_type', '发票类型', '发票类型字典', 'admin', NOW(), 0),
  (REPLACE(UUID(),'-',''), 'address_type', '地址类型', '地址类型字典', 'admin', NOW(), 0),
  (REPLACE(UUID(),'-',''), 'follow_type', '跟进方式', '跟进方式字典', 'admin', NOW(), 0),
  (REPLACE(UUID(),'-',''), 'mes_supplier_type', '供应商类型', 'MES供应商类型字典', 'admin', NOW(), 0),
  (REPLACE(UUID(),'-',''), 'mes_supplier_status', '供应商状态', 'MES供应商状态字典', 'admin', NOW(), 0),
  (REPLACE(UUID(),'-',''), 'mes_supplier_grade', '供应商等级', 'MES供应商等级字典', 'admin', NOW(), 0);
