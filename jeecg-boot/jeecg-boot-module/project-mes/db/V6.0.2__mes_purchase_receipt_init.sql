-- MES 采购入库模块 V6.0.2
-- CREATE TABLE: c_mes_purchase_receipt + c_mes_purchase_receipt_item
-- 字典: mes_qc_result
-- 注意：菜单和权限码由 MesMenuRegistry Java Runner 注册

-- ============================================================
-- 一、建表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_purchase_receipt (
    id                VARCHAR(32)  NOT NULL COMMENT '主键',
    code              VARCHAR(50)  NOT NULL COMMENT '入库单号',
    purchase_order_id VARCHAR(32)  COMMENT '关联采购订单ID',
    supplier_id       VARCHAR(32)  COMMENT '供应商ID',
    warehouse_id      VARCHAR(32)  COMMENT '仓库ID',
    receipt_date      DATETIME     COMMENT '入库日期',
    status            VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:yn)',
    remark            VARCHAR(500) COMMENT '备注',
    create_by         VARCHAR(50)  COMMENT '创建人',
    create_time       DATETIME     COMMENT '创建时间',
    update_by         VARCHAR(50)  COMMENT '更新人',
    update_time       DATETIME     COMMENT '更新时间',
    del_flag          INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_receipt_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-采购入库';

CREATE TABLE IF NOT EXISTS c_mes_purchase_receipt_item (
    id                VARCHAR(32)  NOT NULL COMMENT '主键',
    receipt_id        VARCHAR(32)  NOT NULL COMMENT '入库单ID',
    line_no           INT          COMMENT '行号',
    material_id       VARCHAR(32)  NOT NULL COMMENT '物料ID',
    order_quantity    DECIMAL(18,4) COMMENT '采购数量',
    receipt_quantity  DECIMAL(18,4) COMMENT '本次入库数量',
    qc_result         VARCHAR(20)  COMMENT '质检结果(dict:mes_qc_result)',
    create_by         VARCHAR(50)  COMMENT '创建人',
    create_time       DATETIME     COMMENT '创建时间',
    update_by         VARCHAR(50)  COMMENT '更新人',
    update_time       DATETIME     COMMENT '更新时间',
    PRIMARY KEY (id),
    INDEX idx_item_receipt_id (receipt_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-采购入库行';

-- ============================================================
-- 二、字典注册
-- ============================================================
-- P0修复：入库状态字典（替换yn）
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '入库状态', 'mes_purchase_receipt_status', 'MES采购入库状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_receipt_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_receipt_status'), '草稿',   '1', '新建未入库', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_purchase_receipt_status'), '已入库', '2', '已入库完成', 2, 1, 'admin', NOW(), 'admin', NOW());

INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '质检结果', 'mes_qc_result', 'MES质检结果字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_qc_result');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_qc_result'), '合格', '1', '质检合格可入库', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_qc_result'), '不合格', '2', '质检不合格需退货', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_qc_result'), '待检',   '3', '待质检',         3, 1, 'admin', NOW(), 'admin', NOW());

-- ============================================================
-- 三、角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id = 'mes_purchase_receipt' OR p.id LIKE 'mes:purchaseReceipt:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_purchase_receipt' OR p.id LIKE 'mes:purchaseReceipt:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
