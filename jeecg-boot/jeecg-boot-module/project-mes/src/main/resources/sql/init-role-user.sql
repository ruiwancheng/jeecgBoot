-- ====================================================================
-- MES 项目初始化 SQL
-- 创建项目角色、管理员用户和角色绑定
-- ====================================================================

-- 1. 创建 MES 项目角色
INSERT INTO sys_role (id, role_name, role_code, description, create_by, create_time, update_by, update_time)
VALUES ('mes_role_001', 'MES管理员', 'mes_admin', 'MES项目管理员角色', 'admin', NOW(), 'admin', NOW());

-- 2. 创建 MES 管理员用户（默认密码: 123456）
-- 密码加密方式: PasswordUtil.encrypt(username, password, salt)
-- 即 PBEWithMD5AndDES 算法，迭代1000次
INSERT INTO sys_user (id, username, realname, password, salt, status, del_flag, create_by, create_time, update_by, update_time)
VALUES ('mes_user_001', 'mes_admin', 'MES管理员', '17eb546346c060105117e1314cd12859', 'MES13157', '1', '0', 'admin', NOW(), 'admin', NOW());

-- 3. 绑定用户角色
INSERT INTO sys_user_role (id, user_id, role_id)
VALUES ('mes_ur_001', 'mes_user_001', 'mes_role_001');
