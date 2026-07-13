---
name: code-style
description: 代码规范——命名、格式、修改标记
glob: "**/*.{java,vue,ts}"
version: 1.0
---

# 代码规范

## Java
- 实体：`Sys` 前缀系统表，`@TableId(type = IdType.ASSIGN_ID)`
- Controller：继承 `JeecgController<Entity, IService>`
- Service：`I{Entity}Service` / `{Entity}ServiceImpl`
- Mapper：`{Entity}Mapper extends BaseMapper<Entity>`
- 所有修改加 `update-begin`/`update-end` 标记
- **软删除 + 唯一索引："借尸还魂"模式** — `save()` 先查活跃记录(正常MP)，再查软删除记录（**用 JdbcTemplate 原生 SQL 绕过 `@TableLogic` 拦截器**，`@Select` 注解不可靠，拦截器会追加 `del_flag=0` 导致查不到），找到则复用旧ID/创建人/创建时间，用 JdbcTemplate 原生 UPDATE 将 `del_flag` 归零并覆盖业务字段，同时设 `updateBy`/`updateTime` 保留审计链。避免唯一索引冲突+保留历史关联
- **权限注册必须同时设 `id` 和 `perms`** — Shiro `@RequiresPermissions` 匹配的是 `sys_permission.perms` 列，不是 `id` 列。只设 `id` 不设 `perms` 会导致权限码形同虚设。`permission(id, parentId, name)` 工厂方法自动 `setPerms(id)`，Runner 注册时同步写入 `setPerms(def.getPerms())`

## SQL 迁移脚本规范

### 目标环境

MySQL 5.7（Docker 容器 `jeecg-boot-mysql`）。

### 禁止语法

| 禁止 | 原因 | 替代 |
|------|------|------|
| `DROP INDEX IF EXISTS` | MySQL 5.7 不支持 | 直接 `DROP INDEX` |
| `ADD COLUMN IF NOT EXISTS` | MySQL 5.7 不支持 | 存储过程先判断 |
| 假设标品表结构 | 不同版本表结构不同 | 先 `DESCRIBE` 确认 |
| 假设 `del_flag` 存在 | `sys_dict_item` 等无此字段 | 查实际结构 |

### 幂等要求

SQL 脚本可能被多次执行（部署控制台自动扫描 `sql/` 和 `db/` 目录）。所有 DDL 必须可重复运行不报错。

### 关键数据初始化

权限码注册、角色绑定等关键数据用**独立 `INSERT IGNORE` 语句**，每条幂等可单独重跑。不用 `INSERT ... SELECT ... WHERE LIKE` 模式，避免部分失败无法定位。
权限注册必须同时设 `id` 和 `perms`：`INSERT INTO sys_permission (id, perms, ...) VALUES ('mes:xx:add', 'mes:xx:add', ...)`。

## Vue/TypeScript
- 页面：`index.vue` + `{name}.api.ts` + `{name}.data.ts`
- 组件名：`<script setup name="kebab-case">`
- 别名：`/@/` → `src/`
- 接口请求：`defHttp`（来自 `/@/utils/http/axios`）
- 禁止 `any`，用 `unknown` 替代

## 构建
- 新 Maven 模块需注册三处：boot-module/pom.xml(module) + system-start/pom.xml(dependency) + **`mvn install`（必须 install，不能只 compile）**
- `mvn compile` 产物在 target/ 但不在本地仓库，`spring-boot:run` 解析依赖时找不到 → API 返回 404
- 修改已有模块的代码可以用 compile，但新增模块/新增依赖后必须 install

## 通用
- 函数不超过 50 行，嵌套不超过 3 层
- 不加无业务理由的依赖
