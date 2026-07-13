-- ====================================================================
-- MES 基础设置模块初始化 SQL
-- 包含: DDL 建表、字典数据、菜单权限、角色授权
-- 可重复执行（全部使用 WHERE NOT EXISTS）
-- V1.2: 新增库区/货架表，仓库/库位表补充新字段，唯一索引含 del_flag
-- ====================================================================

-- 1. DDL: 仓库表
CREATE TABLE IF NOT EXISTS c_mes_warehouse (
    id varchar(36) NOT NULL COMMENT '主键',
    code varchar(50) NOT NULL COMMENT '仓库编码',
    name varchar(100) NOT NULL COMMENT '仓库名称',
    type varchar(50) DEFAULT NULL COMMENT '仓库类型',
    address varchar(300) DEFAULT NULL COMMENT '仓库地址',
    manager varchar(50) DEFAULT NULL COMMENT '负责人',
    phone varchar(20) DEFAULT NULL COMMENT '联系电话',
    factory varchar(100) DEFAULT NULL COMMENT '所属工厂',
    workshop varchar(100) DEFAULT NULL COMMENT '所属车间',
    status int DEFAULT 1 COMMENT '状态 1启用 0停用',
    remark varchar(500) DEFAULT NULL COMMENT '备注',
    create_by varchar(50) DEFAULT NULL,
    create_time datetime DEFAULT NULL,
    update_by varchar(50) DEFAULT NULL,
    update_time datetime DEFAULT NULL,
    del_flag int DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE KEY uk_mes_wh_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-仓库表';

-- 2. DDL: 库区表
CREATE TABLE IF NOT EXISTS c_mes_zone (
    id varchar(36) NOT NULL COMMENT '主键',
    warehouse_id varchar(36) NOT NULL COMMENT '所属仓库ID',
    code varchar(50) NOT NULL COMMENT '库区编码',
    name varchar(100) DEFAULT NULL COMMENT '库区名称',
    sort_no int DEFAULT 0 COMMENT '排序号',
    status int DEFAULT 1 COMMENT '状态 1启用 0停用',
    remark varchar(500) DEFAULT NULL COMMENT '备注',
    create_by varchar(50) DEFAULT NULL,
    create_time datetime DEFAULT NULL,
    update_by varchar(50) DEFAULT NULL,
    update_time datetime DEFAULT NULL,
    del_flag int DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE KEY uk_mes_zone_wh_code_del (warehouse_id, code, del_flag),
    KEY idx_mes_zone_wh (warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-库区表';

-- 3. DDL: 货架表
CREATE TABLE IF NOT EXISTS c_mes_shelf (
    id varchar(36) NOT NULL COMMENT '主键',
    zone_id varchar(36) NOT NULL COMMENT '所属库区ID',
    warehouse_id varchar(36) DEFAULT NULL COMMENT '所属仓库ID(冗余)',
    code varchar(50) NOT NULL COMMENT '货架编码',
    name varchar(100) DEFAULT NULL COMMENT '货架名称',
    sort_no int DEFAULT 0 COMMENT '排序号',
    status int DEFAULT 1 COMMENT '状态 1启用 0停用',
    remark varchar(500) DEFAULT NULL COMMENT '备注',
    create_by varchar(50) DEFAULT NULL,
    create_time datetime DEFAULT NULL,
    update_by varchar(50) DEFAULT NULL,
    update_time datetime DEFAULT NULL,
    del_flag int DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE KEY uk_mes_shelf_zone_code_del (zone_id, code, del_flag),
    KEY idx_mes_shelf_zone (zone_id),
    KEY idx_mes_shelf_wh (warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-货架表';

-- 4. DDL: 库位表
CREATE TABLE IF NOT EXISTS c_mes_location (
    id varchar(36) NOT NULL COMMENT '主键',
    warehouse_id varchar(36) DEFAULT NULL COMMENT '所属仓库ID',
    zone_id varchar(36) DEFAULT NULL COMMENT '所属库区ID',
    shelf_id varchar(36) DEFAULT NULL COMMENT '所属货架ID',
    code varchar(100) NOT NULL COMMENT '库位编码',
    name varchar(100) DEFAULT NULL COMMENT '库位名称',
    type varchar(50) DEFAULT NULL COMMENT '库位类型',
    area varchar(50) DEFAULT NULL COMMENT '区域',
    passage_row int DEFAULT NULL COMMENT '通道行数',
    passage_col int DEFAULT NULL COMMENT '通道列数',
    shelf_row int DEFAULT NULL COMMENT '货架行数',
    shelf_col int DEFAULT NULL COMMENT '货架列数',
    max_capacity decimal(10,2) DEFAULT NULL COMMENT '最大容量',
    load_capacity decimal(10,2) DEFAULT NULL COMMENT '承重(kg)',
    storage_limit varchar(255) DEFAULT NULL COMMENT '存放物料限制',
    length decimal(10,2) DEFAULT NULL COMMENT '长(cm)',
    width decimal(10,2) DEFAULT NULL COMMENT '宽(cm)',
    height decimal(10,2) DEFAULT NULL COMMENT '高(cm)',
    factory varchar(100) DEFAULT NULL COMMENT '所属工厂',
    workshop varchar(100) DEFAULT NULL COMMENT '所属车间',
    status int DEFAULT 1 COMMENT '状态 1启用 0停用',
    remark varchar(500) DEFAULT NULL COMMENT '备注',
    create_by varchar(50) DEFAULT NULL,
    create_time datetime DEFAULT NULL,
    update_by varchar(50) DEFAULT NULL,
    update_time datetime DEFAULT NULL,
    del_flag int DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE KEY uk_mes_loc_shelf_code_del (shelf_id, code, del_flag),
    KEY idx_mes_loc_zone (zone_id),
    KEY idx_mes_loc_shelf (shelf_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-库位表';

-- 5. 字典: MES仓库类型
INSERT INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
SELECT REPLACE(UUID(),'-',''), 'MES仓库类型', 'mes_warehouse_type', 'MES仓库类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0
WHERE NOT EXISTS (SELECT 1 FROM sys_dict WHERE dict_code='mes_warehouse_type');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type'), '原料仓', '1', '原料仓库', 1, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type') AND item_value='1');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type'), '成品仓', '2', '成品仓库', 2, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type') AND item_value='2');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type'), '半成品仓', '3', '半成品仓库', 3, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type') AND item_value='3');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type'), '线边仓', '4', '线边仓库', 4, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type') AND item_value='4');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type'), '不良品仓', '5', '不良品存放仓库', 5, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type') AND item_value='5');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type'), '退货仓', '6', '退货存放仓库', 6, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_warehouse_type') AND item_value='6');

