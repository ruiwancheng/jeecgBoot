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
- **禁止同一 Controller 内两个方法映射同一 URL** — 方法名/参数不同但 `@GetMapping` 路径相同时，Spring 启动抛 `Ambiguous mapping` 异常导致整个后端无法启动。编译通过不代表运行时正常——`mvn compile` 无法检测此冲突，只有启动后才能发现。不同用途的方法必须使用不同 URL 路径（如 `/selectPage` vs `/selectDropdown`）（来源：2026-07-22 MesCustomerController 部署事故）

## SQL 迁移脚本规范

### 目标环境

MySQL 5.7（Docker 容器 `jeecg-boot-mysql`）。

### DDL 文件存放路径（强制） ← 2026-07-21 编码规则踩坑

**所有建表/改表 SQL 必须放在 `project-mes/db/` 目录：**

```
jeecg-boot/jeecg-boot-module/project-mes/db/V{版本号}__{描述}.sql
```

**原因：** 
- 部署控制台扫描 `jeecg-boot-module/*/(sql|db)/*.sql` 自动执行
- Flyway 路径 (`flyway/sql/mysql/`) 不会被部署控制台扫描
- `db/` 目录是唯一的 SQL 自动执行路径

**禁止：** 使用 MySQL 保留字作为列名（如 `current_date`、`order`、`status` 等），如必须使用则加反引号包裹并在 Entity 加 `@TableField("`列名`")`。
**注意：** INSERT 语句的列清单中保留字同样要加反引号：`INSERT INTO t (id, ..., `current_date`, ...) VALUES ...`，否则部署时 ERROR 1064 静默失败，种子数据从未落库（来源：2026-07-21 编码规则部署事故）。
**正确：** SQL 放 `db/`，列名避免保留字或加反引号。

### 禁止语法

| 禁止 | 原因 | 替代 |
|------|------|------|
| `DROP INDEX IF EXISTS` | MySQL 5.7 不支持 | 直接 `DROP INDEX` |
| `ADD COLUMN IF NOT EXISTS` | MySQL 5.7 不支持 | 存储过程先判断 |
| 假设标品表结构 | 不同版本表结构不同 | 先 `DESCRIBE` 确认 |
| 假设 `del_flag` 存在 | `sys_dict_item` 等无此字段，INSERT 时不要加 `del_flag` 列 | 先 `DESCRIBE` 确认 |
| `DEFAULT '中文文本'` | 字典字段存入的是 `item_value`（编码），不是 `item_text`（显示文本） | `DEFAULT '1'` 用编码值 |

### 幂等要求

SQL 脚本可能被多次执行（部署控制台自动扫描 `sql/` 和 `db/` 目录）。所有 DDL 必须可重复运行不报错。

**种子数据禁止 DELETE+INSERT** — 重跑会重置流水号等运行数据（来源：2026-07-21 编码规则 PO 流水被重置）。必须用 `INSERT IGNORE` + 固定 id（如 `mes_code_rule_SO`），已存在则跳过，运行数据自持。

**字典项禁止用 `INSERT IGNORE + SELECT + UUID()`** — `sys_dict_item` 无唯一约束，UUID 每次不同，`INSERT IGNORE` 不会跳过，导致每次部署追加重复。必须用 `DELETE + INSERT VALUES` 保证幂等：

### 关键数据初始化

权限码注册、角色绑定等关键数据用**独立 `INSERT IGNORE` 语句**，每条幂等可单独重跑。不用 `INSERT ... SELECT ... WHERE LIKE` 模式，避免部分失败无法定位。
权限注册必须同时设 `id` 和 `perms`：`INSERT INTO sys_permission (id, perms, ...) VALUES ('mes:xx:add', 'mes:xx:add', ...)`。
- **禁止用 `sys/permission/add` API 创建菜单** — 该 API 会静默丢弃 `parentId`/`isRoute`/`isLeaf` 等关键字段，返回成功但字段为 NULL/default。菜单注册只走 Java Runner（`MesMenuRegistry`）或 SQL INSERT。
- **SQL 文件禁止含中文菜单名** — 部署链路（Windows→git→服务器→MySQL）中中文编码不可靠。菜单和权限码的注册全部交给 Java Runner（`MesMenuRegistry`），SQL 只做建表、字典和 `sys_role_permission` 角色绑定。

## 新模块开发检查清单

写新模块时，AI 必须逐项自查（基于供应商/物料/价格模块的踩坑经验）：

### 菜单与路由（强制，最容易忘） ← 2026-07-21 编码规则踩坑
- [ ] **MesMenuRegistry**：注册菜单 + 权限码（`leaf()` + `addPerms()`）
- [ ] **mes.ts 路由**：注册前端路由 `path/name/component/meta.title`

### SQL 迁移脚本
- [ ] **SQL 路径**：DDL 放 `project-mes/db/V{版本号}__{描述}.sql`（部署控制台自动执行）
- [ ] **避免 MySQL 保留字**：列名不要用 `current_date`/`order`/`status` 等，否则加反引号 + `@TableField`
- [ ] 唯一索引：`UNIQUE INDEX uk_{table}_code_del (code, del_flag)` 复合索引
- [ ] 字典默认值：`DEFAULT '1'` 用编码非中文文本
- [ ] 菜单注册：不在 SQL 中写菜单 INSERT（走 Java Runner）
- [ ] perms 列：如果 SQL 中有权限 INSERT，必须含 `perms` 列
- [ ] 角色绑定：独立的 `INSERT IGNORE sys_role_permission` 语句

