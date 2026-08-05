-- V10.1.0  修复 4 个 customer 子表 controller 缺权限码
-- 2026-08-03 渗透测试 H-1~H-4 修复 + BONUS MesCustomerController 缺权限码
-- 防御 CWE-862 Missing Authorization

-- 1. 客户地址 7 个权限码
INSERT INTO sys_permission (id, parent_id, name, perms, menu_type, status, create_by, create_time, update_by, update_time, del_flag)
SELECT REPLACE(UUID(),'-',''), parent_id, 'list',     'mes:customerAddress:list',     2, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'add',          'mes:customerAddress:add',      2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'edit',         'mes:customerAddress:edit',     2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'delete',       'mes:customerAddress:delete',   2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'deleteBatch',  'mes:customerAddress:deleteBatch', 2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'export',       'mes:customerAddress:export',   2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'import',       'mes:customerAddress:import',   2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1;

-- 2. 客户联系人 7 个权限码
INSERT INTO sys_permission (id, parent_id, name, perms, menu_type, status, create_by, create_time, update_by, update_time, del_flag)
SELECT REPLACE(UUID(),'-',''), parent_id, 'list',     'mes:customerContact:list',     2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'add',          'mes:customerContact:add',      2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'edit',         'mes:customerContact:edit',     2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'delete',       'mes:customerContact:delete',   2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'deleteBatch',  'mes:customerContact:deleteBatch', 2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'export',       'mes:customerContact:export',   2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'import',       'mes:customerContact:import',   2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1;

-- 3. 客户跟进 6 个权限码
INSERT INTO sys_permission (id, parent_id, name, perms, menu_type, status, create_by, create_time, update_by, update_time, del_flag)
SELECT REPLACE(UUID(),'-',''), parent_id, 'list',     'mes:customerFollowUp:list',     2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'add',          'mes:customerFollowUp:add',      2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'edit',         'mes:customerFollowUp:edit',     2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'delete',       'mes:customerFollowUp:delete',   2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'deleteBatch',  'mes:customerFollowUp:deleteBatch', 2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'export',       'mes:customerFollowUp:export',   2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1;

-- 4. 客户价格 6 个权限码
INSERT INTO sys_permission (id, parent_id, name, perms, menu_type, status, create_by, create_time, update_by, update_time, del_flag)
SELECT REPLACE(UUID(),'-',''), parent_id, 'list',     'mes:customerPrice:list',     2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'add',          'mes:customerPrice:add',      2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'edit',         'mes:customerPrice:edit',     2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'delete',       'mes:customerPrice:delete',   2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'deleteBatch',  'mes:customerPrice:deleteBatch', 2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1
UNION ALL SELECT REPLACE(UUID(),'-',''), parent_id, 'export',       'mes:customerPrice:export',   2, 1, 'admin', NOW(), 'admin', NOW(), 0 FROM sys_permission WHERE perms = 'mes_basic_customer' LIMIT 1;

-- 5. 清理 M-1: 重复的 mes:productionPicking:* / mes:completionReceipt:* 行
-- 仅删除 perms 列 + name 列 + parent_id 都重复的 (保留 id 最小的一行)
DELETE p1 FROM sys_permission p1
INNER JOIN sys_permission p2
ON p1.perms = p2.perms
  AND p1.parent_id = p2.parent_id
  AND p1.name = p2.name
  AND p1.id > p2.id
WHERE p1.perms IN (
  'mes:productionPicking:list','mes:productionPicking:add','mes:productionPicking:edit',
  'mes:productionPicking:delete','mes:productionPicking:deleteBatch','mes:productionPicking:export',
  'mes:completionReceipt:list','mes:completionReceipt:add','mes:completionReceipt:edit',
  'mes:completionReceipt:delete','mes:completionReceipt:deleteBatch','mes:completionReceipt:export'
);
