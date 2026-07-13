-- MES 仓库/库位模块升级 V1.1.0
-- 1. 仓库：新增负责人、联系电话
-- 2. 新建库区表、货架表
-- 3. 库位：新增层级关联字段、承重、存放限制
-- 4. 字典：仓库类型补不良品仓、退货仓

ALTER TABLE c_mes_warehouse
    ADD COLUMN manager VARCHAR(50)  COMMENT '负责人',
    ADD COLUMN phone   VARCHAR(20)  COMMENT '联系电话';

CREATE TABLE IF NOT EXISTS c_mes_zone (
    id           VARCHAR(36)  NOT NULL COMMENT '主键',
    warehouse_id VARCHAR(36)  NOT NULL COMMENT '所属仓库ID',
    code         VARCHAR(50)  NOT NULL COMMENT '库区编码',
    name         VARCHAR(100) COMMENT '库区名称',
    sort_no      INT          DEFAULT 0 COMMENT '排序号',
    status       INT          DEFAULT 1 COMMENT '状态 1启用 0停用',
    remark       VARCHAR(255) COMMENT '备注',
    create_by    VARCHAR(50)  COMMENT '创建人',
    create_time  DATETIME     COMMENT '创建时间',
    update_by    VARCHAR(50)  COMMENT '更新人',
    update_time  DATETIME     COMMENT '更新时间',
    del_flag     INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_mes_zone_wh_code (warehouse_id, code),
    INDEX idx_mes_zone_wh (warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-库区表';

CREATE TABLE IF NOT EXISTS c_mes_shelf (
    id           VARCHAR(36)  NOT NULL COMMENT '主键',
    zone_id      VARCHAR(36)  NOT NULL COMMENT '所属库区ID',
    warehouse_id VARCHAR(36)  COMMENT '所属仓库ID(冗余加速)',
    code         VARCHAR(50)  NOT NULL COMMENT '货架编码',
    name         VARCHAR(100) COMMENT '货架名称',
    sort_no      INT          DEFAULT 0 COMMENT '排序号',
    status       INT          DEFAULT 1 COMMENT '状态 1启用 0停用',
    remark       VARCHAR(255) COMMENT '备注',
    create_by    VARCHAR(50)  COMMENT '创建人',
    create_time  DATETIME     COMMENT '创建时间',
    update_by    VARCHAR(50)  COMMENT '更新人',
    update_time  DATETIME     COMMENT '更新时间',
    del_flag     INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_mes_shelf_zone_code (zone_id, code),
    INDEX idx_mes_shelf_zone (zone_id),
    INDEX idx_mes_shelf_wh (warehouse_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-货架表';

ALTER TABLE c_mes_location
    ADD COLUMN zone_id       VARCHAR(36)  COMMENT '所属库区ID',
    ADD COLUMN shelf_id      VARCHAR(36)  COMMENT '所属货架ID',
    ADD COLUMN load_capacity DECIMAL(10,2) COMMENT '承重(kg)',
    ADD COLUMN storage_limit VARCHAR(255) COMMENT '存放物料限制',
    ADD INDEX idx_mes_loc_zone (zone_id),
    ADD INDEX idx_mes_loc_shelf (shelf_id);

-- 仓库类型字典补不良品仓、退货仓
INSERT IGNORE INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time, del_flag)
VALUES
(REPLACE(UUID(), '-', ''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_warehouse_type'), '不良品仓', '5', '不良品存放仓库', 5, 1, 'admin', NOW(), 'admin', NOW(), 0),
(REPLACE(UUID(), '-', ''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_warehouse_type'), '退货仓', '6', '退货存放仓库', 6, 1, 'admin', NOW(), 'admin', NOW(), 0);
