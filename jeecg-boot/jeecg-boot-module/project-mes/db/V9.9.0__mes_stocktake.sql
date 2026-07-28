-- V9.9.0 MES 盘点单
-- CREATE TABLE: c_mes_stocktake(_item)
-- 字典: mes_stocktake_type（全盘/抽盘）
-- 编码规则: PD（盘点单前缀）
-- 注意：菜单和权限码由 MesMenuRegistry Java Runner 注册，本文件不含中文菜单名

-- ============================================================
-- 一、建表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_stocktake (
    id                VARCHAR(32)  NOT NULL COMMENT '主键',
    code              VARCHAR(50)  NOT NULL COMMENT '盘点单号',
    warehouse_id      VARCHAR(32)  NOT NULL COMMENT '仓库ID(单仓盘点)',
    take_type         VARCHAR(20)  DEFAULT '1' COMMENT '盘点类型(dict:mes_stocktake_type 1全盘2抽盘)',
    status            VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_other_stock_status)',
    take_date         DATETIME     COMMENT '盘点日期',
    snapshot_time     DATETIME     COMMENT '账面快照时间(book_qty取数时点)',
    total_diff_amount DECIMAL(18,2) COMMENT '差异金额合计(冗余展示)',
    remark            VARCHAR(500) COMMENT '备注',
    create_by         VARCHAR(50)  COMMENT '创建人',
    create_time       DATETIME     COMMENT '创建时间',
    update_by         VARCHAR(50)  COMMENT '更新人',
    update_time       DATETIME     COMMENT '更新时间',
    del_flag          INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_stocktake_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-盘点单';

CREATE TABLE IF NOT EXISTS c_mes_stocktake_item (
    id                VARCHAR(32)  NOT NULL COMMENT '主键',
    take_id           VARCHAR(32)  NOT NULL COMMENT '盘点单ID',
    line_no           INT          COMMENT '行号',
    material_id       VARCHAR(32)  NOT NULL COMMENT '物料ID',
    book_qty          DECIMAL(18,4) NOT NULL COMMENT '账面数量(快照)',
    actual_qty        DECIMAL(18,4) COMMENT '实盘数量(全盘默认=账面,抽盘必填)',
    diff_qty          DECIMAL(18,4) COMMENT '差异数量(实盘-账面)',
    unit_cost         DECIMAL(18,4) COMMENT '成本单价(快照移动平均)',
    diff_amount       DECIMAL(18,2) COMMENT '差异金额(diff_qty*unit_cost)',
    generated_in_id   VARCHAR(32)  COMMENT '盘盈生成的入库单ID',
    generated_out_id  VARCHAR(32)  COMMENT '盘亏生成的出库单ID',
    create_by         VARCHAR(50)  COMMENT '创建人',
    create_time       DATETIME     COMMENT '创建时间',
    update_by         VARCHAR(50)  COMMENT '更新人',
    update_time       DATETIME     COMMENT '更新时间',
    PRIMARY KEY (id),
    INDEX idx_item_take_id (take_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-盘点单行';

-- ============================================================
-- 二、字典（DELETE+INSERT 幂等）
-- ============================================================
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES
(REPLACE(UUID(),'-',''), '盘点类型', 'mes_stocktake_type', 'MES盘点单类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_stocktake_type');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_stocktake_type'), '全盘', '1', '整仓全部物料盘点', 1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_stocktake_type'), '抽盘', '2', '手工选择部分物料盘点', 2, 1, 'admin', NOW(), 'admin', NOW());

-- ============================================================
-- 三、编码规则（INSERT IGNORE + 固定 id 幂等，运行数据自持）
-- ============================================================
INSERT IGNORE INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, `current_date`, biz_type, create_by, create_time, update_by, update_time, del_flag)
VALUES ('mes_code_rule_PD', 'PD', '盘点单编码', 'PD', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'PD', 'admin', NOW(), 'admin', NOW(), 0);

-- 编码规则业务类型字典：仅当不存在时才插入
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(), '-', ''), d.id, '盘点单', 'PD', 'stock/stocktake', 13, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict d
WHERE d.dict_code = 'mes_code_biz_type'
  AND NOT EXISTS (SELECT 1 FROM sys_dict_item di WHERE di.dict_id = d.id AND di.item_value = 'PD');
