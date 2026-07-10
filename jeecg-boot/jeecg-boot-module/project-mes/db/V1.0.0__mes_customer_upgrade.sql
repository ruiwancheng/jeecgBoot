-- MES 客户模块升级 V1.0.0
-- ALTER TABLE: c_mes_customer 新增 12 字段
-- CREATE TABLE: 4 个子表（联系人、地址、跟进记录、价格表）

ALTER TABLE c_mes_customer
    ADD COLUMN grade             VARCHAR(32)   COMMENT '客户等级(dict:mes_customer_grade)',
    ADD COLUMN credit_limit      DECIMAL(18,2) COMMENT '信用额度',
    ADD COLUMN salesman_id       VARCHAR(36)   COMMENT '所属业务员(sys_user.id)',
    ADD COLUMN industry          VARCHAR(32)   COMMENT '行业(dict:mes_customer_industry)',
    ADD COLUMN region            VARCHAR(32)   COMMENT '区域(dict:mes_customer_region)',
    ADD COLUMN scale             VARCHAR(32)   COMMENT '企业规模(dict:mes_customer_scale)',
    ADD COLUMN invoice_title     VARCHAR(200)  COMMENT '发票抬头',
    ADD COLUMN tax_no            VARCHAR(50)   COMMENT '税号',
    ADD COLUMN bank_name         VARCHAR(100)  COMMENT '开户银行',
    ADD COLUMN bank_account      VARCHAR(50)   COMMENT '银行账号',
    ADD COLUMN invoice_address   VARCHAR(300)  COMMENT '开票地址',
    ADD COLUMN invoice_phone     VARCHAR(30)   COMMENT '开票电话',
    ADD COLUMN invoice_type      VARCHAR(10)   COMMENT '发票类型(dict:invoice_type)';

-- 联系人子表
CREATE TABLE IF NOT EXISTS c_mes_customer_contact (
    id          VARCHAR(36)  NOT NULL COMMENT '主键',
    customer_id VARCHAR(36)  NOT NULL COMMENT '客户ID',
    name        VARCHAR(50)  COMMENT '姓名',
    title       VARCHAR(50)  COMMENT '职务',
    phone       VARCHAR(20)  COMMENT '手机',
    email       VARCHAR(100) COMMENT '邮箱',
    social      VARCHAR(100) COMMENT 'QQ/微信',
    is_default  TINYINT(1)   DEFAULT 0 COMMENT '是否默认',
    remark      VARCHAR(200) COMMENT '备注',
    create_by   VARCHAR(50)  COMMENT '创建人',
    create_time DATETIME     COMMENT '创建时间',
    update_by   VARCHAR(50)  COMMENT '更新人',
    update_time DATETIME     COMMENT '更新时间',
    del_flag    INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_contact_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户联系人';

-- 地址子表
CREATE TABLE IF NOT EXISTS c_mes_customer_address (
    id           VARCHAR(36)  NOT NULL COMMENT '主键',
    customer_id  VARCHAR(36)  NOT NULL COMMENT '客户ID',
    address_type VARCHAR(20)  COMMENT '地址类型(dict:address_type)',
    contact      VARCHAR(50)  COMMENT '联系人',
    phone        VARCHAR(20)  COMMENT '联系电话',
    province     VARCHAR(50)  COMMENT '省',
    city         VARCHAR(50)  COMMENT '市',
    district     VARCHAR(50)  COMMENT '区',
    detail       VARCHAR(300) COMMENT '详细地址',
    is_default   TINYINT(1)   DEFAULT 0 COMMENT '是否默认',
    remark       VARCHAR(200) COMMENT '备注',
    create_by    VARCHAR(50)  COMMENT '创建人',
    create_time  DATETIME     COMMENT '创建时间',
    update_by    VARCHAR(50)  COMMENT '更新人',
    update_time  DATETIME     COMMENT '更新时间',
    del_flag     INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_address_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户地址';

-- 跟进记录子表
CREATE TABLE IF NOT EXISTS c_mes_customer_follow_up (
    id          VARCHAR(36)  NOT NULL COMMENT '主键',
    customer_id VARCHAR(36)  NOT NULL COMMENT '客户ID',
    follow_type VARCHAR(20)  COMMENT '跟进方式(dict:follow_type)',
    follow_date DATETIME     COMMENT '跟进日期',
    content     TEXT         COMMENT '跟进内容',
    follower    VARCHAR(36)  COMMENT '跟进人(sys_user.id)',
    next_date   DATETIME     COMMENT '下次跟进日期',
    attachment  VARCHAR(500) COMMENT '附件路径',
    remark      VARCHAR(200) COMMENT '备注',
    create_by   VARCHAR(50)  COMMENT '创建人',
    create_time DATETIME     COMMENT '创建时间',
    update_by   VARCHAR(50)  COMMENT '更新人',
    update_time DATETIME     COMMENT '更新时间',
    del_flag    INT          DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_followup_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户跟进记录';

-- 价格表
CREATE TABLE IF NOT EXISTS c_mes_customer_price (
    id          VARCHAR(36)   NOT NULL COMMENT '主键',
    customer_id VARCHAR(36)   NOT NULL COMMENT '客户ID',
    product_id  VARCHAR(36)   COMMENT '产品ID',
    price       DECIMAL(18,2) COMMENT '协议单价',
    begin_date  DATETIME      COMMENT '生效日期（预留）',
    end_date    DATETIME      COMMENT '失效日期（预留）',
    min_qty     DECIMAL(18,2) COMMENT '起订数量（预留）',
    max_qty     DECIMAL(18,2) COMMENT '截止数量（预留）',
    remark      VARCHAR(200)  COMMENT '备注',
    create_by   VARCHAR(50)   COMMENT '创建人',
    create_time DATETIME      COMMENT '创建时间',
    update_by   VARCHAR(50)   COMMENT '更新人',
    update_time DATETIME      COMMENT '更新时间',
    del_flag    INT           DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    INDEX idx_price_customer_id (customer_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-客户价格表';
