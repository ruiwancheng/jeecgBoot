-- MES 业财管控 V9.2.0 — 发票管理
CREATE TABLE IF NOT EXISTS c_mes_sales_invoice (
    id              VARCHAR(32) NOT NULL COMMENT '主键', code VARCHAR(50) NOT NULL COMMENT '发票单号',
    invoice_no      VARCHAR(50) COMMENT '发票号码', customer_id VARCHAR(32) NOT NULL COMMENT '客户ID',
    sales_order_id  VARCHAR(32) COMMENT '关联订单ID', outbound_id VARCHAR(32) COMMENT '关联出库单ID',
    invoice_date    DATETIME COMMENT '开票日期', amount DECIMAL(18,2) COMMENT '不含税金额',
    tax_rate        DECIMAL(5,2) DEFAULT 0.13 COMMENT '税率', tax_amount DECIMAL(18,2) COMMENT '税额',
    total_with_tax  DECIMAL(18,2) COMMENT '价税合计', invoice_type VARCHAR(20) DEFAULT '1' COMMENT '发票类型(dict:mes_invoice_type)',
    status          VARCHAR(20) DEFAULT '1' COMMENT '状态 1已开票 0已作废', remark VARCHAR(500) COMMENT '备注',
    create_by VARCHAR(50), create_time DATETIME, update_by VARCHAR(50), update_time DATETIME, del_flag INT DEFAULT 0,
    PRIMARY KEY (id), UNIQUE INDEX uk_si_code_del (code, del_flag), INDEX idx_si_customer (customer_id), INDEX idx_si_order (sales_order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-销项发票';

CREATE TABLE IF NOT EXISTS c_mes_purchase_invoice (
    id              VARCHAR(32) NOT NULL COMMENT '主键', code VARCHAR(50) NOT NULL COMMENT '发票单号',
    invoice_no      VARCHAR(50) COMMENT '发票号码', supplier_id VARCHAR(32) NOT NULL COMMENT '供应商ID',
    purchase_order_id VARCHAR(32) COMMENT '关联采购订单ID', receipt_id VARCHAR(32) COMMENT '关联入库单ID',
    invoice_date    DATETIME COMMENT '收票日期', amount DECIMAL(18,2) COMMENT '不含税金额',
    tax_rate        DECIMAL(5,2) DEFAULT 0.13 COMMENT '税率', tax_amount DECIMAL(18,2) COMMENT '税额',
    total_with_tax  DECIMAL(18,2) COMMENT '价税合计', invoice_type VARCHAR(20) DEFAULT '1' COMMENT '发票类型(dict:mes_invoice_type)',
    status          VARCHAR(20) DEFAULT '1' COMMENT '状态 1已收票 0已作废', remark VARCHAR(500) COMMENT '备注',
    create_by VARCHAR(50), create_time DATETIME, update_by VARCHAR(50), update_time DATETIME, del_flag INT DEFAULT 0,
    PRIMARY KEY (id), UNIQUE INDEX uk_pi_code_del (code, del_flag), INDEX idx_pi_supplier (supplier_id), INDEX idx_pi_order (purchase_order_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-进项发票';

INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '发票类型', 'mes_invoice_type', 'MES发票类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0);
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_invoice_type');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_invoice_type'), '增值税专用发票', '1', '专票', 1,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_invoice_type'), '增值税普通发票', '2', '普票', 2,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_invoice_type'), '电子发票', '3', '电子发票', 3,1,'admin',NOW(),'admin',NOW());

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1' FROM sys_permission p
WHERE p.id LIKE 'mes:salesInvoice:%' OR p.id LIKE 'mes:purchaseInvoice:%';
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1' FROM sys_permission p
WHERE (p.id LIKE 'mes:salesInvoice:%' OR p.id LIKE 'mes:purchaseInvoice:%') AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
