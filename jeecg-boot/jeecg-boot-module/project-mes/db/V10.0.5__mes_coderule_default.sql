-- V10.0.5 修复 c_mes_code_rule.rule_code / rule_name 字段无默认值导致 INSERT 失败
-- 触发: harness/tests/modules/basic-extra.test.js §1.1 add
-- 错误: java.sql.SQLException: Field 'rule_code' / 'rule_name' doesn't have a default value
-- 根因: V1.8.0/V9.5.0 DDL 把 rule_code/rule_name 设为 NOT NULL 但无 DEFAULT，新代码 INSERT 时若未传对应字段报错
-- 修复: 允许 NULL + DEFAULT NULL（兼容老 INSERT 缺失字段）
--
-- v2 (2026-08-07, Slice J):
--   - 同步修复 rule_name（与 rule_code 同问题）
--   - 同时更新两个字段以保持一致

-- MySQL 5.7 兼容：用 INFORMATION_SCHEMA 判断 + ALTER（幂等）
SET @dbname = DATABASE();

-- 1) 修改 rule_code 列允许 NULL + DEFAULT NULL
SET @col_exists_code = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = @dbname AND table_name = 'c_mes_code_rule' AND column_name = 'rule_code');
SET @sql = IF(@col_exists_code = 1,
    'ALTER TABLE c_mes_code_rule MODIFY COLUMN rule_code VARCHAR(50) NULL DEFAULT NULL COMMENT ''规则编码''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) 修改 rule_name 列允许 NULL + DEFAULT NULL（与 rule_code 同步）
SET @col_exists_name = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = @dbname AND table_name = 'c_mes_code_rule' AND column_name = 'rule_name');
SET @sql = IF(@col_exists_name = 1,
    'ALTER TABLE c_mes_code_rule MODIFY COLUMN rule_name VARCHAR(100) NULL DEFAULT NULL COMMENT ''规则名称''',
    'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3) 验证：列定义已更新
SELECT column_name, is_nullable, column_default
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = @dbname AND table_name = 'c_mes_code_rule' AND column_name IN ('rule_code', 'rule_name');
