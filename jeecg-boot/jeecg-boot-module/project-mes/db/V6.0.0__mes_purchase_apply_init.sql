-- MES 采购申请模块 V6.0.0
-- CREATE TABLE: c_mes_purchase_apply + c_mes_purchase_apply_item
-- 字典: mes_purchase_apply_status, mes_purchase_type
-- 注意：菜单和权限码由 MesMenuRegistry Java Runner 注册

-- ============================================================
-- 一、建表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_purchase_apply (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    code            VARCHAR(50)  NOT NULL COMMENT '申请单号',
    dept_id         VARCHAR(32)  COMMENT '申请部门',
    applicant_id    VARCHAR(32)  COMMENT '申请人',
    apply_date      DATETIME     COMMENT '申请日期',
    required_date   DATETIME     COMMENT '需求日期',
    budget_subject  VARCHAR(50)  COMMENT '预算科目',
    total_amount    DECIMAL(18,2) COMMENT '申请金额合计',
    status          VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_purchase_apply_status)',
    remark          VARCHAR(500) COMMENT '备注',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_apply_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-采购申请';

CREATE TABLE IF NOT EXISTS c_mes_purchase_apply_item (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    apply_id        VARCHAR(32)  NOT NULL COMMENT '申请单ID',
    line_no         INT          COMMENT '行号',
    material_id     VARCHAR(32)  NOT NULL COMMENT '物料ID',
    quantity        DECIMAL(18,4) COMMENT '申请数量',
    unit            VARCHAR(20)  COMMENT '单位',
    purpose         VARCHAR(200) COMMENT '用途说明',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    PRIMARY KEY (id),
    INDEX idx_item_apply_id (apply_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-采购申请行';

-- ============================================================
-- 二、字典注册
-- ============================================================
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '采购申请状态', 'mes_purchase_apply_status', 'MES采购申请状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_apply_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_apply_status'), '草稿',   '1', '新建未提交', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_apply_status'), '已提交', '2', '已提交待审批', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_apply_status'), '已通过', '3', '审批通过',   3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_apply_status'), '已驳回', '4', '审批驳回',   4, 1, 'admin', NOW(), 'admin', NOW());

INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '采购类型', 'mes_purchase_type', 'MES采购类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_type');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_type'), '原材料', '1', '原材料采购', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_type'), '包材',   '2', '包材采购',   2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_type'), '设备',   '3', '设备采购',   3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_type'), '服务',   '4', '服务采购',   4, 1, 'admin', NOW(), 'admin', NOW());

-- ============================================================
-- 三、角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id = 'mes_purchase_apply' OR p.id LIKE 'mes:purchaseApply:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_purchase_apply' OR p.id LIKE 'mes:purchaseApply:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
