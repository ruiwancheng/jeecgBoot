-- ====================================================================
-- MES 客户管理初始化 SQL
-- 包含: DDL 建表、字典数据
-- 可重复执行（全部使用 WHERE NOT EXISTS）
-- ====================================================================

-- 1. DDL: 客户表
CREATE TABLE IF NOT EXISTS c_mes_customer (
    id varchar(32) NOT NULL COMMENT '主键',
    code varchar(50) NOT NULL COMMENT '客户编码',
    name varchar(100) NOT NULL COMMENT '客户名称',
    type varchar(50) DEFAULT NULL COMMENT '客户类型',
    contact varchar(50) DEFAULT NULL COMMENT '联系人',
    phone varchar(20) DEFAULT NULL COMMENT '联系电话',
    address varchar(255) DEFAULT NULL COMMENT '地址',
    status int DEFAULT 1 COMMENT '状态 1启用 0停用',
    remark varchar(255) DEFAULT NULL COMMENT '备注',
    create_by varchar(50) DEFAULT NULL,
    create_time datetime DEFAULT NULL,
    update_by varchar(50) DEFAULT NULL,
    update_time datetime DEFAULT NULL,
    del_flag int DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE KEY uk_mes_customer_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户表';

-- 2. 字典: MES客户类型
INSERT INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
SELECT REPLACE(UUID(),'-',''), 'MES客户类型', 'mes_customer_type', 'MES客户类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0
WHERE NOT EXISTS (SELECT 1 FROM sys_dict WHERE dict_code='mes_customer_type');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_customer_type'), '企业客户', '1', '企业客户', 1, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_customer_type') AND item_value='1');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_customer_type'), '个人客户', '2', '个人客户', 2, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_customer_type') AND item_value='2');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_customer_type'), '供应商', '3', '供应商客户', 3, 1, 'admin', NOW(), 'admin', NOW()
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id=(SELECT id FROM sys_dict WHERE dict_code='mes_customer_type') AND item_value='3');
