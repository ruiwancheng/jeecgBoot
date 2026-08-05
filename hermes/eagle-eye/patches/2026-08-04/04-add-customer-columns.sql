-- MES 全量回归测试修复 patch 4/4
-- 文件: db/V10.x__mes_customer_add_columns.sql
-- 关联: hermes/eagle-eye/reports/2026-08-04/mes-business-flow-test-report.md
-- 问题: MesCustomer 实体有 6 字段，c_mes_customer 表缺失（schema vs 实体不同步）
-- 优先级: P1（影响所有客户列表/分页查询）
--
-- 应用: 在 MySQL 5.7+ / 8.x 中执行本脚本
--   mysql -uroot -proot --host=127.0.0.1 --protocol=TCP jeecg-boot < V10.x__mes_customer_add_columns.sql
--
-- 幂等性: 每次跑都生效（IF NOT EXISTS 检查列是否存在）

-- 客户等级（字典：mes_customer_grade）
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'grade');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_customer ADD COLUMN grade VARCHAR(50) COMMENT ''客户等级'' AFTER `type`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 信用额度
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'credit_limit');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_customer ADD COLUMN credit_limit DECIMAL(18,4) DEFAULT 0 COMMENT ''信用额度'' AFTER `grade`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 销售员 ID（关联 sys_user）
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'salesman_id');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_customer ADD COLUMN salesman_id VARCHAR(32) COMMENT ''销售员ID'' AFTER `credit_limit`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 行业
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'industry');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_customer ADD COLUMN industry VARCHAR(50) COMMENT ''行业'' AFTER `salesman_id`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 地区
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'region');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_customer ADD COLUMN region VARCHAR(50) COMMENT ''地区'' AFTER `industry`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 规模
SET @col_exists = (SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_customer' AND COLUMN_NAME = 'scale');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_customer ADD COLUMN scale VARCHAR(50) COMMENT ''规模'' AFTER `region`',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 验证
SELECT COLUMN_NAME, COLUMN_TYPE, COLUMN_COMMENT
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'c_mes_customer'
ORDER BY ORDINAL_POSITION;