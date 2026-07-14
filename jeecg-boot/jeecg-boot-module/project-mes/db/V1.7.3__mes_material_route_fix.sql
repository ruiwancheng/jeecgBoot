-- MES 物料路由修复 V1.7.3
-- V1.7.2 UPDATE 的 WHERE parent_id != 'mes_product' 条件太窄
UPDATE sys_permission SET is_route = 1 WHERE id = 'mes_basic_material' AND is_route = 0;
