-- V10.1.1  把 4 个 customer 子表新权限码绑定到 admin / mes_admin 角色
-- 防止 controller 注解生效后 admin 仍被拦截(无权限码)
--
-- sys_role_permission 列: role_id, permission_id, data_rule_ids, operate_date, operate_ip

-- 1. 客户地址 7 个权限码
INSERT IGNORE INTO sys_role_permission (role_id, permission_id) VALUES
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerAddress:list'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerAddress:add'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerAddress:edit'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerAddress:delete'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerAddress:deleteBatch'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerAddress:export'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerAddress:import');

-- 2. 客户联系人 7 个权限码
INSERT IGNORE INTO sys_role_permission (role_id, permission_id) VALUES
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerContact:list'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerContact:add'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerContact:edit'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerContact:delete'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerContact:deleteBatch'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerContact:export'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerContact:import');

-- 3. 客户跟进 6 个权限码
INSERT IGNORE INTO sys_role_permission (role_id, permission_id) VALUES
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerFollowUp:list'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerFollowUp:add'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerFollowUp:edit'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerFollowUp:delete'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerFollowUp:deleteBatch'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerFollowUp:export');

-- 4. 客户价格 6 个权限码
INSERT IGNORE INTO sys_role_permission (role_id, permission_id) VALUES
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerPrice:list'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerPrice:add'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerPrice:edit'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerPrice:delete'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerPrice:deleteBatch'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:customerPrice:export');

-- 5. MesCustomerController 写方法 (BONUS) 5 个权限码 + 1 个 list
-- perms 用 mes:basic:* (继承自原 MesCustomerController 类级注解)
INSERT IGNORE INTO sys_role_permission (role_id, permission_id) VALUES
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:basic:list'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:basic:add'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:basic:edit'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:basic:delete'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:basic:deleteBatch'),
  ('f6817f48af4fb3af11b9e8bf182f618b', 'mes:basic:import');
