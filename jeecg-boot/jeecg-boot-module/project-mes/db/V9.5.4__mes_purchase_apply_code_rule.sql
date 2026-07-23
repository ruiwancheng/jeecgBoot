-- V9.5.4 — 采购申请编码规则 + 字典选项
-- 1) 补建 PA 编码规则（INSERT IGNORE 幂等）
-- 2) mes_code_biz_type 字典追加"采购申请"选项

-- 1) 编码规则：前缀 SQ + yyyyMMdd + 4位流水 + 每日重置
INSERT IGNORE INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, `current_date`, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES ('mes_code_rule_PA', 'PA', '采购申请编码', 'SQ', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'PA', 'admin', NOW(), 'admin', NOW(), 0);

-- 2) 字典项：仅当不存在时才插入
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(), '-', ''), d.id, '采购申请', 'PA', 'purchase/apply', 11, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict d
WHERE d.dict_code = 'mes_code_biz_type'
  AND NOT EXISTS (
    SELECT 1 FROM sys_dict_item di
    WHERE di.dict_id = d.id AND di.item_value = 'PA'
  );
