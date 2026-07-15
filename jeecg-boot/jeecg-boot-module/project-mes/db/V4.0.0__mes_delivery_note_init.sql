-- MES 发货单模块 V4.0.0
-- CREATE TABLE: c_mes_delivery_note + c_mes_delivery_note_item
-- 字典: mes_delivery_status
-- 菜单和权限码由 MesMenuRegistry Java Runner 注册

CREATE TABLE IF NOT EXISTS c_mes_delivery_note (
    id                  VARCHAR(32)  NOT NULL COMMENT '主键',
    code                VARCHAR(50)  NOT NULL COMMENT '发货单编码',
    sales_order_id      VARCHAR(32)  NOT NULL COMMENT '关联销售订单ID',
    warehouse_id        VARCHAR(32)  NOT NULL COMMENT '发货仓库ID',
    customer_id         VARCHAR(32)  COMMENT '客户ID(冗余)',
    delivery_date       DATETIME     COMMENT '发货日期',
    status              VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_delivery_status)',
    logistics_company   VARCHAR(100) COMMENT '物流公司',
    tracking_no         VARCHAR(100) COMMENT '运单号',
    remark              VARCHAR(500) COMMENT '备注',
    create_by           VARCHAR(50)  COMMENT '创建人',
    create_time         DATETIME     COMMENT '创建时间',
    update_by           VARCHAR(50)  COMMENT '更新人',
    update_time         DATETIME     COMMENT '更新时间',
    del_flag            INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_delivery_code_del (code, del_flag),
    INDEX idx_delivery_order_id (sales_order_id),
    INDEX idx_delivery_warehouse_id (warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-发货单';

CREATE TABLE IF NOT EXISTS c_mes_delivery_note_item (
    id                  VARCHAR(32)  NOT NULL COMMENT '主键',
    delivery_id         VARCHAR(32)  NOT NULL COMMENT '发货单ID',
    sales_order_item_id VARCHAR(32)  COMMENT '关联订单明细ID',
    material_id         VARCHAR(32)  NOT NULL COMMENT '物料ID',
    ordered_qty         DECIMAL(18,4) COMMENT '订单数量',
    delivery_qty        DECIMAL(18,4) COMMENT '本次发货数量',
    remark              VARCHAR(200) COMMENT '备注',
    create_by           VARCHAR(50)  COMMENT '创建人',
    create_time         DATETIME     COMMENT '创建时间',
    update_by           VARCHAR(50)  COMMENT '更新人',
    update_time         DATETIME     COMMENT '更新时间',
    PRIMARY KEY (id),
    INDEX idx_de_item_delivery_id (delivery_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-发货单明细';

-- 字典: 发货单状态
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '发货单状态', 'mes_delivery_status', 'MES发货单状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_delivery_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_delivery_status'), '草稿',   '1', '新建未出库',   1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_delivery_status'), '待出库', '2', '等待仓库出库', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_delivery_status'), '已出库', '3', '已完成出库',   3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_delivery_status'), '已签收', '4', '客户已签收',   4, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_delivery_status'), '已取消', '0', '发货已取消',   5, 1, 'admin', NOW(), 'admin', NOW());

-- 角色授权
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id = 'mes_sales_delivery' OR p.id LIKE 'mes:delivery:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_sales_delivery' OR p.id LIKE 'mes:delivery:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
