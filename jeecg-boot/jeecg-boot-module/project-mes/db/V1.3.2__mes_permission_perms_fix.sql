-- MES 权限 perms 字段修复 V1.3.2
-- Shiro 鉴权读取 sys_permission.perms 列，不是 id 列
-- V1.3.0 只设了 id 没设 perms，导致 @RequiresPermissions 永远不匹配
-- 将 perms 更新为与 id 一致的值
-- 可重复执行

UPDATE sys_permission SET perms = id WHERE id LIKE 'mes:warehouse:%' AND (perms IS NULL OR perms = '');
UPDATE sys_permission SET perms = id WHERE id LIKE 'mes:zone:%' AND (perms IS NULL OR perms = '');
UPDATE sys_permission SET perms = id WHERE id LIKE 'mes:shelf:%' AND (perms IS NULL OR perms = '');
UPDATE sys_permission SET perms = id WHERE id LIKE 'mes:location:%' AND (perms IS NULL OR perms = '');
