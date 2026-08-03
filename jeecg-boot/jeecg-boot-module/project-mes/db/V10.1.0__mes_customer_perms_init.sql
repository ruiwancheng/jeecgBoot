-- V10.1.0  修复 4 个 customer 子表 controller 缺权限码
-- 2026-08-03 渗透测试 H-1~H-4 修复 + BONUS MesCustomerController 缺权限码
-- 防御 CWE-862 Missing Authorization
--
-- sys_permission.id 直接用 perms 字符串作为主键(参考 mes:material:list)
-- sys_role_permission 列: role_id, permission_id, data_rule_ids, operate_date, operate_ip
--   (无 create_by, create_time)

-- 1. 客户地址 7 个权限码
INSERT IGNORE INTO sys_permission (id, parent_id, name, perms, perms_type, menu_type, is_leaf, is_route, hidden, sort_no) VALUES
  ('mes:customerAddress:list',     'mes_basic_customer', 'list',       'mes:customerAddress:list',     '1', 2, 1, 0, 0, 0),
  ('mes:customerAddress:add',      'mes_basic_customer', 'add',        'mes:customerAddress:add',      '1', 2, 1, 0, 0, 0),
  ('mes:customerAddress:edit',     'mes_basic_customer', 'edit',       'mes:customerAddress:edit',     '1', 2, 1, 0, 0, 0),
  ('mes:customerAddress:delete',   'mes_basic_customer', 'delete',     'mes:customerAddress:delete',   '1', 2, 1, 0, 0, 0),
  ('mes:customerAddress:deleteBatch','mes_basic_customer','deleteBatch','mes:customerAddress:deleteBatch','1', 2, 1, 0, 0, 0),
  ('mes:customerAddress:export',   'mes_basic_customer', 'export',     'mes:customerAddress:export',   '1', 2, 1, 0, 0, 0),
  ('mes:customerAddress:import',   'mes_basic_customer', 'import',     'mes:customerAddress:import',   '1', 2, 1, 0, 0, 0);

-- 2. 客户联系人 7 个权限码
INSERT IGNORE INTO sys_permission (id, parent_id, name, perms, perms_type, menu_type, is_leaf, is_route, hidden, sort_no) VALUES
  ('mes:customerContact:list',     'mes_basic_customer', 'list',       'mes:customerContact:list',     '1', 2, 1, 0, 0, 0),
  ('mes:customerContact:add',      'mes_basic_customer', 'add',        'mes:customerContact:add',      '1', 2, 1, 0, 0, 0),
  ('mes:customerContact:edit',     'mes_basic_customer', 'edit',       'mes:customerContact:edit',     '1', 2, 1, 0, 0, 0),
  ('mes:customerContact:delete',   'mes_basic_customer', 'delete',     'mes:customerContact:delete',   '1', 2, 1, 0, 0, 0),
  ('mes:customerContact:deleteBatch','mes_basic_customer','deleteBatch','mes:customerContact:deleteBatch','1', 2, 1, 0, 0, 0),
  ('mes:customerContact:export',   'mes_basic_customer', 'export',     'mes:customerContact:export',   '1', 2, 1, 0, 0, 0),
  ('mes:customerContact:import',   'mes_basic_customer', 'import',     'mes:customerContact:import',   '1', 2, 1, 0, 0, 0);

-- 3. 客户跟进 6 个权限码
INSERT IGNORE INTO sys_permission (id, parent_id, name, perms, perms_type, menu_type, is_leaf, is_route, hidden, sort_no) VALUES
  ('mes:customerFollowUp:list',     'mes_basic_customer', 'list',       'mes:customerFollowUp:list',     '1', 2, 1, 0, 0, 0),
  ('mes:customerFollowUp:add',      'mes_basic_customer', 'add',        'mes:customerFollowUp:add',      '1', 2, 1, 0, 0, 0),
  ('mes:customerFollowUp:edit',     'mes_basic_customer', 'edit',       'mes:customerFollowUp:edit',     '1', 2, 1, 0, 0, 0),
  ('mes:customerFollowUp:delete',   'mes_basic_customer', 'delete',     'mes:customerFollowUp:delete',   '1', 2, 1, 0, 0, 0),
  ('mes:customerFollowUp:deleteBatch','mes_basic_customer','deleteBatch','mes:customerFollowUp:deleteBatch','1', 2, 1, 0, 0, 0),
  ('mes:customerFollowUp:export',   'mes_basic_customer', 'export',     'mes:customerFollowUp:export',   '1', 2, 1, 0, 0, 0);

-- 4. 客户价格 6 个权限码
INSERT IGNORE INTO sys_permission (id, parent_id, name, perms, perms_type, menu_type, is_leaf, is_route, hidden, sort_no) VALUES
  ('mes:customerPrice:list',     'mes_basic_customer', 'list',       'mes:customerPrice:list',     '1', 2, 1, 0, 0, 0),
  ('mes:customerPrice:add',      'mes_basic_customer', 'add',        'mes:customerPrice:add',      '1', 2, 1, 0, 0, 0),
  ('mes:customerPrice:edit',     'mes_basic_customer', 'edit',       'mes:customerPrice:edit',     '1', 2, 1, 0, 0, 0),
  ('mes:customerPrice:delete',   'mes_basic_customer', 'delete',     'mes:customerPrice:delete',   '1', 2, 1, 0, 0, 0),
  ('mes:customerPrice:deleteBatch','mes_basic_customer','deleteBatch','mes:customerPrice:deleteBatch','1', 2, 1, 0, 0, 0),
  ('mes:customerPrice:export',   'mes_basic_customer', 'export',     'mes:customerPrice:export',   '1', 2, 1, 0, 0, 0);

-- 5. 清理 M-1: 重复的 mes:productionPicking:* / mes:completionReceipt:* 行
-- 保留 id 最小的一行,删除其他
DELETE p1 FROM sys_permission p1
INNER JOIN sys_permission p2
ON p1.perms = p2.perms
  AND p1.id > p2.id
WHERE p1.perms IN (
  'mes:productionPicking:list','mes:productionPicking:add','mes:productionPicking:edit',
  'mes:productionPicking:delete','mes:productionPicking:deleteBatch','mes:productionPicking:export',
  'mes:completionReceipt:list','mes:completionReceipt:add','mes:completionReceipt:edit',
  'mes:completionReceipt:delete','mes:completionReceipt:deleteBatch','mes:completionReceipt:export'
);
