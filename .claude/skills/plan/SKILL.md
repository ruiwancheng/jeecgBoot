---
name: plan
description: 制定实施计划，区分纯新增/覆盖标品/加字段三种策略 — Create implementation plan, distinguishing three strategies: new feature, override standard product, add fields
version: 1.0.0
---

# 实施计划 (Plan)

## features.json

`features.json` 是项目模块清单文件，记录每个模块的元信息：

```json
{
  "modules": [
    {
      "name": "模块名称",
      "path": "后端模块路径",
      "type": "controller|service|entity|mapper",
      "description": "模块功能描述"
    }
  ]
}
```

**用途：** 制定计划前先查 `features.json`，定位相关标品模块的位置，判断是需要新增还是覆盖。

## 标品（标准产品）概念

标品是 JeecgBoot 框架自带的代码，位置在：

| 目录 | 内容 |
|------|------|
| `jeecg-boot-base-core/` | 平台核心框架（Controller 基类、工具类、AOP） |
| `jeecg-module-system/` | 系统管理（用户、角色、菜单、字典、日志） |
| `jeecg-boot-module/jeecg-module-demo/` | 演示示例代码 |

**核心原则：客户定制代码不能修改标品源文件。** 只能通过覆盖机制扩展。

## 三种策略

### 策略 1：纯新增

**适用场景：** 客户需要标品完全没有的功能。

**做法：**
- 后端在 `jeecg-boot/jeecg-boot-module/project-{项目名}/` 新建 Entity / Mapper / Service / Controller
- 前端在 `jeecgboot-vue3/src/views/customer/{客户名}/` 新建页面
- 路由文件在 `jeecgboot-vue3/src/router/routes/modules/` 新建
- 菜单权限在 `sys_permission` 表新增，id 用项目前缀

### 策略 2：覆盖标品

**适用场景：** 需要修改标品已有功能的行为或界面。

**做法：**

| 覆盖方式 | 具体操作 |
|----------|----------|
| Bean 替换 | 在项目模块中创建同名 Service Bean，标记 `@Primary` 注解 |
| 路由覆盖 | 客户目录下新建同名路由，路径加客户前缀 |
| 页面覆盖 | 客户目录下创建同名 Vue 组件，通过菜单配置指向客户版本 |

**记录要求：** 所有覆盖操作记录到 `project-{项目名}/.manifest.yml`：

```yaml
overrides:
  - target: 被覆盖的标品类/路由/页面路径
    override_by: 客户覆盖版本路径
    reason: 覆盖原因
    date: YYYY-MM-DD
```

### 策略 3：加字段

**适用场景：** 需要在标品表上添加客户专属字段。

**做法：**
- 不修改标品表结构
- 创建扩展表 `c_{项目名}_{标品表名}_ext`
- 通过外键关联标品表主键
- 业务逻辑中 LEFT JOIN 或单独查询扩展表

```sql
CREATE TABLE c_{项目名}_{原表}_ext (
    id varchar(32) NOT NULL COMMENT '主键',
    source_id varchar(32) NOT NULL COMMENT '关联标品表主键',
    ext_field_1 varchar(255) COMMENT '扩展字段1',
    ext_field_2 varchar(255) COMMENT '扩展字段2',
    PRIMARY KEY (id),
    KEY idx_source_id (source_id)
) COMMENT='{项目名}-{原表}扩展表';
```

## 计划输出格式

```
## 实施计划

### 策略判定
- 类型：纯新增 / 覆盖标品 / 加字段
- 涉及标品模块：<路径>（覆盖/加字段时填写）

### 文件清单

| 文件 | 操作 | 说明 |
|------|------|------|
| jeecg-boot/.../XxxController.java | 新增 | 实现 xxx 接口 |
| jeecgboot-vue3/.../index.vue | 新增 | xxx 页面 |

### 任务步骤

#### 步骤 1：xxx
- 操作：...
- 代码：关键代码片段
- 验证命令：curl ... / Playwright ...

#### 步骤 2：xxx
...

### 范围外
- 不包含：xxx（原因）

### 风险
- 风险1：xxx → 缓解措施：xxx
```

## 铁律

> 禁止输出 TODO / TBD / "适当处理" 等模糊表述。每一步必须有具体代码和验证命令。
> 计划必须先展示给用户确认，用户说"开始"后才执行。
