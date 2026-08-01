-- MES 全局开关 V8.0.2
-- 全局开关表（key-value 结构，支持后续扩展"启用条码"、"启用多组织"等开关）

CREATE TABLE IF NOT EXISTS c_mes_global_switch (
    id varchar(32) NOT NULL COMMENT '主键',
    switch_key varchar(50) NOT NULL COMMENT '开关标识',
    switch_value int NOT NULL DEFAULT 0 COMMENT '开关值(0关/1开)',
    switch_name varchar(100) DEFAULT NULL COMMENT '开关名称',
    description varchar(500) DEFAULT NULL COMMENT '开关描述',
    create_by varchar(32) DEFAULT NULL,
    create_time datetime DEFAULT NULL,
    update_by varchar(32) DEFAULT NULL,
    update_time datetime DEFAULT NULL,
    PRIMARY KEY (id),
    UNIQUE KEY uk_switch_key (switch_key)
) COMMENT='MES全局开关表';

-- 种子数据：生产批次管理总开关（默认关闭）
INSERT INTO c_mes_global_switch (id, switch_key, switch_value, switch_name, description)
VALUES ('mes_global_switch_batch_001', 'mes_batch_enabled', 0, '生产批次管理', '生产批次管理总开关，关闭后物料级批次开关失效，不创建/扣减批次')
ON DUPLICATE KEY UPDATE switch_name = VALUES(switch_name), description = VALUES(description);