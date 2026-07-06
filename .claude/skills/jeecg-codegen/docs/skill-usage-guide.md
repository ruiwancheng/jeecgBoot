# jeecg-codegen Skills 使用指南

> 通过 Claude Code 以自然语言描述业务需求，自动生成 JeecgBoot 全套 CRUD 代码（后端 Java + 前端 Vue3 + 建表 SQL + 菜单 SQL）。
> 无需预建表结构，AI 根据语义自动推导表结构、字段类型与前端控件；也支持基于已有表或多表关联生成代码。覆盖单表、树表、一对多等模型，可一次性生成整个业务模块。主键策略自适应，字典字段自动匹配系统已有编码——不只是模板填充，而是从业务需求到可运行代码的端到端生成。

## 与传统代码生成器的区别

- **无需预建表结构**：只需用自然语言描述业务需求，AI 即可自动推导出表结构与字段属性，省去手动建表的前置工作
- **表结构驱动同样支持**：也可以直接基于已有的数据库表或多表关联关系生成代码，兼容传统代码生成器的使用习惯
- **模块级批量生成**：支持一次性生成整个业务模块的全部代码文件（涵盖多张表、多个功能点），而非逐表逐模型地单独生成
- **主键策略自适应**：AI 会参照项目中已有表的主键定义，自动选用合适的 MyBatis-Plus 主键策略，不局限于 String 类型的雪花 ID
- **字典智能匹配**：自动读取系统字典表（`sys_dict` + `sys_dict_item`），为字段精准匹配已有的字典编码，免去手动查找和指定的繁琐步骤
- **代码自动归位**：生成的前后端代码自动落入项目对应目录，建表与菜单 SQL 自动追加至 Flyway 升级脚本，无需手动搬运，生成即就绪

---

## 触发方式

在 Claude Code 对话中，用自然语言描述你要创建的功能，包含以下任意关键词即可自动触发：

```
代码生成 / 生成代码 / 创建模块 / 新增功能 / 建表 / 加字段 / 增加字段 / 新增字段 / 修改字段 / 删除字段
```

## 示例用法

### 1. 一句话描述（最简方式）

```
帮我生成一个商品管理模块，包含商品名称、价格、库存、状态、图片、描述
```

AI 会自动推导：表名 `biz_goods`、字段类型（价格→BigDecimal、库存→Integer、图片→JImageUpload 等）。

### 2. 指定表名和字典

```
创建一个订单管理功能：
- 表名 biz_order
- 字段：订单编号、客户名称、下单日期、金额、状态（待付款/已付款/已发货/已完成）、备注
- 状态用字典 order_status
```

### 3. 树表（带层级关系）

```
建一个部门分类的树表，包含分类名称和分类编码
```

提到"分类/层级/树/上下级"等关键词，AI 自动识别为树表模式。

### 4. 一对多（主子表）

```
生成一个采购单模块，主表是采购单（单号、供应商、日期、总金额），
子表是采购明细（商品名、数量、单价、小计）
```

提到"主子表/明细/一对多"等关键词，AI 自动识别为一对多模式。

### 5. 指定后端模块

```
在 jeecg-module-demo 模块下生成一个公告管理，包含标题、内容（富文本）、发布时间、状态
```

### 6. 已有表反向生成（给表名即可）

```
生成 tmp_tables 这个表的代码
```

AI 会自动连接数据库查询 DDL，解析主键类型、全部字段、系统字段，然后生成匹配的代码。无需手动描述字段。

### 7. 增量修改（给已有模块加/改/删字段）

```
给表信息管理加一个备注字段
```

```
给 tmp_tables 增加两个字段：排序号和状态（启用/停用）
```

```
把商品管理的价格字段从 int 改成 decimal
```

```
删除商品管理的描述字段
```

AI 会自动定位已生成的全部代码文件（Entity、data.ts、Form.vue 等），精确修改每个文件，并生成 ALTER TABLE 的 Flyway SQL，无需重新生成整个模块。

## 交互流程

### 全量生成流程

