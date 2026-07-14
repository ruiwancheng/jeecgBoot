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
- **软删除 + 唯一索引："借尸还魂"模式** — `save()` 先查活跃记录(正常MP)，再查软删除记录（用 Mapper `@Select` 注解原生 SQL 绕过 `@TableLogic` 拦截器），找到则复用旧ID/创建人/创建时间，用 Mapper `@Update` 注解原生 UPDATE 将 `del_flag` 归零并覆盖业务字段，同时设 `updateBy`/`updateTime` 保留审计链。避免唯一索引冲突+保留历史关联
- **禁止 Service 内部 `this.xxx()` 自调用** — Spring AOP 基于代理，`this` 指向原始对象，绕过事务拦截器。需要调用同类 `@Transactional` 方法时用 `super.xxx()`（调基类）或注入自身代理 Bean。典型反模式：`for (id : ids) this.removeById(id)` → 改为 `super.removeByIds(ids)`
- **脱敏操作禁止直接修改实体引用** — Controller 对 MyBatis-Plus 分页结果做脱敏时，`page.getRecords()` 返回的是数据库实体的原引用。直接 `setXxx("****")` 会通过前端编辑回写覆盖数据库真实值。必须提供独立的 `queryById` 接口返回完整数据供编辑使用；或在脱敏前创建副本
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
| `DEFAULT '中文文本'` | 字典字段存入的是 `item_value`（编码），不是 `item_text`（显示文本） | `DEFAULT '1'` 用编码值 |

### 幂等要求

SQL 脚本可能被多次执行（部署控制台自动扫描 `sql/` 和 `db/` 目录）。所有 DDL 必须可重复运行不报错。

### 关键数据初始化

权限码注册、角色绑定等关键数据用**独立 `INSERT IGNORE` 语句**，每条幂等可单独重跑。不用 `INSERT ... SELECT ... WHERE LIKE` 模式，避免部分失败无法定位。
权限注册必须同时设 `id` 和 `perms`：`INSERT INTO sys_permission (id, perms, ...) VALUES ('mes:xx:add', 'mes:xx:add', ...)`。
- **禁止用 `sys/permission/add` API 创建菜单** — 该 API 会静默丢弃 `parentId`/`isRoute`/`isLeaf` 等关键字段，返回成功但字段为 NULL/default。菜单注册只走 Java Runner（`MesMenuRegistry`）或 SQL INSERT。
- **SQL 文件禁止含中文菜单名** — 部署链路（Windows→git→服务器→MySQL）中中文编码不可靠。菜单和权限码的注册全部交给 Java Runner（`MesMenuRegistry`），SQL 只做建表、字典和 `sys_role_permission` 角色绑定。

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