### Entity
- [ ] `@TableName` + `@TableId(type = IdType.ASSIGN_ID)` + `@TableLogic`
- [ ] 字典字段用 `@Dict(dicCode = "...")` + `@Excel(... dicCode = "...")`
- [ ] status 用 `Integer` 类型（与仓库/客户/库位保持一致）
- [ ] 审计字段完整：createBy/createTime/updateBy/updateTime/delFlag
- [ ] update-begin/end 标记包裹

### Controller
- [ ] 所有方法 `@RequiresPermissions`
- [ ] **数据隔离用角色判断，禁止硬编码用户名** ← 2026-07-21 mes_admin踩坑：`!"admin".equals(username)` 在多项目中失效，应用 `SecurityUtils.getSubject().hasRole("mes_admin")`
- [ ] 提供 `queryById` 接口（编辑时获取完整数据）
- [ ] `queryAll` 有上限保护（1000 条）
- [ ] 导入 Excel 先全量校验编码再统一保存
- [ ] 导出有数据量上限
- [ ] `deleteBatch` 处理空字符串

### ServiceImpl
- [ ] 参数校验：code/name 非空+长度、字典值白名单
- [ ] `save()` catch `DuplicateKeyException` 友好提示
- [ ] `removeByIds` 用 `super.removeByIds`（非 `this.removeById` 循环）
- [ ] 导入用 `@Transactional(rollbackFor = Exception.class)`
- [ ] **来源字段无条件覆盖** — 从关联表继承的字段（如 `deliveryQty` 从发货单来），Service 中无条件 `setXxx(src.getXxx())`，不做 `if-null-then-set`。前端只读只是 UI 防线，API 可绕过（来源：出库模块 P0-10）
- [ ] `resurrect` SQL 含 `AND del_flag = 1` 条件
- [ ] **合计计算在持久化之前** — `calcTotal()`/`calcSummary()` 必须在 `super.save()`/`resurrect()`/`updateById()` **之前**调用。之后调用只改内存对象不写数据库→字段永久NULL（来源：库存闭环审计 P0-01）
- [ ] **audit 先改状态再执行副作用** — 审核方法中先执行原子 `auditWithGuard`（UPDATE ... WHERE status='X'），成功后再扣库存/写台账/联动下游。副作用先于状态变更→并发失败时库存幻扣（来源：库存闭环审计 P1-01）
- [ ] **金额操作必须 FOR UPDATE 行锁** — 涉及金额"读-校验-写"的操作（收款/付款/库存扣减），必须在 Mapper 层提供 `selectByIdForUpdate` 方法，Service 层使用行锁读取后再更新，防止并发超收超付（来源：全量审计 P0-01）
- [ ] **对称操作并发保护一致** — 入库/出库、收款/付款、应收/应付等对称操作必须使用相同的锁机制。一处用了 `selectForUpdate`，另一处也必须用（来源：全量审计 P0-02）
- [ ] **跨模块查不到关键数据必须抛异常** — 从关联表取单价/数量/金额时，找不到或为空必须抛出明确异常，禁止 `if (!list.isEmpty())` 静默跳过。库存增加但金额未计→业财数据不一致（来源：全量审计 P1-04）
- [ ] **发号/计数器禁止 synchronized + @Transactional 共存** — synchronized 在事务代理内层，锁释放早于事务提交，并发可发重号且集群失效。取号/发号/计数器必须用 `SELECT ... FOR UPDATE` 行锁（`.last("FOR UPDATE")`）或原子 `UPDATE ... SET seq=seq+1`（来源：2026-07-21 codeRule 审计 P1-A）
- [ ] **自动生成关联单据必须补齐所有 NOT NULL 字段** — 建表 DDL 中 `NOT NULL` 且无 `DEFAULT` 的列，insert 时必须赋值，否则静默失败（事务回滚 insert 但 UPDATE 守卫可能已提交）。无法确定值时取系统默认值（如第一个仓库 ID）。禁止随机拼编码——用已有的 getNextCode 服务。（来源：2026-07-22 O2D2O warehouse_id 踩坑，反复部署 4 次）

### Mapper
- [ ] `selectDeletedByCode` 用 `@Select` 注解原生 SQL
- [ ] `resurrect` 用 `@Update` 注解原生 SQL（非 JdbcTemplate）

### 前端
- [ ] formSchema 中字典字段用 `JDictSelectTag` + 正确的 `dictCode`
- [ ] 表字典（关联其他表）用 `JSearchSelect` + `dict: 'table,text,code'`（注意：是合写格式不是分立字段）
- [ ] `Switch` 组件设 `checkedValue/unCheckedValue`
- [ ] `DatePicker` 设 `valueFormat`

### MenuRegistry
- [ ] 菜单用 `MesMenuDefinition.leaf/folder` 注册
- [ ] 权限码用 `MesMenuDefinition.permission` 注册
- [ ] parentId 指向正确的父菜单 ID
- [ ] **Runner fixIfNeeded 检测"不一致"非仅"为空"** — 修改菜单的 parentId/name/url 后，Runner 应能检测已有记录的值与定义不同并自动修正。只判空会导致菜单变更后悬挂在旧父级下（来源：出库模块菜单重组）

> **自更新规则：** 每次新模块开发后，如果发现了此清单未覆盖的坑，AI 必须在 `/learn` 后提议添加新条目到此清单。清单只增不减，每个条目必须标注来源模块。

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
