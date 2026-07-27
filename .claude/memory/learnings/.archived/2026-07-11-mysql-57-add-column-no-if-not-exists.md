# MySQL 5.7 不支持 ADD COLUMN IF NOT EXISTS

**触发条件：** 编写 SQL 迁移脚本时使用了 `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`

**现象：** SQL 执行返回成功但列未添加，MyBatis-Plus 运行时抛出 `Unknown column` 错误

**处理方式：**
- 使用 `ADD COLUMN` 去掉 `IF NOT EXISTS`（MySQL 8.0 才支持）
- Docker 部署重建容器后表结构丢失，SQL 迁移需重新执行
- 建议 SQL 文件放在项目 `db/` 目录，随代码版本管理

**关联经验：** Docker 部署后 SQL 需重新执行

**日期：** 2026-07-11
