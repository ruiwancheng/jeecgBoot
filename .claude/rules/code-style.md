---
name: code-style
description: 代码规范——命名、格式、修改标记、后端优先、安全、平台保护与覆盖
glob: "**/*.{java,vue,ts,sql,xml}"
version: 2.0
---

# 代码规范

## Java
- 实体：`Sys` 前缀系统表，`@TableId(type = IdType.ASSIGN_ID)`
- Controller：继承 `JeecgController<Entity, IService>`
- Service：`I{Entity}Service` / `{Entity}ServiceImpl`
- Mapper：`{Entity}Mapper extends BaseMapper<Entity>`
- 所有修改加 `update-begin`/`update-end` 标记
- **软删除 + 唯一索引："借尸还魂"模式** — `save()` 先查活跃记录(正常MP)，再查软删除记录（用 Mapper `@Select` 注解原生 SQL 绕过 `@TableLogic` 拦截器），找到则复用旧ID/创建人/创建时间，用 Mapper `@Update` 注解原生 UPDATE 将 `del_flag` 归零并覆盖业务字段，同时设 `updateBy`/`updateTime` 保留审计链。避免唯一索引冲突+保留历史关联。**经验证：MyBatis-Plus 3.5.16 + JeecgBoot 3.9.5 中 `@Select` 注解的方法不会被 `@TableLogic` 拦截器追加 `AND del_flag=0`**，此方案适用当前版本。如遇升级 MyBatis-Plus 大版本，需重新验证此行为。
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
- [ ] **commit 前对账**：`grep -c "update-begin" file.java` 应等于 `grep -c "update-end" file.java`；差异用 python 栈模拟找未闭合 begin：
  ```python
  import re
  for i, line in enumerate(lines, 1):
      for m in re.finditer(r'update-begin', line): stack.append(i)
      for m in re.finditer(r'update-end', line):
          if stack: stack.pop(0)
          else: print(f'L{i}: 多余 update-end')
  if stack: print(f'未闭合 begin: {stack}')
  ```
  来源：2026-08-02 `MesSalesOutboundServiceImpl.java` L336 重复 update-end（4 年历史 bug）被栈模拟 1 行定位修复。

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
- **业务流水（ledger）唯一职责 = 库存变动**：创档/状态变更/冻结/解冻都不写 ledger。同一业务动作只产一条流水（含 warehouse_id + biz_id + biz_no + in_qty/out_qty + 数量变动方向），同 `biz_id + biz_type` 出现 2 条 = 重复记账 → 未来"批次追溯"会双倍扣减。代码 review 看到 `writeLedger` 立即想：warehouseId 是空吗？是空就不该写。表设计时 `warehouse_id NOT NULL` 可架构上拦截错误写入（实证：2026-08-01 修复 MesBatchServiceImpl.createBatchWithManualNo 重复写 ledger）

## 后端优先原则

> 合并自 `backend-first.md`（2026-07-28 token 降本）

- 数据验证、状态转换、计算逻辑、默认值——全部在 Service 中实现
- Controller 只做参数接收和调用 Service
- 前端仅做 UI 展示和格式校验（必填、长度），不做业务判断
- 扩展字段用项目专属扩展表，不修改标品表结构

## 平台保护与覆盖

> 合并自 `no-platform-modify.md` + `override-mechanism.md`（2026-07-28 token 降本）

### 发现框架 Bug 时
1. 不修改框架代码
2. 记录到 `.claude/memory/platform-issues.md`
3. 在项目模块中用覆盖机制绕过
4. 通知技术负责人

记录格式：`[日期] 问题 | 文件 | 现象 | 临时绕过方案`

### Bean 替换
客户模块中创建同名 Service Bean，标记 `@Primary`：
```java
@Service
@Primary
public class ProjectXxxServiceImpl extends XxxServiceImpl {
    // 覆盖标品方法
}
```

### 路由覆盖
客户目录下注册同名路由，路径加客户前缀：
```typescript
// project/{项目名}/xxx.ts
path: '/project/{项目名}/xxx'
```

### 页面覆盖
客户目录下创建同名 Vue 组件，通过菜单配置指向客户版本。

### 记录追踪
所有覆盖操作记录在 `project-{项目名}/.manifest.yml`：
```yaml
project: {项目名}
overrides:
  - type: bean
    original: XxxServiceImpl
    replacement: ProjectXxxServiceImpl
  - type: route
    path: /system/xxx
    replacement: /project/{项目名}/xxx
```

### 扩展表
不能修改标品表结构。在客户目录下创建扩展表（如 `c_{项目名}_order_ext`），通过外键关联标品表。

## 安全规范

> 合并自 `security.md`（2026-07-28 token 降本）

