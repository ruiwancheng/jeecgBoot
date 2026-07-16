-- MES 生产制造模块 V7.0.1 — 生产订单
CREATE TABLE IF NOT EXISTS c_mes_production_order (
    id              VARCHAR(32)  NOT NULL COMMENT '主键',
    code            VARCHAR(50)  NOT NULL COMMENT '订单编号',
    product_id      VARCHAR(32)  NOT NULL COMMENT '生产产品ID',
    bom_id          VARCHAR(32)  COMMENT '关联BOM ID',
    plan_qty        DECIMAL(18,4) COMMENT '计划数量',
    completed_qty   DECIMAL(18,4) DEFAULT 0 COMMENT '已完工数量',
    start_date      DATETIME     COMMENT '计划开工日期',
    end_date        DATETIME     COMMENT '计划完工日期',
    warehouse_id    VARCHAR(32)  COMMENT '完工仓库ID',
    status          VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_production_order_status)',
    remark          VARCHAR(500) COMMENT '备注',
    create_by       VARCHAR(50), create_time DATETIME, update_by VARCHAR(50), update_time DATETIME,
    del_flag        INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_prod_order_code (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-生产订单';

-- 字典
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '生产订单状态', 'mes_production_order_status', 'MES生产订单状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_production_order_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_production_order_status'), '草稿',   '1', '新建未审核',   1, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_production_order_status'), '已审核', '2', '审核通过可下达', 2, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_production_order_status'), '已下达', '3', '已下发车间',   3, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_production_order_status'), '执行中', '4', '已有领料或报工', 4, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_production_order_status'), '已完工', '5', '完工数量达标', 5, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_production_order_status'), '已关闭', '6', '订单关闭',     6, 1, 'admin', NOW(), 'admin', NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_production_order_status'), '已取消', '7', '订单已取消',   7, 1, 'admin', NOW(), 'admin', NOW());

-- 角色授权
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1' FROM sys_permission p WHERE p.id = 'mes_production_order' OR p.id LIKE 'mes:productionOrder:%';
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p WHERE (p.id = 'mes_production_order' OR p.id LIKE 'mes:productionOrder:%') AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
