-- MES 供应商模块 V1.4.0
-- CREATE TABLE: c_mes_supplier
-- 字典注册: mes_supplier_type / mes_supplier_status / mes_supplier_grade
-- 权限注册: 菜单 + 7 个权限码 + 角色绑定

-- ============================================================
-- 一、建表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_supplier (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    code            VARCHAR(50)  NOT NULL COMMENT '供应商编码',
    name            VARCHAR(100) NOT NULL COMMENT '供应商名称',
    type            VARCHAR(20)  COMMENT '供应商类型(dict:mes_supplier_type)',
    status          VARCHAR(20)  DEFAULT '潜在' COMMENT '供应商状态(dict:mes_supplier_status)',
    grade           VARCHAR(20)  COMMENT '供应商等级(dict:mes_supplier_grade)',
    blacklist_flag  TINYINT(1)   DEFAULT 0 COMMENT '黑名单标记 0否 1是',
    contact         VARCHAR(100) COMMENT '联系人',
    phone           VARCHAR(50)  COMMENT '联系电话',
    address         VARCHAR(255) COMMENT '地址',
    invoice_title   VARCHAR(200) COMMENT '发票抬头',
    tax_no          VARCHAR(50)  COMMENT '税号',
    bank_name       VARCHAR(100) COMMENT '开户银行',
    bank_account    VARCHAR(50)  COMMENT '银行账号',
    remark          VARCHAR(500) COMMENT '备注',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_supplier_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-供应商';

-- ============================================================
-- 二、字典注册
-- ============================================================
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '供应商类型', 'mes_supplier_type', 'MES供应商类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0),
(REPLACE(UUID(),'-',''), '供应商状态', 'mes_supplier_status', 'MES供应商生命周期状态', 0, 'admin', NOW(), 'admin', NOW(), 0),
(REPLACE(UUID(),'-',''), '供应商等级', 'mes_supplier_grade', 'MES供应商综合评级', 0, 'admin', NOW(), 'admin', NOW(), 0);

INSERT IGNORE INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time, del_flag)
SELECT REPLACE(UUID(),'-,''), d.id, '生产商', '1', '生产制造型企业', 1, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_type'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, '贸易商', '2', '贸易/代理商', 2, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_type'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, '服务商', '3', '物流/检测/外协等服务商', 3, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_type'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, '其他', '4', '其他类型供应商', 4, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_type';

INSERT IGNORE INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time, del_flag)
SELECT REPLACE(UUID(),'-',''), d.id, '潜在', '1', '初步收集信息，尚未提交审核', 1, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_status'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, '准入中', '2', '已提交资质，正在评审', 2, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_status'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, '合格', '3', '评审通过，可正式下单', 3, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_status'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, '合作中', '4', '已有采购往来，活跃供应商', 4, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_status'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, '暂停', '5', '重大质量问题或资质过期，暂停新订单', 5, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_status'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, '退出', '6', '长期不合作或终止，仅保留历史数据', 6, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_status';

INSERT IGNORE INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time, del_flag)
SELECT REPLACE(UUID(),'-',''), d.id, 'A级', 'A', '综合得分≥90分，优先推荐', 1, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_grade'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, 'B级', 'B', '综合得分80-89分', 2, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_grade'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, 'C级', 'C', '综合得分60-79分，需整改观察', 3, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_grade'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, 'D级', 'D', '综合得分<60分，暂停合作', 4, 1, 'admin', NOW(), 'admin', NOW(), 0
FROM sys_dict d WHERE d.dict_code = 'mes_supplier_grade';

-- ============================================================
-- 三、菜单注册
-- ============================================================
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES
('mes_basic_supplier', 'mes_basic', '供应商管理', '/project/mes/basic/supplier', 'project/mes/basic/supplier/index', 1, 'MesBasicSupplier', '', 1, '1', 4.00, 0, 'ant-design:shop-outlined', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0);

-- ============================================================
-- 四、权限码注册
-- ============================================================
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES
('mes:supplier:list',       'mes_basic_supplier', '供应商列表',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:supplier:add',        'mes_basic_supplier', '供应商新增',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:supplier:edit',       'mes_basic_supplier', '供应商编辑',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:supplier:delete',     'mes_basic_supplier', '供应商删除',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:supplier:deleteBatch','mes_basic_supplier', '供应商批量删除',   '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:supplier:export',     'mes_basic_supplier', '供应商导出',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0),
('mes:supplier:import',     'mes_basic_supplier', '供应商导入',       '', '', 0, '', '', 2, '1', 0, 0, '', 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, 0);

-- ============================================================
-- 五、角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id = 'mes_basic_supplier' OR p.id LIKE 'mes:supplier:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_basic_supplier' OR p.id LIKE 'mes:supplier:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
