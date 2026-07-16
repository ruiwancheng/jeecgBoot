-- MES 生产制造模块 V7.0.0 — BOM管理
CREATE TABLE IF NOT EXISTS c_mes_bom (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    code            VARCHAR(50)  NOT NULL COMMENT 'BOM编号',
    product_id      VARCHAR(32)  NOT NULL COMMENT '父项物料ID',
    version         VARCHAR(20)  DEFAULT 'V1.0' COMMENT '版本号',
    effective_date  DATETIME     COMMENT '生效日期',
    expiry_date     DATETIME     COMMENT '失效日期',
    status          VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_bom_status)',
    remark          VARCHAR(500) COMMENT '备注',
    create_by       VARCHAR(50), create_time DATETIME, update_by VARCHAR(50), update_time DATETIME,
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_bom_product_version (product_id, version, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-BOM';

CREATE TABLE IF NOT EXISTS c_mes_bom_item (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    bom_id          VARCHAR(32)  NOT NULL COMMENT 'BOM ID',
    line_no         INT          COMMENT '行号',
    material_id     VARCHAR(32)  NOT NULL COMMENT '子项物料ID',
    quantity        DECIMAL(18,4) COMMENT '用量',
    loss_rate       DECIMAL(5,2)  COMMENT '损耗率(%)',
    is_substitute   VARCHAR(1)   DEFAULT '0' COMMENT '是否替代料(yn)',
    create_by       VARCHAR(50), create_time DATETIME, update_by VARCHAR(50), update_time DATETIME,
    PRIMARY KEY (id),
    INDEX idx_item_bom_id (bom_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-BOM子项';

-- 字典
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), 'BOM状态', 'mes_bom_status', 'MES BOM状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_bom_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_bom_status'), '草稿', '1', '新建未审核', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_bom_status'), '生效', '2', '审核通过可用', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_bom_status'), '失效', '3', '已过期不可用', 3, 1, 'admin', NOW(), 'admin', NOW());

-- 角色授权
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1' FROM sys_permission p WHERE p.id = 'mes_bom' OR p.id LIKE 'mes:bom:%';
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p WHERE (p.id = 'mes_bom' OR p.id LIKE 'mes:bom:%') AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
