-- MES 编码规则模块
-- 支持前缀+日期+流水号自动编码，普适于所有需要自动编码的页面

CREATE TABLE IF NOT EXISTS c_mes_code_rule (
    id              VARCHAR(32)   NOT NULL COMMENT '主键',
    rule_code       VARCHAR(30)   NOT NULL COMMENT '规则编码(唯一,如SO/PO/MO)',
    rule_name       VARCHAR(50)   NOT NULL COMMENT '规则名称',
    prefix          VARCHAR(20)   NOT NULL COMMENT '前缀',
    date_format     VARCHAR(20)   DEFAULT 'yyyyMMdd' COMMENT '日期格式(java SimpleDateFormat)',
    seq_length      INT           DEFAULT 4    COMMENT '流水号位数',
    reset_cycle     VARCHAR(10)   DEFAULT 'DAILY' COMMENT '重置周期: NONE/DAILY/MONTHLY/YEARLY',
    current_seq     INT           DEFAULT 0    COMMENT '当前流水号',
    current_date    VARCHAR(10)   DEFAULT NULL COMMENT '当前日期(用于判断重置)',
    remark          VARCHAR(200)  DEFAULT NULL COMMENT '备注',
    create_by       VARCHAR(50)   DEFAULT NULL COMMENT '创建人',
    create_time     DATETIME      DEFAULT NULL COMMENT '创建时间',
    update_by       VARCHAR(50)   DEFAULT NULL COMMENT '更新人',
    update_time     DATETIME      DEFAULT NULL COMMENT '更新时间',
    del_flag        INT           DEFAULT 0    COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_code_rule_code (rule_code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES编码规则';

-- 初始化销售订单编码规则
DELETE FROM c_mes_code_rule WHERE rule_code = 'SO';
INSERT INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, current_date, create_by, create_time, update_by, update_time, del_flag)
VALUES (REPLACE(UUID(),'-',''), 'SO', '销售订单编码', 'SO', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'admin', NOW(), 'admin', NOW(), 0);

-- 初始化采购订单编码规则
DELETE FROM c_mes_code_rule WHERE rule_code = 'PO';
INSERT INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, current_date, create_by, create_time, update_by, update_time, del_flag)
VALUES (REPLACE(UUID(),'-',''), 'PO', '采购订单编码', 'PO', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'admin', NOW(), 'admin', NOW(), 0);

-- 初始化生产订单编码规则
DELETE FROM c_mes_code_rule WHERE rule_code = 'MO';
INSERT INTO c_mes_code_rule (id, rule_code, rule_name, prefix, date_format, seq_length, reset_cycle, current_seq, current_date, create_by, create_time, update_by, update_time, del_flag)
VALUES (REPLACE(UUID(),'-',''), 'MO', '生产订单编码', 'MO', 'yyyyMMdd', 4, 'DAILY', 0, NULL, 'admin', NOW(), 'admin', NOW(), 0);
