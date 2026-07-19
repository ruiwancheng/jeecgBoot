-- MES 业财管控模块 V9.1.0 — 收付款闭环
-- CREATE TABLE: c_mes_collection + c_mes_payment

-- ============================================================
-- 1. 收款单
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_collection (
    id                  VARCHAR(32)  NOT NULL COMMENT '主键',
    code                VARCHAR(50)  NOT NULL COMMENT '收款单号',
    customer_id         VARCHAR(32)  NOT NULL COMMENT '客户ID',
    receivable_id       VARCHAR(32)  COMMENT '关联应收单ID',
    amount              DECIMAL(18,2) NOT NULL COMMENT '收款金额',
    collection_date     DATETIME     COMMENT '收款日期',
    payment_method      VARCHAR(20)  DEFAULT '1' COMMENT '收款方式(dict:mes_payment_method)',
    status              VARCHAR(20)  DEFAULT '1' COMMENT '状态 1已收款 0已作废',
    remark              VARCHAR(500) COMMENT '备注',
    create_by           VARCHAR(50),  create_time DATETIME,
    update_by           VARCHAR(50),  update_time DATETIME,
    del_flag            INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_col_code_del (code, del_flag),
    INDEX idx_col_customer (customer_id),
    INDEX idx_col_receivable (receivable_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-收款单';

-- ============================================================
-- 2. 付款单
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_payment (
    id                  VARCHAR(32)  NOT NULL COMMENT '主键',
    code                VARCHAR(50)  NOT NULL COMMENT '付款单号',
    supplier_id         VARCHAR(32)  NOT NULL COMMENT '供应商ID',
    payable_id          VARCHAR(32)  COMMENT '关联应付单ID',
    amount              DECIMAL(18,2) NOT NULL COMMENT '付款金额',
    payment_date        DATETIME     COMMENT '付款日期',
    payment_method      VARCHAR(20)  DEFAULT '1' COMMENT '付款方式(dict:mes_payment_method)',
    status              VARCHAR(20)  DEFAULT '1' COMMENT '状态 1已付款 0已作废',
    remark              VARCHAR(500) COMMENT '备注',
    create_by           VARCHAR(50),  create_time DATETIME,
    update_by           VARCHAR(50),  update_time DATETIME,
    del_flag            INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_pmt_code_del (code, del_flag),
    INDEX idx_pmt_supplier (supplier_id),
    INDEX idx_pmt_payable (payable_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-付款单';

-- ============================================================
-- 3. 字典：收款/付款方式
-- ============================================================
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '收付款方式', 'mes_payment_method', 'MES收付款方式字典', 0, 'admin', NOW(), 'admin', NOW(), 0);
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_payment_method');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_payment_method'), '银行转账', '1', '银行转账', 1,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_payment_method'), '现金', '2', '现金', 2,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_payment_method'), '支票', '3', '支票', 3,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_payment_method'), '微信/支付宝', '4', '第三方支付', 4,1,'admin',NOW(),'admin',NOW());

-- ============================================================
-- 4. 角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id LIKE 'mes:collection:%' OR p.id LIKE 'mes:payment:%';
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id LIKE 'mes:collection:%' OR p.id LIKE 'mes:payment:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
