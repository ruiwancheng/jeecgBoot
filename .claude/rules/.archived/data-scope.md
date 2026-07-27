---
name: data-scope
description: 数据库操作边界——可新增自己项目的配置，不能改平台核心数据
glob: "**/*.sql,**/*.java"
version: 2.0
---

# 数据库操作边界

## 可以做的（当前项目）
- `CREATE TABLE c_{项目名}_*` — 项目表
- `INSERT sys_permission` — id 用项目前缀
- `INSERT sys_role_permission` — 绑到项目角色
- 读写项目自己的业务数据

## 不能做的
- `UPDATE/DELETE` 非当前项目的菜单和权限
- 改 `sys_role`、`sys_user`、`sys_depart` 等系统核心表
- `DROP TABLE` 任何表
- 改标品表结构
- SQL 必须参数化
