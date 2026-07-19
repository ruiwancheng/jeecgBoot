-- MES 业财管控模块 V9.0.0
-- CREATE TABLE: c_mes_account_subject + c_mes_receivable + c_mes_payable + c_mes_voucher + c_mes_voucher_item
-- 字典: mes_subject_category, mes_balance_direction, mes_receivable_status, mes_payable_status, mes_voucher_status
-- 注意：菜单和权限码由 MesMenuRegistry Java Runner 注册

-- ============================================================
-- 1. 会计科目（树形结构）
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_account_subject (
    id                  VARCHAR(32)  NOT NULL COMMENT '主键',
    code                VARCHAR(50)  NOT NULL COMMENT '科目编码',
    name                VARCHAR(100) NOT NULL COMMENT '科目名称',
    category            VARCHAR(20)  NOT NULL COMMENT '科目类别(dict:mes_subject_category)',
    level               INT          DEFAULT 1 COMMENT '科目级别',
    parent_id           VARCHAR(32)  COMMENT '上级科目ID',
    balance_direction   VARCHAR(10)  DEFAULT '1' COMMENT '余额方向(dict:mes_balance_direction)',
    status              VARCHAR(20)  DEFAULT '1' COMMENT '状态 1启用 0停用',
    is_leaf             INT          DEFAULT 1 COMMENT '是否叶子科目 1是 0否',
    remark              VARCHAR(500) COMMENT '备注',
    create_by           VARCHAR(50),  create_time DATETIME,
    update_by           VARCHAR(50),  update_time DATETIME,
    del_flag            INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_subject_code_del (code, del_flag),
    INDEX idx_subject_parent (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-会计科目';

-- ============================================================
-- 2. 应收单
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_receivable (
    id                  VARCHAR(32)  NOT NULL COMMENT '主键',
    code                VARCHAR(50)  NOT NULL COMMENT '应收单号',
    customer_id         VARCHAR(32)  NOT NULL COMMENT '客户ID',
    source_type         VARCHAR(50)  COMMENT '来源类型(销售出库)',
    source_bill_id      VARCHAR(32)  COMMENT '来源单据ID',
    source_bill_no      VARCHAR(50)  COMMENT '来源单据号',
    amount              DECIMAL(18,2) NOT NULL COMMENT '应收金额',
    received_amount     DECIMAL(18,2) DEFAULT 0 COMMENT '已收金额',
    unsettled_amount    DECIMAL(18,2) COMMENT '未结金额',
    credit_period       INT          DEFAULT 30 COMMENT '账期(天)',
    due_date            DATETIME     COMMENT '到期日',
    status              VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_receivable_status)',
    settlement_date     DATETIME     COMMENT '结清日期',
    remark              VARCHAR(500) COMMENT '备注',
    create_by           VARCHAR(50),  create_time DATETIME,
    update_by           VARCHAR(50),  update_time DATETIME,
    del_flag            INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_rec_code_del (code, del_flag),
    INDEX idx_rec_customer (customer_id),
    INDEX idx_rec_due_date (due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-应收单';

-- ============================================================
-- 3. 应付单
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_payable (
    id                  VARCHAR(32)  NOT NULL COMMENT '主键',
    code                VARCHAR(50)  NOT NULL COMMENT '应付单号',
    supplier_id         VARCHAR(32)  NOT NULL COMMENT '供应商ID',
    source_type         VARCHAR(50)  COMMENT '来源类型(采购入库)',
    source_bill_id      VARCHAR(32)  COMMENT '来源单据ID',
    source_bill_no      VARCHAR(50)  COMMENT '来源单据号',
    amount              DECIMAL(18,2) NOT NULL COMMENT '应付金额',
    paid_amount         DECIMAL(18,2) DEFAULT 0 COMMENT '已付金额',
    unsettled_amount    DECIMAL(18,2) COMMENT '未付金额',
    credit_period       INT          DEFAULT 30 COMMENT '账期(天)',
    due_date            DATETIME     COMMENT '到期日',
    status              VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_payable_status)',
    settlement_date     DATETIME     COMMENT '结清日期',
    remark              VARCHAR(500) COMMENT '备注',
    create_by           VARCHAR(50),  create_time DATETIME,
    update_by           VARCHAR(50),  update_time DATETIME,
    del_flag            INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_pay_code_del (code, del_flag),
    INDEX idx_pay_supplier (supplier_id),
    INDEX idx_pay_due_date (due_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-应付单';

-- ============================================================
-- 4. 凭证主表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_voucher (
    id                  VARCHAR(32)  NOT NULL COMMENT '主键',
    voucher_no          VARCHAR(50)  NOT NULL COMMENT '凭证号',
    voucher_date        DATETIME     COMMENT '凭证日期',
    status              VARCHAR(20)  DEFAULT '1' COMMENT '状态(dict:mes_voucher_status)',
    source_type         VARCHAR(20)  DEFAULT '1' COMMENT '来源类型 1手工 2业务',
    source_bill_id      VARCHAR(32)  COMMENT '来源单据ID',
    total_debit         DECIMAL(18,2) COMMENT '借方合计',
    total_credit        DECIMAL(18,2) COMMENT '贷方合计',
    remark              VARCHAR(500) COMMENT '摘要',
    create_by           VARCHAR(50),  create_time DATETIME,
    update_by           VARCHAR(50),  update_time DATETIME,
    del_flag            INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_voucher_no_del (voucher_no, del_flag),
    INDEX idx_voucher_date (voucher_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-凭证';

-- ============================================================
-- 5. 凭证明细
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_voucher_item (
    id                  VARCHAR(32)  NOT NULL COMMENT '主键',
    voucher_id          VARCHAR(32)  NOT NULL COMMENT '凭证ID',
    line_no             INT          COMMENT '行号',
    summary             VARCHAR(200) COMMENT '摘要',
    subject_id          VARCHAR(32)  NOT NULL COMMENT '科目ID',
    debit_amount        DECIMAL(18,2) DEFAULT 0 COMMENT '借方金额',
    credit_amount       DECIMAL(18,2) DEFAULT 0 COMMENT '贷方金额',
    create_by           VARCHAR(50),  create_time DATETIME,
    update_by           VARCHAR(50),  update_time DATETIME,
    PRIMARY KEY (id),
    INDEX idx_vi_voucher_id (voucher_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-凭证明细';

-- ============================================================
-- 二、字典注册
-- ============================================================
-- 科目类别
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '科目类别', 'mes_subject_category', 'MES科目类别字典', 0, 'admin', NOW(), 'admin', NOW(), 0);
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_subject_category');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_subject_category'), '资产', '1', '资产类科目', 1,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_subject_category'), '负债', '2', '负债类科目', 2,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_subject_category'), '权益', '3', '权益类科目', 3,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_subject_category'), '成本', '4', '成本类科目', 4,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_subject_category'), '损益', '5', '损益类科目', 5,1,'admin',NOW(),'admin',NOW());

-- 余额方向
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '余额方向', 'mes_balance_direction', 'MES余额方向字典', 0, 'admin', NOW(), 'admin', NOW(), 0);
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_balance_direction');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_balance_direction'), '借方', '1', '余额在借方', 1,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_balance_direction'), '贷方', '2', '余额在贷方', 2,1,'admin',NOW(),'admin',NOW());

-- 应收状态
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '应收状态', 'mes_receivable_status', 'MES应收状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_receivable_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_receivable_status'), '未结清', '1', '未结清', 1,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_receivable_status'), '部分结清', '2', '部分结清', 2,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_receivable_status'), '已结清', '3', '已结清', 3,1,'admin',NOW(),'admin',NOW());

