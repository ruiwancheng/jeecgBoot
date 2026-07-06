---
name: new-project-sql-gap
description: new-project 技能只生成 SQL 文件不执行，需额外步骤写入数据库
metadata:
  type: feedback
---

# new-project 流程缺口：SQL 只写文件不执行

## 问题

`/new-project` 命令按 skill 流程执行完毕后，SQL 初始化脚本（`init-role-user.sql`）只生成为文件，不会自动执行到数据库中。用户反馈"用户没创建成功"，因为数据库里确实没有记录。

## 根因

skill 流程中「步骤五：数据库初始化」只描述了创建 SQL 文件，但没有数据库执行步骤。用户期望的是项目创建完成后就能用新账号登录。

## 临时处理

在 `/new-project` 执行完毕后，如果 MySQL 可用（Docker 或本地），应主动将 SQL 执行到数据库中。

**Why:** 业务人员认为"创建项目"= 可用的完整项目。只生成文件不符合预期，靠后续 `/setup` 弥补增加了操作步骤。

**How to apply:** 执行 `/new-project` 时，在生成 SQL 文件后检测数据库可用性，如果可连接则自动执行 SQL。
