-- MES 物料权限修复 V1.7.1
-- 根因：V1.7.0 SQL INSERT 未包含 perms 列，Shiro @RequiresPermissions 匹配的是 sys_permission.perms 不是 id
-- 修复1：UPDATE perms = id（补齐缺失的权限标识列）
-- 修复2：INSERT 角色绑定（确保角色能看到这些权限）

UPDATE sys_permission SET perms = 'mes_basic_material' WHERE id = 'mes_basic_material';

UPDATE sys_permission SET perms = 'mes:material:list' WHERE id = 'mes:material:list';
UPDATE sys_permission SET perms = 'mes:material:add' WHERE id = 'mes:material:add';
UPDATE sys_permission SET perms = 'mes:material:edit' WHERE id = 'mes:material:edit';
UPDATE sys_permission SET perms = 'mes:material:delete' WHERE id = 'mes:material:delete';
UPDATE sys_permission SET perms = 'mes:material:deleteBatch' WHERE id = 'mes:material:deleteBatch';
UPDATE sys_permission SET perms = 'mes:material:export' WHERE id = 'mes:material:export';
UPDATE sys_permission SET perms = 'mes:material:import' WHERE id = 'mes:material:import';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id = 'mes_basic_material' OR p.id LIKE 'mes:material:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_basic_material' OR p.id LIKE 'mes:material:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
