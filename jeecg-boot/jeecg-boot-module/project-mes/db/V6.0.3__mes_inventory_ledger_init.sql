-- MES 库存台账模块 V6.0.3
-- CREATE TABLE: c_mes_inventory_ledger + c_mes_inventory
-- 注意：菜单和权限码由 MesMenuRegistry Java Runner 注册

-- ============================================================
-- 一、建表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_inventory (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    material_id     VARCHAR(32)  NOT NULL COMMENT '物料ID',
    warehouse_id    VARCHAR(32)  NOT NULL COMMENT '仓库ID',
    current_qty     DECIMAL(18,4) DEFAULT 0 COMMENT '当前库存数量',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_inv_material_wh (material_id, warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-库存快照';

CREATE TABLE IF NOT EXISTS c_mes_inventory_ledger (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    material_id     VARCHAR(32)  NOT NULL COMMENT '物料ID',
    warehouse_id    VARCHAR(32)  NOT NULL COMMENT '仓库ID',
    beginning_qty   DECIMAL(18,4) COMMENT '期初数量',
    in_qty          DECIMAL(18,4) COMMENT '本期入库',
    out_qty         DECIMAL(18,4) COMMENT '本期出库',
    ending_qty      DECIMAL(18,4) COMMENT '期末数量',
    record_date     DATETIME     COMMENT '记录日期',
    biz_type        VARCHAR(50)  COMMENT '业务类型(采购入库/销售出库/生产领料/完工入库)',
    biz_id          VARCHAR(32)  COMMENT '业务单号',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    PRIMARY KEY (id),
    INDEX idx_ledger_material (material_id),
    INDEX idx_ledger_warehouse (warehouse_id),
    INDEX idx_ledger_date (record_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-库存台账';

-- ============================================================
-- 二、角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id = 'mes_inventory_ledger' OR p.id LIKE 'mes:inventoryLedger:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_inventory_ledger' OR p.id LIKE 'mes:inventoryLedger:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
