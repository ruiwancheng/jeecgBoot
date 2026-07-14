-- MES 价格类型字典补录（V3.9.3_0）
-- 仅补字典项，避免重复执行冲突
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '价格类型', 'mes_price_type', 'MES价格类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

INSERT IGNORE INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time, del_flag)
SELECT REPLACE(UUID(),'-',''), d.id, '标准售价', '1', '无客户特殊政策的默认价格', 1, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_price_type'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, '客户协议价', '2', '特定客户专属协议价格', 2, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_price_type';
