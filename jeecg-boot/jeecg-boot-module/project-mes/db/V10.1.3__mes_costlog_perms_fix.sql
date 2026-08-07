-- ============================================================
-- MES 成本日志权限修复 V10.1.3
-- 背景：B1 · purchase-mesCostLog 权限码注册（P0 24h hotfix）
-- 症状：GET /mes/purchase/mesCostLog/list 返回 500
--       "Subject does not have permission [mes:purchase:costLog:list]"
-- 根因：
--   1. sys_permission 中已有 costLog 权限记录（id=mes_cost_log, perms=mes:purchase:costLog:list）
--      但 parent_id 误写为 'mes_purchase_purchase'（不存在）→ 菜单挂载异常
--   2. sys_role_permission 中 costLog 没绑定到 mes_role_001 → Shiro 拦截兜底 500
-- 修复：
--   1. 修正 parent_id 为 'mes_purchase'（采购管理目录）
--   2. 绑定 mes:purchase:costLog:list 到 mes_role_001 + admin 角色
-- 可重复执行（INSERT IGNORE / UPDATE）
-- ============================================================

-- 1. 修正 parent_id
UPDATE sys_permission
SET parent_id = 'mes_purchase'
WHERE id = 'mes_cost_log' AND parent_id <> 'mes_purchase';

-- 2. 兜底：若权限记录不存在则插入（防御性，正常情况不会触发）
INSERT IGNORE INTO sys_permission (id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES ('mes_cost_log', 'mes_purchase', '成本变动日志', '/mes/costLog', 'project/mes/purchase/ledger/CostLog', 0, 'project-mes-cost-log', NULL, 0, 'mes:purchase:costLog:list', '1', 15.00, 0, NULL, 1, 0, 0, 0, 'admin', NOW(), 'admin', NOW(), 0, 0, 1, NULL);

-- 3. 绑定到 MES 项目管理员角色
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), 'mes_role_001', 'mes_cost_log', NOW(), '127.0.0.1'
WHERE EXISTS (SELECT 1 FROM sys_permission WHERE id = 'mes_cost_log');

-- 4. 绑定到 admin 角色
INSERT IGNORE INTO sys_role_permission (id, role_id, permission_id, operate_date, operate_ip)
SELECT REPLACE(UUID(),'-',''), r.id, 'mes_cost_log', NOW(), '127.0.0.1'
FROM sys_role r
WHERE r.role_code = 'admin' AND EXISTS (SELECT 1 FROM sys_permission WHERE id = 'mes_cost_log');