```
Step 0  判断操作类型：全量生成 or 增量修改？
        ↓
Step 1  解析需求，判断场景：
        · 场景A — 已有表 → 查数据库获取 DDL，自动解析字段
        · 场景B — 新建表 → 从自然语言推导表结构
        ↓
Step 2  询问 4 个选项（都有默认值，说"确认"即可）：
        ① 后端模块 — 默认 jeecg-module-system/jeecg-system-biz
        ② 前端风格 — vue3（封装风格）或 vue3Native（原生风格）
        ③ 前端目录 — 默认按 entityPackage 值
        ④ 是否读取系统字典 — 默认是，自动匹配已有字典编码
        ↓
Step 3  展示表结构摘要（含匹配到的字典），等待确认
        ↓
Step 4  确认后，自动生成全部文件写入项目目录
        ↓
Step 5  输出生成文件清单 + 后续操作说明
```

### 增量修改流程

```
Step 0  识别增量修改关键词（加字段/删字段/修改字段/给XX加...）
        ↓
Step 1  定位目标模块，扫描并读取已有代码文件
        （Entity.java / *.data.ts / *List.vue / *Modal.vue / *Form.vue）
        ↓
Step 2  解析已有字段，推导新字段属性
        ↓
Step 3  展示修改摘要（每个文件的具体变更内容），等待确认
        ↓
Step 4  确认后，用 Edit 精确修改每个文件 + 生成 ALTER TABLE SQL
        ↓
Step 5  输出修改文件清单 + 后续操作说明
```

## 生成产物

### 单表模式（11 个文件）

| 类别 | 文件 | 说明 |
|------|------|------|
| **后端** | `Entity.java` | 实体类，含 MyBatis-Plus / AutoPoi / Dict 注解 |
| | `Controller.java` | REST 控制器，继承 JeecgController，含权限注解 |
| | `IService.java` | Service 接口 |
| | `ServiceImpl.java` | Service 实现 |
| | `Mapper.java` | MyBatis Mapper 接口 |
| | `Mapper.xml` | MyBatis XML 映射 |
| **前端** | `*.api.ts` | API 接口定义（list/save/edit/delete/export/import） |
| | `*.data.ts` | 列定义 + 查询表单 + 编辑表单 Schema |
| | `*List.vue` | 列表页面（表格 + 查询 + 操作按钮） |
| | `*Modal.vue` | 编辑弹窗 |
| | `*Form.vue` | 表单组件（仅 vue3Native 风格） |
| **SQL** | `V*__.sql` | Flyway 迁移：建表DDL + 菜单 + 7个按钮权限 + 角色授权 |

### 树表模式

在单表基础上增加：
- Entity 额外字段：`pid`（父节点）、`has_child`（是否有子节点）
- Controller 额外接口：`rootList`、`childList`、`getChildListBatch`
- Service 额外方法：树节点的增删改逻辑
- 前端额外接口：树数据加载、子节点查询

### 一对多模式

在单表基础上增加：
- 子表完整的 Entity / Mapper / Service 各一套
- 主表 Service 包含联合保存/更新/删除
- Page VO 用于 Excel 主子表导入导出
- 前端 Tab 页展示子表数据

## 两种前端风格

| | vue3 封装风格 | vue3Native 原生风格 |
|---|-------------|-------------------|
| **表单** | `BasicForm` + FormSchema 配置驱动 | `a-form` + `a-form-item` 模板直接写控件 |
| **弹窗** | `BasicModal` + `useModal` Hook | `JModal` + `ref` + `defineExpose` |
| **表格** | `BasicTable` + `useTable` + `formConfig` 内置查询 | `BasicTable` + 手写查询表单区域 |
| **数据文件** | columns + searchFormSchema + formSchema | columns + superQuerySchema（表单在模板中） |
| **优点** | 代码量少，配置化，统一风格 | 灵活度高，可深度定制交互 |
| **适合** | 标准 CRUD 页面 | 需要复杂交互或自定义布局的场景 |

## 智能字段推导

AI 根据字段语义自动推导类型和控件：

