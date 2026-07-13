-- MES 权限码注册 V1.3.0
-- 背景：@RequiresPermissions 需要 sys_permission 中存在对应权限码
-- MesMenuAutoRegisterRunner 首次运行可能被跳过，改用 SQL 兜底注册
-- 全部使用 INSERT IGNORE，可重复执行

-- 仓库权限（父级：mes_basic_wh）
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES
('mes:warehouse:list', 'mes_basic_wh', '仓库列表', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:warehouse:add', 'mes_basic_wh', '仓库新增', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:warehouse:edit', 'mes_basic_wh', '仓库编辑', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:warehouse:delete', 'mes_basic_wh', '仓库删除', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:warehouse:deleteBatch', 'mes_basic_wh', '仓库批量删除', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:warehouse:export', 'mes_basic_wh', '仓库导出', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:warehouse:import', 'mes_basic_wh', '仓库导入', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0);

-- 库区权限（父级：mes_basic_loc）
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES
('mes:zone:list', 'mes_basic_loc', '库区列表', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:zone:add', 'mes_basic_loc', '库区新增', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:zone:edit', 'mes_basic_loc', '库区编辑', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:zone:delete', 'mes_basic_loc', '库区删除', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:zone:deleteBatch', 'mes_basic_loc', '库区批量删除', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:zone:export', 'mes_basic_loc', '库区导出', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:zone:import', 'mes_basic_loc', '库区导入', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0);

-- 货架权限（父级：mes_basic_loc）
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES
('mes:shelf:list', 'mes_basic_loc', '货架列表', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:shelf:add', 'mes_basic_loc', '货架新增', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:shelf:edit', 'mes_basic_loc', '货架编辑', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:shelf:delete', 'mes_basic_loc', '货架删除', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:shelf:deleteBatch', 'mes_basic_loc', '货架批量删除', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:shelf:export', 'mes_basic_loc', '货架导出', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:shelf:import', 'mes_basic_loc', '货架导入', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0);

-- 库位权限（父级：mes_basic_loc）
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES
('mes:location:list', 'mes_basic_loc', '库位列表', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:location:add', 'mes_basic_loc', '库位新增', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:location:edit', 'mes_basic_loc', '库位编辑', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:location:delete', 'mes_basic_loc', '库位删除', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:location:deleteBatch', 'mes_basic_loc', '库位批量删除', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:location:export', 'mes_basic_loc', '库位导出', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:location:import', 'mes_basic_loc', '库位导入', '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0);

-- 授权：绑定到 MES 管理员角色
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id LIKE 'mes:warehouse:%' OR p.id LIKE 'mes:zone:%' OR p.id LIKE 'mes:shelf:%' OR p.id LIKE 'mes:location:%';

-- 授权：绑定到 admin 角色
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id LIKE 'mes:warehouse:%' OR p.id LIKE 'mes:zone:%' OR p.id LIKE 'mes:shelf:%' OR p.id LIKE 'mes:location:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
