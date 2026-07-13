-- MES 角色权限绑定 V1.3.1
-- V1.3.0 权限码已入库，但角色绑定未执行，此处兜底
-- 所有操作使用 INSERT IGNORE，可重复执行

-- 绑定到 MES 项目管理员角色
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', id, NOW(), '127.0.0.1'
FROM sys_permission
WHERE id IN (
    'mes:warehouse:list','mes:warehouse:add','mes:warehouse:edit','mes:warehouse:delete','mes:warehouse:deleteBatch','mes:warehouse:export','mes:warehouse:import',
    'mes:zone:list','mes:zone:add','mes:zone:edit','mes:zone:delete','mes:zone:deleteBatch','mes:zone:export','mes:zone:import',
    'mes:shelf:list','mes:shelf:add','mes:shelf:edit','mes:shelf:delete','mes:shelf:deleteBatch','mes:shelf:export','mes:shelf:import',
    'mes:location:list','mes:location:add','mes:location:edit','mes:location:delete','mes:location:deleteBatch','mes:location:export','mes:location:import'
);

-- 绑定到 admin 角色
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), r.id, p.id, NOW(), '127.0.0.1'
FROM sys_permission p, sys_role r
WHERE r.role_code = 'admin'
  AND p.id IN (
    'mes:warehouse:list','mes:warehouse:add','mes:warehouse:edit','mes:warehouse:delete','mes:warehouse:deleteBatch','mes:warehouse:export','mes:warehouse:import',
    'mes:zone:list','mes:zone:add','mes:zone:edit','mes:zone:delete','mes:zone:deleteBatch','mes:zone:export','mes:zone:import',
    'mes:shelf:list','mes:shelf:add','mes:shelf:edit','mes:shelf:delete','mes:shelf:deleteBatch','mes:shelf:export','mes:shelf:import',
    'mes:location:list','mes:location:add','mes:location:edit','mes:location:delete','mes:location:deleteBatch','mes:location:export','mes:location:import'
);
