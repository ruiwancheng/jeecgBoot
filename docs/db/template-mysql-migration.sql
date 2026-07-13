-- JeecgBoot MySQL 5.7 幂等迁移脚本模板
-- 目标: MySQL 5.7 (Docker jeecg-boot-mysql)
-- 此脚本被部署控制台自动执行，必须可重复运行不报错
-- 用法: 复制模板，替换表名/字段名/索引名

-- =======================================
-- 1. 新增列（先判断再执行）
-- =======================================
SET @sql = IF(
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
   WHERE TABLE_SCHEMA='jeecg-boot' AND TABLE_NAME='c_mes_xxx' AND COLUMN_NAME='new_col')=0,
  'ALTER TABLE c_mes_xxx ADD COLUMN new_col VARCHAR(50) COMMENT ''字段说明''',
  'SELECT ''SKIP: 已存在'' AS msg'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- =======================================
-- 2. 新建表
-- =======================================
CREATE TABLE IF NOT EXISTS c_mes_xxx (
    id VARCHAR(36) NOT NULL, code VARCHAR(50) NOT NULL, name VARCHAR(100),
    del_flag INT DEFAULT 0, create_by VARCHAR(50), create_time DATETIME,
    update_by VARCHAR(50), update_time DATETIME,
    PRIMARY KEY (id),
    UNIQUE INDEX uk_xxx_code_del (code, del_flag)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =======================================
-- 3. 重建唯一索引（含 del_flag）
-- =======================================
ALTER TABLE c_mes_xxx DROP INDEX old_name;
ALTER TABLE c_mes_xxx ADD UNIQUE INDEX uk_xxx_new (code, del_flag);

-- =======================================
-- 4. 字典数据（INSERT IGNORE，无 del_flag！）
-- =======================================
INSERT IGNORE INTO sys_dict_item
  (id,dict_id,item_text,item_value,description,sort_order,status,create_by,create_time,update_by,update_time)
VALUES
  (REPLACE(UUID(),'-',''), (SELECT id FROM sys_dict WHERE dict_code='mes_xxx'), '显示', '值', '说明', 1,1,'admin',NOW(),'admin',NOW());

-- =======================================
-- MySQL 5.7 禁止语法
-- =======================================
-- ❌ DROP INDEX IF EXISTS      → ✅ DROP INDEX
-- ❌ ADD COLUMN IF NOT EXISTS  → ✅ 存储过程
-- ❌ sys_dict_item.del_flag    → 不存在，别加
