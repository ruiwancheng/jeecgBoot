-- MES 供应商审计修复 V1.5.0
-- 1. 唯一索引增加 del_flag（参照 c_mes_warehouse 的 uk_mes_wh_code_del 模式）
-- 2. 补充授权 customer 模块权限码到 mes_role_001 和 admin（之前遗漏）

-- ============================================================
-- 一、唯一索引修复：code → (code, del_flag)
-- ============================================================
-- 先删旧索引
ALTER TABLE c_mes_supplier DROP INDEX uk_supplier_code;
-- 重建为 code + del_flag 复合索引
ALTER TABLE c_mes_supplier ADD UNIQUE INDEX uk_supplier_code_del (code, del_flag);

-- ============================================================
-- 二、补充客户权限授权到 mes_role_001（之前遗漏）
-- ============================================================
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', p.id, NOW(), '127.0.0.1'
FROM sys_permission p
WHERE (p.id = 'mes_basic_customer' OR p.id LIKE 'mes:customer:%')
  AND NOT EXISTS (
    SELECT 1 FROM sys_role_permission rp
    WHERE rp.role_id = 'mes_role_001' AND rp.permission_id = p.id
  );