-- 应付状态
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '应付状态', 'mes_payable_status', 'MES应付状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_payable_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_payable_status'), '未结清', '1', '未结清', 1,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_payable_status'), '部分结清', '2', '部分结清', 2,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_payable_status'), '已结清', '3', '已结清', 3,1,'admin',NOW(),'admin',NOW());

-- 凭证状态
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '凭证状态', 'mes_voucher_status', 'MES凭证状态字典', 0, 'admin', NOW(), 'admin', NOW(), 0);
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'mes_voucher_status');
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time) VALUES
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_voucher_status'), '草稿', '1', '草稿', 1,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_voucher_status'), '已审核', '2', '已审核', 2,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_voucher_status'), '已过账', '3', '已过账', 3,1,'admin',NOW(),'admin',NOW()),
(REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code = 'mes_voucher_status'), '已作废', '0', '已作废', 4,1,'admin',NOW(),'admin',NOW());

-- ============================================================
-- 三、角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id LIKE 'mes_finance%' OR p.id LIKE 'mes:finance:%' OR p.id LIKE 'mes:subject:%' OR p.id LIKE 'mes:receivable:%' OR p.id LIKE 'mes:payable:%' OR p.id LIKE 'mes:voucher:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id LIKE 'mes_finance%' OR p.id LIKE 'mes:finance:%' OR p.id LIKE 'mes:subject:%' OR p.id LIKE 'mes:receivable:%' OR p.id LIKE 'mes:payable:%' OR p.id LIKE 'mes:voucher:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
