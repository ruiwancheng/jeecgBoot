-- MES 采购订单模块 V6.0.1
-- CREATE TABLE: c_mes_purchase_order + c_mes_purchase_order_item
-- 字典: mes_purchase_order_status
-- 注意：菜单和权限码由 MesMenuRegistry Java Runner 注册

-- ============================================================
-- 一、建表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_purchase_order (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    code            VARCHAR(50)  NOT NULL COMMENT '订单编号',
    supplier_id     VARCHAR(32)  NOT NULL COMMENT '供应商ID',
    purchase_type   VARCHAR(20)  COMMENT '采购类型(dict:mes_purchase_type)',
    order_date      DATETIME     COMMENT '订单日期',
    delivery_date   DATETIME     COMMENT '交货日期',
    payment_terms   VARCHAR(50)  COMMENT '付款条款',
    total_amount    DECIMAL(18,2) COMMENT '不含税金额',
    tax_amount      DECIMAL(18,2) COMMENT '税额',
    total_with_tax  DECIMAL(18,2) COMMENT '含税总额',
    status          VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_purchase_order_status)',
    remark          VARCHAR(500) COMMENT '备注',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_po_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-采购订单';

CREATE TABLE IF NOT EXISTS c_mes_purchase_order_item (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    order_id        VARCHAR(32)  NOT NULL COMMENT '订单ID',
    line_no         INT          COMMENT '行号',
    material_id     VARCHAR(32)  NOT NULL COMMENT '物料ID',
    quantity        DECIMAL(18,4) COMMENT '数量',
    unit_price      DECIMAL(18,2) COMMENT '单价',
    tax_rate        DECIMAL(5,2)  DEFAULT 0.13 COMMENT '税率',
    amount          DECIMAL(18,2) COMMENT '金额(服务端计算)',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    PRIMARY KEY (id),
    INDEX idx_item_po_id (order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-采购订单行';

-- ============================================================
-- 二、字典注册
-- ============================================================
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '采购订单状态', 'mes_purchase_order_status', 'MES采购订单状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_order_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_order_status'), '草稿',     '1', '新建未确认',   1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_order_status'), '待确认',   '2', '待供应商确认', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_order_status'), '已确认',   '3', '供应商已确认', 3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_order_status'), '部分到货', '4', '部分入库',     4, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_order_status'), '已到货',   '5', '全部入库',     5, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_order_status'), '已关闭',   '6', '订单已关闭',   6, 1, 'admin', NOW(), 'admin', NOW());

-- ============================================================
-- 三、角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id = 'mes_purchase_order' OR p.id LIKE 'mes:purchaseOrder:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_purchase_order' OR p.id LIKE 'mes:purchaseOrder:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