| 语义关键词 | 数据库类型 | Java 类型 | 前端控件 |
|-----------|----------|----------|---------|
| 名称/标题/编码 | varchar(100) | String | Input / a-input |
| 金额/价格/费用 | decimal(10,2) | BigDecimal | InputNumber / a-input-number |
| 数量/个数 | int | Integer | InputNumber / a-input-number |
| 状态/类型/级别 | varchar(10) | String | JDictSelectTag |
| 是否/开关 | varchar(2) | String | Switch / a-switch |
| 日期/生日 | date | Date | DatePicker / a-date-picker |
| 时间/日期时间 | datetime | Date | DatePicker(showTime) |
| 备注/描述/说明 | text | String | InputTextArea / a-textarea |
| 内容/富文本 | text | String | JEditor |
| 图片/头像/照片 | varchar(1000) | String | JImageUpload |
| 文件/附件 | varchar(1000) | String | JUpload |
| 用户/负责人 | varchar(32) | String | JSelectUserByDept |
| 部门/组织 | varchar(32) | String | JSelectDept |
| 排序/序号 | int | Integer | InputNumber / a-input-number |

当然，你也可以在描述中明确指定字段类型，AI 会优先使用你的指定。

### 已有表的 DB 类型→控件自动映射

对于已有表场景，如果字段没有注释，AI 根据数据库列类型自动推导前端控件：

| DB 列类型 | Java 类型 | 默认前端控件 |
|----------|----------|-----------|
| varchar(n) n<=200 | String | Input |
| varchar(n) n>200 | String | InputTextArea |
| text / longtext | String | InputTextArea |
| int / tinyint | Integer | InputNumber |
| bigint | Long | InputNumber |
| decimal / double / float | BigDecimal | InputNumber |
| date | Date | DatePicker |
| datetime / timestamp | Date | DatePicker(showTime) |

## 字典智能匹配

生成代码时，AI 可选择读取系统字典表（`sys_dict` + `sys_dict_item`），自动为字段匹配已有的字典编码。

**匹配优先级：**
1. **用户明确指定** — `"状态用字典 order_status"`，直接使用
2. **字段名精确匹配** — 字段名 `status` 与字典编码 `status` 一致
3. **语义关键词匹配** — 字段注释含"状态"，搜索字典名称含"状态"的字典
4. **不匹配** — 找不到合适字典时，不使用字典注解，按普通 Input 处理

**效果示例：**

假设系统中已有字典 `order_status`（待付款=0, 已付款=1, 已完成=2），当你描述字段"订单状态"时：

| 位置 | 自动生成内容 |
|------|-------------|
| Entity.java | `@Dict(dicCode = "order_status")` |
| columns | `dataIndex: 'orderStatus_dictText'` |
| formSchema | `component: 'JDictSelectTag', componentProps: { dictCode: 'order_status' }` |
| searchFormSchema | `component: 'JDictSelectTag', componentProps: { dictCode: 'order_status' }` |

在 Step 3 表结构摘要中会展示匹配结果，确认前可以修改或取消字典关联。

## 已有表反向生成

给定表名时，AI 会自动连接数据库获取精确表结构：

1. **查询 DDL**：`SHOW CREATE TABLE 表名` 获取完整建表语句
2. **查询字段详情**：从 `information_schema.COLUMNS` 获取每个字段的类型、注释、是否可空、默认值、主键标识
3. **解析主键策略**：根据主键列类型和是否 AUTO_INCREMENT 选择 MyBatis-Plus 注解
4. **识别系统字段**：检查 create_by/create_time/update_by/update_time/sys_org_code 是否存在
5. **推导前端控件**：优先用字段注释语义匹配，无注释时按 DB 类型映射

数据库连接信息：`mysql -h127.0.0.1 -P3306 -uroot -proot jeecgboot3`（配置文件：`application-dev.yml`）

## 增量修改详解

### 支持的操作

| 操作 | 说明 | 影响的文件 |
|------|------|-----------|
| **加字段** | 在所有文件中追加新字段定义 | Entity + data.ts + Form.vue(Native) + ALTER TABLE SQL |
| **删字段** | 从所有文件中移除指定字段 | Entity + data.ts + Form.vue(Native) + DROP COLUMN SQL |
| **改字段** | 修改字段类型/控件/注释等 | Entity + data.ts + Form.vue(Native) + MODIFY COLUMN SQL |

### 修改位置清单

每次增量修改，AI 会精确定位并修改以下位置：

