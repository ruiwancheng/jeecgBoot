-- MES 物料模块 V1.7.0
-- CREATE TABLE: c_mes_material
-- 字典注册: mes_material_type / mes_material_unit
-- 权限注册: 菜单 + 7 个权限码 + 角色绑定

-- ============================================================
-- 一、建表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_material (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    code            VARCHAR(50)  NOT NULL COMMENT '物料编码',
    name            VARCHAR(100) NOT NULL COMMENT '物料名称',
    type            VARCHAR(20)  COMMENT '物料类型(dict:mes_material_type)',
    spec            VARCHAR(100) COMMENT '规格型号',
    unit            VARCHAR(20)  COMMENT '单位(dict:mes_material_unit)',
    status          VARCHAR(20)  DEFAULT '1' COMMENT '状态 1启用 0停用',
    remark          VARCHAR(500) COMMENT '备注',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_material_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-物料';

-- ============================================================
-- 二、字典注册
-- ============================================================
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '物料类型', 'mes_material_type', 'MES物料类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0),
(REPLACE(UUID(),'-',''), '物料单位', 'mes_material_unit', 'MES物料单位字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_type');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_type'), '原材料', '1', '生产所需的原始物料', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_type'), '半成品', '2', '中间加工状态的物料', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_type'), '成品', '3', '最终可销售的产品', 3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_type'), '辅料', '4', '辅助性物料', 4, 1, 'admin', NOW(), 'admin', NOW());

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_unit');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_unit'), '个', '1', '个/件/只', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_unit'), '箱', '2', '箱/盒', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_unit'), '千克', '3', '千克', 3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_unit'), '米', '4', '米', 4, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_unit'), '升', '5', '升', 5, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_unit'), '卷', '6', '卷/捆', 6, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_unit'), '套', '7', '套/组', 7, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_material_unit'), '台', '8', '台', 8, 1, 'admin', NOW(), 'admin', NOW());

-- ============================================================
-- 三、菜单注册
-- ============================================================
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES
('mes_basic_material', 'mes_basic', '物料管理', '/project/mes/basic/material', 'project/mes/basic/material/index', 1, 'MesBasicMaterial', '', 1, '1', 5.00, 0, 'ant-design:gold-outlined', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0);

-- ============================================================
-- 四、权限码注册
-- ============================================================
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES
('mes:material:list',       'mes_basic_material', '物料列表',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:material:add',        'mes_basic_material', '物料新增',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:material:edit',       'mes_basic_material', '物料编辑',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:material:delete',     'mes_basic_material', '物料删除',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:material:deleteBatch','mes_basic_material', '物料批量删除',   '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:material:export',     'mes_basic_material', '物料导出',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:material:import',     'mes_basic_material', '物料导入',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0);

-- ============================================================
-- 五、角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id = 'mes_basic_material' OR p.id LIKE 'mes:material:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_basic_material' OR p.id LIKE 'mes:material:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
