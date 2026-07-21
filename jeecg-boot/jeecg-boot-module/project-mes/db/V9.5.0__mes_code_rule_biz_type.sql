-- MES V9.5.0 — 编码规则与单据页面绑定
-- 1) c_mes_code_rule 增加 biz_type(适用单据) 列
-- 2) 新建字典 mes_code_biz_type（适用单据）
-- 3) 回填已有规则 SO/PO/MO 的 biz_type
-- 4) 补建 DN/OB/PR/PP/MC/SI/PI 七条编码规则（幂等）

-- 1) 加列（MySQL 5.7 不支持 ADD COLUMN IF NOT EXISTS，用 INFORMATION_SCHEMA 守卫）
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema = DATABASE() AND table_name = 'c_mes_code_rule' AND column_name = 'biz_type');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_code_rule ADD COLUMN biz_type VARCHAR(30) DEFAULT NULL COMMENT ''适用单据(字典 mes_code_biz_type)''', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) 适用单据字典
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), 'MES适用单据', 'mes_code_biz_type', 'MES编码规则-适用单据字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

-- sys_dict_item 无 del_flag 列，用 DELETE+INSERT 保证幂等
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_code_biz_type');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '销售订单', 'SO', 'sales/order', 1, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '采购订单', 'PO', 'purchase/order', 2, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '生产订单', 'MO', 'manufacturing/order', 3, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '发货单', 'DN', 'sales/delivery', 4, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '销售出库单', 'OB', 'sales/outbound', 5, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '采购收货单', 'PR', 'purchase/receipt', 6, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '生产领料单', 'PP', 'manufacturing/picking', 7, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '完工入库单', 'MC', 'manufacturing/completion', 8, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '销售发票', 'SI', 'finance/invoice', 9, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '采购发票', 'PI', 'finance/purchaseInvoice', 10, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), id, '其他', 'OTHER', '未绑定具体单据的通用规则', 99, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict WHERE dict_code = 'mes_code_biz_type';

-- 3) 回填已有规则的适用单据
UPDATE c_mes_code_rule SET biz_type = rule_code WHERE rule_code IN ('SO', 'PO', 'MO') AND (biz_type IS NULL OR biz_type = '');

-- 4) 补建缺失规则（DELETE+INSERT 幂等，参数与 SO 一致：yyyyMMdd + 4位流水 + 每日重置）
DELETE FROM c_mes_code_rule WHERE rule_code = 'DN';
INSERT INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, current_date, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES (REPLACE(UUID(),'-',''), 'DN', '发货单编码', 'DN', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'DN', 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM c_mes_code_rule WHERE rule_code = 'OB';
INSERT INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, current_date, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES (REPLACE(UUID(),'-',''), 'OB', '销售出库单编码', 'OB', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'OB', 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM c_mes_code_rule WHERE rule_code = 'PR';
INSERT INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, current_date, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES (REPLACE(UUID(),'-',''), 'PR', '采购收货单编码', 'PR', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'PR', 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM c_mes_code_rule WHERE rule_code = 'PP';
INSERT INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, current_date, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES (REPLACE(UUID(),'-',''), 'PP', '生产领料单编码', 'PP', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'PP', 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM c_mes_code_rule WHERE rule_code = 'MC';
INSERT INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, current_date, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES (REPLACE(UUID(),'-',''), 'MC', '完工入库单编码', 'MC', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'MC', 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM c_mes_code_rule WHERE rule_code = 'SI';
INSERT INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, current_date, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES (REPLACE(UUID(),'-',''), 'SI', '销售发票单号', 'SI', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'SI', 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM c_mes_code_rule WHERE rule_code = 'PI';
INSERT INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, current_date, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES (REPLACE(UUID(),'-',''), 'PI', '采购发票单号', 'PI', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'PI', 'admin', NOW(), 'admin', NOW(), 0);
