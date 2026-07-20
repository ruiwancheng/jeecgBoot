# 菜单权限 SQL 模板

> ⚠️ 生成 Flyway SQL 时必须严格按此模板填充变量，禁止凭记忆生成。

## 变量说明

| 变量 | 说明 |
|------|------|
| `{{timestamp}}` | 毫秒时间戳，与 Flyway 版本检查时并行获取的值相同 |
| `{{description}}` | 功能描述，如"课程管理" |
| `{{entityPackagePath}}` | 包路径斜线形式，如 `biz/course` |
| `{{entityName_uncap}}` | 实体名首字母小写，如 `bizCourse` |
| `{{viewDir}}` | 前端视图目录，如 `biz/course` |
| `{{entityName}}` | 实体名，如 `BizCourse` |
| `{{entityPackage}}` | 包前缀，如 `biz` |
| `{{tableName}}` | 表名，如 `biz_course` |
| `{{today}}` | 当天日期，如 `2026-04-29` |

## SQL 模板

```sql
-- 注意：该页面对应的前台目录为 views/{{viewDir}} 文件夹下
-- 如果你想更改到其他目录，请修改sql中component字段对应的值

-- 主菜单
-- ⚠️ is_leaf 必须为 0（第15个值）：有按钮子级时 is_leaf=1 会导致按钮在权限树中不可见
INSERT INTO sys_permission(id, parent_id, name, url, component, component_name, redirect, menu_type, perms, perms_type, sort_no, always_show, icon, is_route, is_leaf, keep_alive, hidden, hide_tab, description, status, del_flag, rule_flag, create_by, create_time, update_by, update_time, internal_or_external)
VALUES ('{{timestamp}}01', NULL, '{{description}}', '/{{entityPackagePath}}/{{entityName_uncap}}List', '{{viewDir}}/{{entityName}}List', NULL, NULL, 0, NULL, '1', 0.00, 0, NULL, 1, 0, 0, 0, 0, NULL, '1', 0, 0, 'admin', '{{today}} 00:00:00', NULL, NULL, 0);

-- 新增
INSERT INTO sys_permission(id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, description, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES ('{{timestamp}}02', '{{timestamp}}01', '添加{{description}}', NULL, NULL, 0, NULL, NULL, 2, '{{entityPackage}}:{{tableName}}:add', '1', NULL, 0, NULL, 1, 0, 0, 0, NULL, 'admin', '{{today}} 00:00:00', NULL, NULL, 0, 0, '1', 0);

-- 编辑
INSERT INTO sys_permission(id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, description, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES ('{{timestamp}}03', '{{timestamp}}01', '编辑{{description}}', NULL, NULL, 0, NULL, NULL, 2, '{{entityPackage}}:{{tableName}}:edit', '1', NULL, 0, NULL, 1, 0, 0, 0, NULL, 'admin', '{{today}} 00:00:00', NULL, NULL, 0, 0, '1', 0);

-- 删除
INSERT INTO sys_permission(id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, description, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES ('{{timestamp}}04', '{{timestamp}}01', '删除{{description}}', NULL, NULL, 0, NULL, NULL, 2, '{{entityPackage}}:{{tableName}}:delete', '1', NULL, 0, NULL, 1, 0, 0, 0, NULL, 'admin', '{{today}} 00:00:00', NULL, NULL, 0, 0, '1', 0);

-- 批量删除
INSERT INTO sys_permission(id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, description, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES ('{{timestamp}}05', '{{timestamp}}01', '批量删除{{description}}', NULL, NULL, 0, NULL, NULL, 2, '{{entityPackage}}:{{tableName}}:deleteBatch', '1', NULL, 0, NULL, 1, 0, 0, 0, NULL, 'admin', '{{today}} 00:00:00', NULL, NULL, 0, 0, '1', 0);

-- 导出excel
INSERT INTO sys_permission(id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, description, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES ('{{timestamp}}06', '{{timestamp}}01', '导出excel_{{description}}', NULL, NULL, 0, NULL, NULL, 2, '{{entityPackage}}:{{tableName}}:exportXls', '1', NULL, 0, NULL, 1, 0, 0, 0, NULL, 'admin', '{{today}} 00:00:00', NULL, NULL, 0, 0, '1', 0);

-- 导入excel
INSERT INTO sys_permission(id, parent_id, name, url, component, is_route, component_name, redirect, menu_type, perms, perms_type, sort_no, always_show, icon, is_leaf, keep_alive, hidden, hide_tab, description, create_by, create_time, update_by, update_time, del_flag, rule_flag, status, internal_or_external)
VALUES ('{{timestamp}}07', '{{timestamp}}01', '导入excel_{{description}}', NULL, NULL, 0, NULL, NULL, 2, '{{entityPackage}}:{{tableName}}:importExcel', '1', NULL, 0, NULL, 1, 0, 0, 0, NULL, 'admin', '{{today}} 00:00:00', NULL, NULL, 0, 0, '1', 0);

-- 角色授权（admin角色）
INSERT INTO sys_role_permission (id, role_id, permission_id, data_rule_ids, operate_date, operate_ip) VALUES ('{{timestamp}}08', 'f6817f48af4fb3af11b9e8bf182f618b', '{{timestamp}}01', NULL, '{{today}} 00:00:00', '127.0.0.1');
INSERT INTO sys_role_permission (id, role_id, permission_id, data_rule_ids, operate_date, operate_ip) VALUES ('{{timestamp}}09', 'f6817f48af4fb3af11b9e8bf182f618b', '{{timestamp}}02', NULL, '{{today}} 00:00:00', '127.0.0.1');
INSERT INTO sys_role_permission (id, role_id, permission_id, data_rule_ids, operate_date, operate_ip) VALUES ('{{timestamp}}10', 'f6817f48af4fb3af11b9e8bf182f618b', '{{timestamp}}03', NULL, '{{today}} 00:00:00', '127.0.0.1');
INSERT INTO sys_role_permission (id, role_id, permission_id, data_rule_ids, operate_date, operate_ip) VALUES ('{{timestamp}}11', 'f6817f48af4fb3af11b9e8bf182f618b', '{{timestamp}}04', NULL, '{{today}} 00:00:00', '127.0.0.1');
INSERT INTO sys_role_permission (id, role_id, permission_id, data_rule_ids, operate_date, operate_ip) VALUES ('{{timestamp}}12', 'f6817f48af4fb3af11b9e8bf182f618b', '{{timestamp}}05', NULL, '{{today}} 00:00:00', '127.0.0.1');
INSERT INTO sys_role_permission (id, role_id, permission_id, data_rule_ids, operate_date, operate_ip) VALUES ('{{timestamp}}13', 'f6817f48af4fb3af11b9e8bf182f618b', '{{timestamp}}06', NULL, '{{today}} 00:00:00', '127.0.0.1');
INSERT INTO sys_role_permission (id, role_id, permission_id, data_rule_ids, operate_date, operate_ip) VALUES ('{{timestamp}}14', 'f6817f48af4fb3af11b9e8bf182f618b', '{{timestamp}}07', NULL, '{{today}} 00:00:00', '127.0.0.1');
```
