-- MES 其它出入库模块 V9.8.0
-- CREATE TABLE: c_mes_other_stock_in(_item) + c_mes_other_stock_out(_item)
-- 字典: mes_other_stock_in_type / mes_other_stock_out_type / mes_other_stock_status
-- 编码规则: QI(QT-IN 前缀) / QO(QT-OUT 前缀)
-- 注意：菜单和权限码由 MesMenuRegistry Java Runner 注册，本文件不含中文菜单名

-- ============================================================
-- 一、建表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_other_stock_in (
    id                VARCHAR(32)  NOT NULL COMMENT '主键',
    code              VARCHAR(50)  NOT NULL COMMENT '入库单号',
    in_type           VARCHAR(20)  COMMENT '入库类型(dict:mes_other_stock_in_type)',
    reason            VARCHAR(500) COMMENT '原因(手工填)',
    stock_date        DATETIME     COMMENT '出入库日期',
    status            VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_other_stock_status)',
    remark            VARCHAR(500) COMMENT '备注',
    create_by         VARCHAR(50)  COMMENT '创建人',
    create_time       DATETIME     COMMENT '创建时间',
    update_by         VARCHAR(50)  COMMENT '更新人',
    update_time       DATETIME     COMMENT '更新时间',
    del_flag          INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_other_stock_in_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-其它入库';

CREATE TABLE IF NOT EXISTS c_mes_other_stock_in_item (
    id                VARCHAR(32)  NOT NULL COMMENT '主键',
    in_id             VARCHAR(32)  NOT NULL COMMENT '入库单ID',
    line_no           INT          COMMENT '行号',
    material_id       VARCHAR(32)  NOT NULL COMMENT '物料ID',
    warehouse_id      VARCHAR(32)  NOT NULL COMMENT '仓库ID',
    location_id       VARCHAR(32)  COMMENT '库位ID(仅记录,不参与库存计算)',
    qty               DECIMAL(18,4) NOT NULL COMMENT '数量',
    create_by         VARCHAR(50)  COMMENT '创建人',
    create_time       DATETIME     COMMENT '创建时间',
    update_by         VARCHAR(50)  COMMENT '更新人',
    update_time       DATETIME     COMMENT '更新时间',
    PRIMARY KEY (id),
    INDEX idx_item_in_id (in_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-其它入库行';

CREATE TABLE IF NOT EXISTS c_mes_other_stock_out (
    id                VARCHAR(32)  NOT NULL COMMENT '主键',
    code              VARCHAR(50)  NOT NULL COMMENT '出库单号',
    out_type          VARCHAR(20)  COMMENT '出库类型(dict:mes_other_stock_out_type)',
    reason            VARCHAR(500) COMMENT '原因(手工填)',
    stock_date        DATETIME     COMMENT '出入库日期',
    status            VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_other_stock_status)',
    remark            VARCHAR(500) COMMENT '备注',
    create_by         VARCHAR(50)  COMMENT '创建人',
    create_time       DATETIME     COMMENT '创建时间',
    update_by         VARCHAR(50)  COMMENT '更新人',
    update_time       DATETIME     COMMENT '更新时间',
    del_flag          INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_other_stock_out_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-其它出库';

CREATE TABLE IF NOT EXISTS c_mes_other_stock_out_item (
    id                VARCHAR(32)  NOT NULL COMMENT '主键',
    out_id            VARCHAR(32)  NOT NULL COMMENT '出库单ID',
    line_no           INT          COMMENT '行号',
    material_id       VARCHAR(32)  NOT NULL COMMENT '物料ID',
    warehouse_id      VARCHAR(32)  NOT NULL COMMENT '仓库ID',
    location_id       VARCHAR(32)  COMMENT '库位ID(仅记录,不参与库存计算)',
    qty               DECIMAL(18,4) NOT NULL COMMENT '数量',
    create_by         VARCHAR(50)  COMMENT '创建人',
    create_time       DATETIME     COMMENT '创建时间',
    update_by         VARCHAR(50)  COMMENT '更新人',
    update_time       DATETIME     COMMENT '更新时间',
    PRIMARY KEY (id),
    INDEX idx_item_out_id (out_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-其它出库行';

-- ============================================================
-- 二、字典注册（DELETE+INSERT 幂等）
-- ============================================================
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '其它入库类型', 'mes_other_stock_in_type', 'MES其它入库类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_in_type');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_in_type'), '盘盈',   '1', '盘点盈余入库', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_in_type'), '期初',   '2', '期初库存录入', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_in_type'), '归还',   '3', '借出归还入库', 3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_in_type'), '其他',   '9', '其他原因入库', 9, 1, 'admin', NOW(), 'admin', NOW());

INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '其它出库类型', 'mes_other_stock_out_type', 'MES其它出库类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_out_type');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_out_type'), '盘亏',   '1', '盘点亏损出库', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_out_type'), '报废',   '2', '报废损耗出库', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_out_type'), '领用',   '3', '样品/办公领用', 3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_out_type'), '其他',   '9', '其他原因出库', 9, 1, 'admin', NOW(), 'admin', NOW());

INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '其它出入库状态', 'mes_other_stock_status', 'MES其它出入库状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_status'), '草稿',   '1', '新建未审核', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_other_stock_status'), '已审核', '2', '已审核库存已变动', 2, 1, 'admin', NOW(), 'admin', NOW());

-- ============================================================
-- 三、编码规则（INSERT IGNORE + 固定 id 幂等，运行数据自持）
-- ============================================================
INSERT IGNORE INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, `current_date`, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES ('mes_code_rule_QI', 'QI', '其它入库编码', 'QT-IN', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'QI', 'admin', NOW(), 'admin', NOW(), 0);

INSERT IGNORE INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, `current_date`, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES ('mes_code_rule_QO', 'QO', '其它出库编码', 'QT-OUT', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'QO', 'admin', NOW(), 'admin', NOW(), 0);

-- 编码规则业务类型字典：仅当不存在时才插入
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(), '-', ''), d.id, '其它入库', 'QI', 'stock/other-in', 12, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict d
WHERE d.dict_code = 'mes_code_biz_type'
  AND NOT EXISTS (SELECT 1 FROM sys_dict_item di WHERE di.dict_id = d.id AND di.item_value = 'QI');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(), '-', ''), d.id, '其它出库', 'QO', 'stock/other-out', 13, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict d
WHERE d.dict_code = 'mes_code_biz_type'
  AND NOT EXISTS (SELECT 1 FROM sys_dict_item di WHERE di.dict_id = d.id AND di.item_value = 'QO');

-- ============================================================
-- 四、角色授权（菜单/权限码由 MesMenuRegistry 注册后，此处绑定到角色）
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id IN ('mes_other_stock_in', 'mes_other_stock_out')
   OR p.id LIKE 'mes:otherStockIn:%' OR p.id LIKE 'mes:otherStockOut:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id IN ('mes_other_stock_in', 'mes_other_stock_out')
   OR p.id LIKE 'mes:otherStockIn:%' OR p.id LIKE 'mes:otherStockOut:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
