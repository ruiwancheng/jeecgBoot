-- V10.0.5 修复 c_mes_code_rule.rule_code 字段无默认值导致 INSERT 失败
-- 触发: harness/tests/modules/basic-extra.test.js §1.1 add
-- 错误: java.sql.SQLException: Field 'rule_code' doesn't have a default value
-- 根因: V1.8.0/V9.5.0 DDL 把 rule_code 设为 NOT NULL 但无 DEFAULT，新代码 INSERT 时若未传 rule_code 报错

-- MySQL 5.7 兼容：用 INFORMATION_SCHEMA 判断 + ALTER（幂等）
SET @dbname = DATABASE();
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE table_schema = @dbname AND table_name = 'c_mes_code_rule' AND column_name = 'rule_code');

-- 1) 修改 rule_code 列允许 NULL（保留 NOT NULL 但加 DEFAULT '' 兼容老 INSERT）
SET @sql = IF(@col_exists = 1,
    'ALTER TABLE c_mes_code_rule MODIFY COLUMN rule_code VARCHAR(50) NULL DEFAULT NULL COMMENT ''规则编码''',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2) 已存在但 DEFAULT 不为 NULL 的，改为 NULL 兼容
SET @sql = IF(@col_exists = 1,
    'ALTER TABLE c_mes_code_rule ALTER COLUMN rule_code SET DEFAULT NULL',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3) 验证：列定义已更新
SELECT column_name, is_nullable, column_default
FROM INFORMATION_SCHEMA.COLUMNS
WHERE table_schema = @dbname AND table_name = 'c_mes_code_rule' AND column_name = 'rule_code';
