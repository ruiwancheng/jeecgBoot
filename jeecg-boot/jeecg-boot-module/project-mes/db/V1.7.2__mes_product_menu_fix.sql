-- MES 商品菜单修复 V1.7.2
-- 问题：sys/permission/add API 忽略 parentId/route 字段，菜单不显示
-- 修复：直接 UPDATE 数据库补全缺失字段

-- 1. 确保 mes_product 存在（如被误删则重建）
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, component_name, redirect, menu_type, perms_type, sort_no, icon, is_route, is_leaf, keep_alive, status, create_by, create_time, update_by, update_time, del_flag, rule_flag, internal_or_external)
VALUES ('mes_product', 'mes_menu_001', '商品', '/project/mes/product', 'layouts/default/index', '', '/project/mes/product/material', 0, '1', 20.00, 'ant-design:shopping-outlined', 1, 0, 1, '1', 'admin', NOW(), 'admin', NOW(), 0, 0, 0);

-- 2. 修复 mes_product 的 parentId 和 route
UPDATE sys_permission SET parent_id = 'mes_menu_001', is_route = 1, is_leaf = 0 WHERE id = 'mes_product' AND (parent_id IS NULL OR parent_id = '');

-- 3. 确保 mes_basic_material 存在且字段正确
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, component_name, menu_type, perms, perms_type, sort_no, icon, is_route, is_leaf, status, create_by, create_time, update_by, update_time, del_flag, rule_flag, internal_or_external)
VALUES ('mes_basic_material', 'mes_product', '物料管理', '/project/mes/basic/material', 'project/mes/basic/material/index', 'MesBasicMaterial', 1, 'mes_basic_material', '1', 1.00, 'ant-design:gold-outlined', 1, 1, '1', 'admin', NOW(), 'admin', NOW(), 0, 0, 0);

-- 4. 修复 mes_basic_material 的 parentId 和其他字段
UPDATE sys_permission SET parent_id = 'mes_product', is_route = 1, is_leaf = 1 WHERE id = 'mes_basic_material' AND parent_id != 'mes_product';
