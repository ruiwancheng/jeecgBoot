-- MES 生产制造模块 V7.0.3 — 完工入库
CREATE TABLE IF NOT EXISTS c_mes_completion_receipt (
    id                  VARCHAR(32)  NOT NULL COMMENT '主键',
    code                VARCHAR(50)  NOT NULL COMMENT '入库单号',
    production_order_id VARCHAR(32)  NOT NULL COMMENT '生产订单ID',
    product_id          VARCHAR(32)  COMMENT '产品物料ID',
    warehouse_id        VARCHAR(32)  COMMENT '入库仓库ID',
    receipt_date        DATETIME     COMMENT '入库日期',
    status              VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_completion_status)',
    remark              VARCHAR(500) COMMENT '备注',
    create_by           VARCHAR(50), create_time DATETIME, update_by VARCHAR(50), update_time DATETIME,
    del_flag            INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_completion_code (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-完工入库';

CREATE TABLE IF NOT EXISTS c_mes_completion_receipt_item (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    receipt_id      VARCHAR(32)  NOT NULL COMMENT '入库单ID',
    line_no         INT          COMMENT '行号',
    material_id     VARCHAR(32)  NOT NULL COMMENT '产品物料ID',
    plan_qty        DECIMAL(18,4) COMMENT '计划数量',
    receipt_qty     DECIMAL(18,4) COMMENT '本次入库数量',
    create_by       VARCHAR(50), create_time DATETIME, update_by VARCHAR(50), update_time DATETIME,
    PRIMARY KEY (id),
    INDEX idx_item_completion_id (receipt_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-完工入库行';

-- 字典
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '完工入库状态', 'mes_completion_status', 'MES完工入库状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_completion_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_completion_status'), '草稿',   '1', '新建未入库', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_completion_status'), '已入库', '2', '已入库完成', 2, 1, 'admin', NOW(), 'admin', NOW());

-- 角色授权
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1' FROM sys_permission p WHERE p.id = 'mes_completion_receipt' OR p.id LIKE 'mes:completionReceipt:%';
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p WHERE (p.id = 'mes_completion_receipt' OR p.id LIKE 'mes:completionReceipt:%') AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
