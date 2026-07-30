-- MES 批次管理模块 V8.0.0
-- CREATE TABLE: c_mes_batch + c_mes_batch_inventory + c_mes_batch_ledger
-- 字典: mes_batch_status + mes_batch_origin_type
-- 编码规则: BT (BT-物料编码-YYYYMMDD-序号 格式)

-- ============================================================
-- 一、建表
-- ============================================================

CREATE TABLE IF NOT EXISTS c_mes_batch (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    batch_no        VARCHAR(50)  NOT NULL COMMENT '批次号(系统生成 BT-{物料编码}-{YYYYMMDD}-{序号})',
    material_id     VARCHAR(32)  NOT NULL COMMENT '物料ID',
    origin_type     VARCHAR(20)  NOT NULL COMMENT '来源类型(dict:mes_batch_origin_type)',
    origin_bill_id  VARCHAR(32)  COMMENT '来源单据ID',
    origin_bill_no  VARCHAR(50)  COMMENT '来源单据号',
    qty             DECIMAL(18,4) NOT NULL DEFAULT 0 COMMENT '初始批次数量',
    production_date DATE         COMMENT '生产日期',
    expiry_date     DATE         COMMENT '有效期(可空)',
    unit_cost       DECIMAL(18,4) DEFAULT 0 COMMENT '批次单位成本(采购价/加权平均成本)',
    status          VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_batch_status)',
    remark          VARCHAR(500) COMMENT '备注',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_batch_no_del (batch_no, del_flag),
    INDEX idx_batch_material (material_id),
    INDEX idx_batch_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-批次主档';

CREATE TABLE IF NOT EXISTS c_mes_batch_inventory (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    batch_id        VARCHAR(32)  NOT NULL COMMENT '批次ID',
    batch_no        VARCHAR(50)  NOT NULL COMMENT '批次号(冗余)',
    material_id     VARCHAR(32)  NOT NULL COMMENT '物料ID',
    warehouse_id    VARCHAR(32)  NOT NULL COMMENT '仓库ID',
    qty             DECIMAL(18,4) NOT NULL DEFAULT 0 COMMENT '当前数量',
    unit_cost       DECIMAL(18,4) DEFAULT 0 COMMENT '批次单位成本(冗余便于出库取值)',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    update_by       VARCHAR(50)  COMMENT '更新人',
    update_time     DATETIME     COMMENT '更新时间',
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_batch_warehouse (batch_id, warehouse_id, del_flag),
    INDEX idx_bi_batch (batch_id),
    INDEX idx_bi_material_warehouse (material_id, warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-批次库存';

CREATE TABLE IF NOT EXISTS c_mes_batch_ledger (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    batch_id        VARCHAR(32)  NOT NULL COMMENT '批次ID',
    batch_no        VARCHAR(50)  NOT NULL COMMENT '批次号(冗余)',
    material_id     VARCHAR(32)  NOT NULL COMMENT '物料ID',
    warehouse_id    VARCHAR(32)  NOT NULL COMMENT '仓库ID',
    biz_type        VARCHAR(20)  NOT NULL COMMENT '业务类型(采购入库/生产入库/领料/销售出库)',
    biz_id          VARCHAR(32)  COMMENT '业务单据ID',
    biz_no          VARCHAR(50)  COMMENT '业务单据号',
    in_qty          DECIMAL(18,4) DEFAULT 0 COMMENT '入库数量',
    out_qty         DECIMAL(18,4) DEFAULT 0 COMMENT '出库数量',
    unit_cost       DECIMAL(18,4) DEFAULT 0 COMMENT '批次单位成本',
    occur_time      DATETIME     COMMENT '发生时间',
    remark          VARCHAR(500) COMMENT '备注',
    create_by       VARCHAR(50)  COMMENT '创建人',
    create_time     DATETIME     COMMENT '创建时间',
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_bl_batch (batch_id),
    INDEX idx_bl_biz (biz_type, biz_id),
    INDEX idx_bl_occur_time (occur_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-批次流水';

-- ============================================================
-- 二、字典注册
-- ============================================================

INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '批次状态', 'mes_batch_status', 'MES批次状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_batch_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_batch_status'), '在用',     '1', '批次正常可用',         1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_batch_status'), '冻结',     '2', '禁止使用(质检不合格等)', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_batch_status'), '已耗尽',   '3', '库存数量为0',           3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_batch_status'), '过期',     '4', '超过有效期',            4, 1, 'admin', NOW(), 'admin', NOW());

INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '批次来源类型', 'mes_batch_origin_type', 'MES批次来源类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_batch_origin_type');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_batch_origin_type'), '采购入库', '1', '采购收货时创建',     1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_batch_origin_type'), '生产完工', '2', '完工入库时创建',     2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_batch_origin_type'), '手工创建', '3', '手工创建批次档案',   3, 1, 'admin', NOW(), 'admin', NOW());

-- ============================================================
-- 三、角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id IN ('mes_batch_master', 'mes_batch_inventory', 'mes_batch_ledger', 'mes_batch_traceability');

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id IN ('mes_batch_master', 'mes_batch_inventory', 'mes_batch_ledger', 'mes_batch_traceability'))
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');

-- 备注：菜单/权限码由 MesMenuRegistry Java Runner 注册，本文件不含中文菜单名
