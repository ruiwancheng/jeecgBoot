---
date: 2026-07-14
category: 部署
tags: [SQL迁移, Flyway替代, 部署流程, 幂等, MySQL 5.7]
---

# SQL 迁移脚本不能依赖部署流程自动执行

## 触发条件
创建了 V1.3.0、V1.3.1 两个 SQL 迁移文件放在 `db/` 目录，部署后 SQL 未执行或仅部分执行，导致权限码注册、角色绑定等关键数据初始化失败。

## 根因
1. 部署流程的 SQL 执行基于文件校验码去重，部分执行失败后不再重试
2. MySQL 5.7 不支持 `DROP INDEX IF EXISTS` 等语法，语法错误导致剩余语句被跳过
3. `INSERT IGNORE INTO ... SELECT ... WHERE ... LIKE ...` 这类复杂语句在部分环境中执行不稳定

## 正确做法
1. **关键数据初始化用独立 `INSERT IGNORE`**，每条语句独立、幂等、可单独重跑
2. **SQL 必须 MySQL 5.7 兼容**：禁止 `IF EXISTS`/`IF NOT EXISTS`（DDL 列操作），禁止假设 `sys_dict_item` 有 `del_flag`
3. **权限注册同时设 `id` 和 `perms`**：`INSERT INTO sys_permission (id, perms, ...) VALUES (...)` 两列同值
4. **角色绑定用显式 IN 列表**而非 `LIKE` 匹配：
   ```sql
   -- ✅ 可靠
   INSERT IGNORE INTO sys_role_permission (...) 
   SELECT ... FROM sys_permission WHERE id IN ('mes:warehouse:add', 'mes:warehouse:edit', ...);
   
   -- ❌ 不可靠
   INSERT IGNORE INTO sys_role_permission (...) 
   SELECT ... FROM sys_permission WHERE id LIKE 'mes:warehouse:%';
   ```
5. **提供直接可执行的 SQL** 给服务端管理员备用，不依赖部署流程
