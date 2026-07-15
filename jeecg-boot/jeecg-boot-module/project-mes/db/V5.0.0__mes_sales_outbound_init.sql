-- MES 销售出库模块 V5.0.0
-- 字典: mes_outbound_status
-- 菜单和权限码由 MesMenuRegistry Java Runner 注册

CREATE TABLE IF NOT EXISTS c_mes_sales_outbound (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    code            VARCHAR(50)  NOT NULL COMMENT '出库单编码',
    delivery_note_id VARCHAR(32) COMMENT '关联发货单ID',
    sales_order_id  VARCHAR(32)  COMMENT '关联销售订单ID',
    warehouse_id    VARCHAR(32)  NOT NULL COMMENT '出库仓库ID',
    customer_id     VARCHAR(32)  COMMENT '客户ID(冗余)',
    outbound_date   DATETIME     COMMENT '出库日期',
    status          VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_outbound_status)',
    remark          VARCHAR(500) COMMENT '备注',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_outbound_code_del (code, del_flag),
    INDEX idx_outbound_delivery (delivery_note_id),
    INDEX idx_outbound_status (status),
    INDEX idx_outbound_create_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-销售出库单';

-- 字典: 出库单状态
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '出库单状态', 'mes_outbound_status', 'MES出库单状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_outbound_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_outbound_status'), '草稿',   '1', '新建未审核', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_outbound_status'), '待审核', '2', '等待审核',   2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_outbound_status'), '已审核', '3', '审核通过',   3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_outbound_status'), '已取消', '0', '出库已取消', 4, 1, 'admin', NOW(), 'admin', NOW());

-- 角色授权
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p WHERE p.id = 'mes_sales_outbound' OR p.id LIKE 'mes:outbound:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p WHERE (p.id = 'mes_sales_outbound' OR p.id LIKE 'mes:outbound:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
