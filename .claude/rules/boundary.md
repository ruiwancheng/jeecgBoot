---
name: boundary
description: 操作边界——文件写入+数据库操作+平台保护，合并自 file-scope + data-scope（2026-07-28 token 降本）
glob: "**/*"
version: 3.0
---

# 操作边界

## 文件系统

### 可以写入

#### 项目文件（自由读写）
- `jeecg-boot/jeecg-boot-module/project-{当前项目}/`
- `jeecgboot-vue3/src/views/project/{当前项目}/`

#### 公共注册点（只能新增，不改已有）
- `jeecgboot-vue3/src/router/routes/modules/` — 新增路由文件
- Maven pom.xml — 新增 `<module>` 和 `<dependency>`

### 禁止写入
- `jeecg-boot/jeecg-boot-base-core/` — 平台核心框架
- `jeecg-boot/jeecg-module-system/jeecg-system-biz/` — 系统业务逻辑
- `jeecg-boot/jeecg-module-system/jeecg-system-api/` — 系统 API 接口
- `jeecg-boot/jeecg-module-system/jeecg-system-start/src/` — 系统启动器
- `jeecgboot-vue3/src/views/system/` — 系统管理前端
- `jeecgboot-vue3/src/components/` — 公共组件
- `.claude/` — Harness 工程文件
- 其他项目目录（`project-xxx/`）

> `system-start/pom.xml` 不在保护范围——新模块的 Maven 依赖注册是正常操作。
> 工程产物放 `harness/` 和 `hermes/`，管理员模式 `/admin` 解除限制。

## 数据库

### 可以做的（当前项目）
- `CREATE TABLE c_{项目名}_*` — 项目表
- `INSERT sys_permission` — id 用项目前缀
- `INSERT sys_role_permission` — 绑到项目角色
- 读写项目自己的业务数据

### 不能做的
- `UPDATE/DELETE` 非当前项目的菜单和权限
- 改 `sys_role`、`sys_user`、`sys_depart` 等系统核心表
- `DROP TABLE` 任何表
- 改标品表结构
- SQL 必须参数化