- 不改 `.env`，不写死密码/Token/API Key
- 不执行 `git push --force`、`DROP TABLE`、无 WHERE 的 DELETE
- SQL 用 MyBatis-Plus 参数化，不拼字符串
- 敏感配置通过环境变量注入

## 数据库/SQL 规范沉淀（2026-07 / 8 月 learnings 合并）

//update-begin---author:evolve---date:2026-08-02---for:【/evolve 批 3】合并 7 月数据库/SQL 9 条 learnings 到 code-style.md---

### 字典项幂等 INSERT 模式（dict-item-insert-ignore-duplicates）

**铁律**：`sys_dict_item` 缺少 `(dict_id, item_value)` 唯一约束。`INSERT IGNORE + SELECT + UUID()` 每次部署生成新 UUID → 新记录 → 字典项越积越多（物料模块 4 次部署膨胀到 117 条）。

**正确写法**：先 `DELETE` 后 `INSERT VALUES`，无论部署多少次都只有 N 条：
```sql
DELETE FROM sys_dict_item WHERE dict_id = (SELECT id FROM sys_dict WHERE dict_code = 'xxx');
INSERT INTO sys_dict_item (...) VALUES (...), (...), (...);
```

详见 `learnings/2026-07-15-dict-item-insert-ignore-duplicates.md`。

### JSearchSelect 表字典配置格式（jsearchselect-dict-format）

**铁律**：`JSearchSelect` 只认合写 `dict` 属性（`table,text,code`），不认分立的 `dictTable`/`dictText`/`dictCode`。

```ts
// ✅ 正确
{ component: 'JSearchSelect', componentProps: { dict: 'c_mes_material,name,id' } }
// ❌ 错误 — 下拉无数据
{ component: 'JSearchSelect', componentProps: { dictTable: 'c_mes_material', dictText: 'name', dictCode: 'id' } }
```

| 表 | 配置 |
|---|---|
| 物料 | `dict: 'c_mes_material,name,id'` |
| 客户 | `dict: 'c_mes_customer,name,id'` |
| 仓库 | `dict: 'c_mes_warehouse,name,id'` |

详见 `learnings/2026-07-15-jsearchselect-dict-format.md`。

### MySQL HEX() 诊断 UTF-8 编码（mysql-hex-encoding-check）

中文乱码时先用 `HEX()` 看原始字节定位是数据库存储还是应用层问题：

| 编码状态 | HEX 示例（"管理员"） | 字节数 |
|---------|---------|:--:|
| ✅ 正确 UTF-8 | `E7AEA1 E79086 E59198` | 9（每字 3 字节） |
| ❌ 双重编码 | `C3A7C2AE C2A1C3A7 C290E280A0 C3A5E28098 CB9C` | 21（每字节 2-3 字节） |

**判断**：字符数×3 = 正常；远超 = 双重编码（UTF-8 字节被当 Latin-1 再编码为 UTF-8）。

详见 `learnings/2026-07-06-mysql-hex-encoding-check.md`。

### new-project 流程 SQL 执行缺口（new-project-sql-gap）

`/new-project` 技能只生成 `init-role-user.sql` 文件，**不会自动执行到数据库**。用户期望"创建项目"= 可用项目，所以必须自动执行：

```bash
# /new-project 生成 SQL 后，检测 MySQL 可用性 → 自动执行
docker exec jeecg-boot-mysql mysql -uroot -proot `jeecg-boot` < init-role-user.sql
```

详见 `learnings/2026-07-06-new-project-sql-gap.md`。

### Docker MySQL 连字符库名用反引号（docker-mysql-backtick）

含连字符的库名（如 `jeecg-boot`）在 `docker exec mysql ...` 中必须用反引号包裹，且 shell 中需转义：

```bash
# ❌ 错误 — 连字符被解析为减法
docker exec jeecg-boot-mysql mysql -uroot -proot -e "SELECT * FROM jeecg-boot.sys_user;"
# → ERROR 1064

# ✅ 正确 — shell 转义反引号
docker exec jeecg-boot-mysql mysql -uroot -proot -e "SELECT * FROM \`jeecg-boot\`.sys_user;"
```

详见 `learnings/2026-07-06-docker-mysql-backtick.md`。

### WSL MySQL 与 Windows mysqld 抢 3306（wsl-mysql-port-fight）

**现象**：DB 幻影根因。WSL Ubuntu 装了 MySQL 且 systemd enabled，wslrelay.exe 转发 WSL 3306 → 127.0.0.1:3306，与 Windows mysqld 同时应答。连接被随机路由到两个不同 server_uuid 的库，`service mysql stop` 后 systemd 自动拉起。