1. **Entity.java** — 字段声明 + 注解（@Excel、@Dict、@Schema、@JsonFormat 等）+ 必要的 import
2. ***.data.ts** — columns 列定义 + formSchema 表单项 + searchFormSchema 查询条件（如需） + superQuerySchema（如存在）
3. ***Form.vue**（仅 vue3Native）— `<a-form-item>` 控件 + `formData` 初始值
4. **Flyway SQL** — `ALTER TABLE ADD/DROP/MODIFY COLUMN` 语句

## Flyway 版本号规则

生成 Flyway SQL 前自动检查已有版本号，递增避免冲突：

- 版本命名：`V{YYYYMMDD}_{序号}__{描述}.sql`
- 检查当天是否已有文件（如 `V20260311_1__xxx.sql`）
- 如果有，序号递增（`V20260311_2__xxx.sql`）
- 如果没有，从 `_1` 开始
- 菜单 SQL 的 ID 使用 13 位毫秒级真实时间戳（`date +%s%3N`），确保全局唯一

## 主键策略自适应

AI 会根据已有表的 DDL 自动选择正确的主键策略：

| 表DDL中的主键定义 | Java类型 | MyBatis-Plus 注解 |
|------------------|---------|------------------|
| `int AUTO_INCREMENT` | Integer | `@TableId(type = IdType.AUTO)` |
| `bigint AUTO_INCREMENT` | Long | `@TableId(type = IdType.AUTO)` |
| `varchar(36)` 无自增 | String | `@TableId(type = IdType.ASSIGN_ID)` |
| `bigint` 无自增 | Long | `@TableId(type = IdType.ASSIGN_ID)` |

新建表时默认使用 JeecgBoot 标准的 `varchar(36) + ASSIGN_ID`。

**注意：** 当主键为 Integer/Long 类型时，Controller 中 `delete` 和 `queryById` 的参数类型也要对应调整，`deleteBatch` 需要做类型转换。

## 系统字段智能判断

**对于已有表**，AI 会检查表结构，只生成表中实际存在的系统字段：

| 字段 | 不存在时 |
|------|---------|
| `create_by` / `create_time` | 不生成对应 Java 属性 |
| `update_by` / `update_time` | 不生成对应 Java 属性 |
| `sys_org_code` | 不生成对应 Java 属性 |

**对于新建表**（自然语言描述需求），默认添加全部系统字段。

树表额外字段：`pid`、`has_child`（同样需检查是否实际存在）。

## 生成后的操作

### 1. 执行 SQL

生成的 Flyway SQL 文件位于：
```
jeecg-module-system/jeecg-system-start/src/main/resources/flyway/sql/mysql/
```

两种方式：
- **自动执行**：重启后端时 Flyway 自动执行
- **手动执行**：在数据库中手动执行 SQL 文件内容

### 2. 重启后端

```bash
cd jeecg-boot-framework-2026
mvn spring-boot:run -pl jeecg-module-system/jeecg-system-start
```

### 3. 刷新前端

开发服务器（`pnpm dev`）会自动热更新，无需重启。

### 4. 访问功能

登录系统后，新菜单已自动添加（默认授权给 admin 角色），直接可见可用。

## 文件路径说明

| 类别 | 路径 |
|------|------|
| 后端代码 | `jeecg-boot-framework-2026/{module}/src/main/java/org/jeecg/modules/{package}/` |
| 前端代码 | `jeecgboot-vue3-2026/src/views/{viewDir}/` |
| Flyway SQL | `jeecg-boot-framework-2026/jeecg-module-system/jeecg-system-start/src/main/resources/flyway/sql/mysql/` |

## 注意事项

1. **每次生成/修改前会展示摘要等你确认**，不会直接写文件，放心使用
2. **已有表按实际结构生成**，不会盲目添加不存在的字段
3. **权限编码规则**：`{entityPackage}:{tableName}:add/edit/delete/deleteBatch/exportXls/importExcel`
4. **如果后端模块目录不存在**，AI 会提示你先创建 Maven 模块结构
5. **生成的代码可以二次修改**，和手写代码完全一样，没有任何框架锁定
6. **增量修改只改动必要的文件和位置**，不会影响你手动修改过的其他代码
7. **字典匹配可选**，不想自动匹配字典时在 Step 2 选择"否"即可
