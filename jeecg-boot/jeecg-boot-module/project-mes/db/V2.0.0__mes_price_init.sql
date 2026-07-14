-- MES 价格管理模块 V2.0.0
-- CREATE TABLE: c_mes_price
-- 字典: mes_price_type
-- 注意：菜单和权限码由 MesMenuRegistry Java Runner 注册（SQL 文件不写中文菜单名避免编码问题）

-- ============================================================
-- 一、建表
-- ============================================================
CREATE TABLE IF NOT EXISTS c_mes_price (
    id              VARCHAR(32)   NOT NULL COMMENT '主键',
    code            VARCHAR(50)   NOT NULL COMMENT '价格编码',
    material_id     VARCHAR(32)   NOT NULL COMMENT '物料ID',
    customer_id     VARCHAR(32)   COMMENT '客户ID(空=标准售价)',
    price           DECIMAL(18,2) NOT NULL COMMENT '价格',
    type            VARCHAR(20)   DEFAULT '1' COMMENT '价格类型(dict:mes_price_type)',
    begin_date      DATETIME      COMMENT '生效日期',
    end_date        DATETIME      COMMENT '失效日期',
    status          VARCHAR(20)   DEFAULT '1' COMMENT '状态 1启用 0停用',
    remark          VARCHAR(500)  COMMENT '备注',
    create_by       VARCHAR(50)   COMMENT '创建人',
    create_time     DATETIME      COMMENT '创建时间',
    update_by       VARCHAR(50)   COMMENT '更新人',
    update_time     DATETIME      COMMENT '更新时间',
    del_flag        INT           DEFAULT 0 COMMENT '删除标记',
    PRIMARY KEY (id),
    UNIQUE INDEX uk_price_code_del (code, del_flag),
    INDEX idx_price_material (material_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='MES-价格';

-- ============================================================
-- 二、字典注册
-- ============================================================
INSERT IGNORE INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, update_by, update_time, type)
VALUES (REPLACE(UUID(),'-',''), '价格类型', 'mes_price_type', 'MES价格类型字典', 0, 'admin', NOW(), 'admin', NOW(), 0);

INSERT IGNORE INTO sys_dict_item (id, dict_id, item_text, item_value, description, sort_order, status, create_by, create_time, update_by, update_time)
SELECT REPLACE(UUID(),'-',''), d.id, '标准售价', '1', '无客户特殊政策的默认价格', 1, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict d WHERE d.dict_code = 'mes_price_type'
UNION ALL
SELECT REPLACE(UUID(),'-',''), d.id, '客户协议价', '2', '特定客户专属协议价格', 2, 1, 'admin', NOW(), 'admin', NOW()
FROM sys_dict d WHERE d.dict_code = 'mes_price_type';

-- ============================================================
-- 三、角色授权
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE p.id = 'mes_sales_price' OR p.id LIKE 'mes:price:%';

INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), (SELECT id FROM sys_role WHERE role_code='admin'), p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_sales_price' OR p.id LIKE 'mes:price:%')
  AND EXISTS (SELECT 1 FROM sys_role WHERE role_code='admin');