**诊断**：
```bash
for i in 1 2 3; do mysql -uroot -proot --host=127.0.0.1 -N -e "SELECT @@server_uuid;"; done
# 出现两个不同 uuid = 两个库在抢端口
netstat -ano | grep ":3306" | grep LISTEN   # wslrelay.exe + mysqld.exe 双监听
```

**根治**（stop 不够，**必须 disable** 防 systemd 复活）：
```bash
wsl -d Ubuntu -- sudo systemctl disable mysql
wsl -d Ubuntu -- sudo service mysql stop
```

**项目约定**：本地开发库以 Windows 手动 mysqld 为准（`"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe" --console`），WSL 内禁止跑 MySQL。

详见 `learnings/2026-07-29-wsl-mysql-port-fight.md`。

### 软删除 + 唯一索引"借尸还魂"模式（tablelogic-resurrection）

数据库 `UNIQUE(code)` + MyBatis-Plus `@TableLogic`。场景：新建 ck001 → 软删除 → 重建 ck001 → 再删 → ❌ 唯一索引冲突。

**根因**：`@TableLogic` 自动追加 `AND del_flag=0`：
- `selectOne(qw)` 找不到软删除记录
- `updateById(entity)` 改不了软删除记录

**解决方案**：新增时复用软删除旧记录（保留 ID/创建人/创建时间，历史关联数据不中断）：

```java
// 1. 查活跃记录 → @TableLogic 自动过滤，正常
if (baseMapper.selectCount(activeQw) > 0) throw exception("已存在");

// 2. 查软删除记录 → 必须原始 SQL 绕过
MesWarehouse old = baseMapper.selectDeletedByCode(code);

// 3. 有则复活 → 必须原始 SQL 绕过
if (old != null) {
    entity.setId(old.getId());
    entity.setCreateBy(old.getCreateBy());
    entity.setCreateTime(old.getCreateTime());
    baseMapper.resurrect(entity);  // UPDATE ... SET del_flag=0
    return true;
}

// 4. 没有 → 正常新增
return super.save(entity);
```

**Mapper 原始 SQL**：
```java
@Select("SELECT * FROM c_mes_warehouse WHERE code = #{code} AND del_flag = 1 LIMIT 1")
MesWarehouse selectDeletedByCode(String code);

@Update("UPDATE c_mes_warehouse SET code=#{code}, name=#{name}, ..., del_flag=0 WHERE id=#{id}")
void resurrect(MesWarehouse entity);
```

详见 `learnings/2026-07-06-tablelogic-resurrection.md`。

### 跨链路 @Dict 注解一致性扫描（dict-annotation-parity-check）

**黄金模板对齐前必做的跨链路扫描**：后端实体的 `@Dict(dictTable, dicText, dicCode)` 是手动添加的，跨模块同语义字段（purchaseApplyId / salesOrderId）独立维护。黄金模板对齐只改前端，但前端依赖后端 `@Dict` 才能让 list 接口带 `_dictText`。

```bash
# 黄金模板对齐前必做
grep -E "@Dict\(dictTable" jeecg-boot/jeecg-boot-module/project-mes/src/main/java/.../entity/*.java
```

**判断信号**：
- Claude 评审反复提醒"前端依赖后端" → 往往是 `@Dict` 不一致
- 看到 `_dictText` 在 list 接口有但 queryById 没有 → 关联 learning dict-text-only-on-list

**实证**：2026-07-30 采购链路黄金模板对齐，2 字段 5 分钟修复（1 行注解 × 2 文件）。不评审直接改前端会出现"代码看起来都对，文案却显示 UUID"的诡异 bug。

详见 `learnings/2026-07-30-dict-annotation-parity-check.md`。

### @Dict 字段 _dictText 只在 list 接口返回（dict-text-only-on-list）

**陷阱**：JeecgBoot 平台的 `DictAspect` 字典填充切面**只对 `*Controller.list` 分页查询生效**。自定义 `*Service.queryWithItems`（含 `selectById` + 关联子查询）走 MyBatis Plus 直接 mapper，**绕过了切面**——`queryById` 返回的 `_dictText` 为 None。

**前端 fallback 必须**：
```ts
// 不要相信"@Dict 自动带" — 所有响应式关联文案必须实测 list 和 queryById 两个接口
const orderRef = delivery.salesOrderId_dictText || delivery.salesOrderId;
if (orderRef) {
  alertText.value = `由订单 ${orderRef} 创建。出库后订单自动置已发货。`;
}
```

详见 `learnings/2026-07-30-dict-text-only-on-list.md`。

//update-end---author:evolve---date:2026-08-02---for:【/evolve 批 3】合并 7 月数据库/SQL 9 条 learnings 到 code-style.md---
