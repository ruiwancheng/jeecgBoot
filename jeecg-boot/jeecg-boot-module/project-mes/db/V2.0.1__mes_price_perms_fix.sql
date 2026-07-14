-- MES 价格权限修复 V2.0.1
-- V2.0.0 SQL INSERT 未含 perms 列，Shiro 鉴权失败
UPDATE sys_permission SET perms = 'mes_sales_price' WHERE id = 'mes_sales_price' AND (perms IS NULL OR perms = '');
UPDATE sys_permission SET perms = 'mes:price:list' WHERE id = 'mes:price:list' AND (perms IS NULL OR perms = '');
UPDATE sys_permission SET perms = 'mes:price:add' WHERE id = 'mes:price:add' AND (perms IS NULL OR perms = '');
UPDATE sys_permission SET perms = 'mes:price:edit' WHERE id = 'mes:price:edit' AND (perms IS NULL OR perms = '');
UPDATE sys_permission SET perms = 'mes:price:delete' WHERE id = 'mes:price:delete' AND (perms IS NULL OR perms = '');
UPDATE sys_permission SET perms = 'mes:price:deleteBatch' WHERE id = 'mes:price:deleteBatch' AND (perms IS NULL OR perms = '');
UPDATE sys_permission SET perms = 'mes:price:export' WHERE id = 'mes:price:export' AND (perms IS NULL OR perms = '');
UPDATE sys_permission SET perms = 'mes:price:import' WHERE id = 'mes:price:import' AND (perms IS NULL OR perms = '');
