-- MES 价格菜单路由修复 V2.0.2
-- sys/permission/add API 忽略 isRoute，RUNNER 可能跳过了注册
UPDATE sys_permission SET is_route = 1 WHERE id = 'mes_sales_price' AND is_route = 0;
