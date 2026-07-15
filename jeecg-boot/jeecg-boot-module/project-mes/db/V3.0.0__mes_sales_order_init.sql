-- MES 销售订单模块 V3.0.0
-- CREATE TABLE: c_mes_sales_order + c_mes_sales_order_item
-- 字典: mes_order_status
-- 注意：菜单和权限码由 MesMenuRegistry Java Runner 注册

-- ============================================================
-- 一、建表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_sales_order (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    code            VARCHAR(50)  NOT NULL COMMENT '订单编码',
    customer_id     VARCHAR(32)  NOT NULL COMMENT '客户ID',
    order_date      DATETIME     COMMENT '订单日期',
    delivery_date   DATETIME     COMMENT '交货日期',
    status          VARCHAR(20)  DEFAULT '1' COMMENT '订单状态(dict:mes_order_status)',
    total_amount    DECIMAL(18,2) COMMENT '订单总金额',
    remark          VARCHAR(500) COMMENT '备注',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_order_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-销售订单';

CREATE TABLE IF NOT EXISTS c_mes_sales_order_item (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    order_id        VARCHAR(32)  NOT NULL COMMENT '订单ID',
    line_no         INT          COMMENT '行号',
    material_id     VARCHAR(32)  NOT NULL COMMENT '物料ID',
    quantity        DECIMAL(18,4) COMMENT '数量',
    unit_price      DECIMAL(18,2) COMMENT '单价',
    amount          DECIMAL(18,2) COMMENT '金额',
    remark          VARCHAR(200) COMMENT '备注',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    PRIMARY KEY (id),
    INDEX idx_item_order_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-销售订单行';

-- ============================================================
-- 二、字典注册
-- ============================================================
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '订单状态', 'mes_order_status', 'MES销售订单状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_order_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_order_status'), '草稿',   '1', '新建未审核', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_order_status'), '已审核', '2', '审核通过',   2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_order_status'), '已下达', '3', '已下达到车间', 3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_order_status'), '已发货', '4', '已发货',     4, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_order_status'), '已关闭', '5', '订单已关闭', 5, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_order_status'), '已取消', '6', '订单已取消', 6, 1, 'admin', NOW(), 'admin', NOW());

-- ============================================================
-- 三、角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id = 'mes_sales_order' OR p.id LIKE 'mes:salesOrder:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_sales_order' OR p.id LIKE 'mes:salesOrder:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
