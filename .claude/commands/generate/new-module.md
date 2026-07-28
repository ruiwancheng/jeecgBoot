# 新建标准 CRUD 模块

快速生成 JeecgBoot MES 项目的标准 CRUD 模块（单表或主子表），减少手工探索模板的 Token 消耗。

> 2026-07-29 升级：前端改用**黄金模板**（`harness/templates/mes-doc-page/`），10 个 UX 模式生成即内置，不再产出基础版。

## 触发词

"新建模块"、"创建模块"、"new module"、"加一个XX管理"、"新建页面"

## 流程

### 1. 模式匹配

AI 自动识别模块类型并加载黄金模板：

| 类型 | 模板目录 | 文件数 | 内置 UX 模式 |
|------|---------|:--:|------|
| 单表 | `harness/templates/mes-doc-page/single-table/` | 4 | 1/2/4/7/10 |
| 主子表 | `harness/templates/mes-doc-page/master-detail/` | 5 | 全 10 个 |

模板占位符规范见 `harness/templates/mes-doc-page/README.md`（5 个核心占位符 {{BIZ}}/{{BIZ_NAME}}/{{MOD}}/{{PAGE_COMPONENT}}/{{API_PREFIX}}，case 变体由生成时派生）。

### 2. 生成清单

AI 输出：

```
模块名：{name}
类型：单表/主子表
菜单：{父菜单} > {菜单名}
文件：
  SQL: db/V{X}.0.0__mes_{name}_init.sql
  后端: entity(1/2) + mapper(1/2) + service(2) + controller(1)
  前端: index.vue + Drawer.vue + api.ts + data.ts
  注册: MesMenuRegistry.java +1 菜单 +N 权限码
```

### 3. 批量生成

用户确认后，AI 一次性生成所有文件（不复用探索过程）。生成规则：

- Entity: 复制模板文件结构，替换表名/字段
- Mapper: 复制 `selectDeletedByCode` + `resurrect` 骨架
- Service: 主子表复制 `saveWithItems/updateWithItems/removeWithItems` 模式
- Controller: 9 个标准端点 + `@RequiresPermissions`
- SQL: 模板建表 + DELETE+INSERT 字典 + INSERT IGNORE 角色绑定
- 前端: 模板 index.vue + Drawer.vue + api.ts + data.ts

### 4. 注册

- MesMenuRegistry: `folder/leaf` 注册菜单 + `permission` 注册权限码

### 5. 编译 → 提交 → 部署

## 铁律

- 不逐文件探索已有模板——直接复制已知模式
- 权限码必须同时设 `id` 和 `perms`
- SQL 不加中文菜单名（走 Java Runner）
- 子表无 `delFlag`（先删后插策略）