-- 6. 字典: MES库位类型
INSERT INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
SELECT REPLACE(UUID(),'-',''), 'MES库位类型', 'mes_location_type', 'MES库位类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0
WHERE NOT EXISTS (SELECT 1 FROM sys_dict WHERE dict_code='mes_location_type');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_location_type'), '货架', '1', '货架库位', 1, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_location_type') AND item_value='1');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_location_type'), '地面', '2', '地面库位', 2, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_location_type') AND item_value='2');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_location_type'), '暂存区', '3', '暂存区域', 3, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_location_type') AND item_value='3');

-- 7. 菜单: MES 一级菜单
INSERT INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
SELECT 'mes_menu_001', '', 'MES系统', '/project/mes', 'layouts/default/index', 1, '', '/project/mes/basic', 0, '1', 90.00, 0, 'ant-design:appstore-outlined', 0, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM sys_permission WHERE id='mes_menu_001');

-- 8. 菜单: 基础设置
INSERT INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
SELECT 'mes_basic', 'mes_menu_001', '基础设置', '/project/mes/basic', 'layouts/default/index', 1, '', '/project/mes/basic/warehouse', 1, '1', 10.00, 0, 'ant-design:setting-outlined', 0, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM sys_permission WHERE id='mes_basic');

-- 9. 菜单: 仓库管理
INSERT INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
SELECT 'mes_basic_wh', 'mes_basic', '仓库管理', '/project/mes/basic/warehouse', 'project/mes/basic/warehouse/index', 1, 'MesBasicWarehouse', NULL, 1, '1', 1.00, 0, 'ant-design:database-filled', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM sys_permission WHERE id='mes_basic_wh');

-- 10. 菜单: 库位管理
INSERT INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
SELECT 'mes_basic_loc', 'mes_basic', '库位管理', '/project/mes/basic/location', 'project/mes/basic/location/index', 1, 'MesBasicLocation', NULL, 1, '1', 2.00, 0, 'ant-design:environment-filled', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0
WHERE NOT EXISTS (SELECT 1 FROM sys_permission WHERE id='mes_basic_loc');

-- 11. 角色授权: MES管理员
INSERT INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', 'mes_menu_001', NOW(), '127.0.0.1'
WHERE NOT EXISTS (SELECT 1 FROM sys_role_permission WHERE role_id='mes_role_001' AND permission_id='mes_menu_001');

INSERT INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', 'mes_basic', NOW(), '127.0.0.1'
WHERE NOT EXISTS (SELECT 1 FROM sys_role_permission WHERE role_id='mes_role_001' AND permission_id='mes_basic');

INSERT INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', 'mes_basic_wh', NOW(), '127.0.0.1'
WHERE NOT EXISTS (SELECT 1 FROM sys_role_permission WHERE role_id='mes_role_001' AND permission_id='mes_basic_wh');

INSERT INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', 'mes_basic_loc', NOW(), '127.0.0.1'
WHERE NOT EXISTS (SELECT 1 FROM sys_role_permission WHERE role_id='mes_role_001' AND permission_id='mes_basic_loc');
