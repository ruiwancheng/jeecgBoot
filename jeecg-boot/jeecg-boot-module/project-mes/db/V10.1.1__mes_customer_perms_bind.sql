-- V10.1.1  把 4 个 customer 子表新权限码绑定到 admin / mes_admin 角色
-- 防止 controller 注解生效后 admin 仍被拦截(无权限码)

INSERT INTO sys_role_permission (id, role_id, permission_id, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), r.id, p.id, 'admin', NOW(), 'admin', NOW()
FROM sys_role r
CROSS JOIN sys_permission p
WHERE r.role_code IN ('admin', 'mes_admin')
  AND p.perms IN (
    'mes:customerAddress:list','mes:customerAddress:add','mes:customerAddress:edit',
    'mes:customerAddress:delete','mes:customerAddress:deleteBatch','mes:customerAddress:export','mes:customerAddress:import',
    'mes:customerContact:list','mes:customerContact:add','mes:customerContact:edit',
    'mes:customerContact:delete','mes:customerContact:deleteBatch','mes:customerContact:export','mes:customerContact:import',
    'mes:customerFollowUp:list','mes:customerFollowUp:add','mes:customerFollowUp:edit',
    'mes:customerFollowUp:delete','mes:customerFollowUp:deleteBatch','mes:customerFollowUp:export',
    'mes:customerPrice:list','mes:customerPrice:add','mes:customerPrice:edit',
    'mes:customerPrice:delete','mes:customerPrice:deleteBatch','mes:customerPrice:export'
  );
