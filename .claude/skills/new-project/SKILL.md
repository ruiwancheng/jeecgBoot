---
name: new-project
description: 创建新的 KA 客户项目。当用户说"创建新的客户项目"、"新建一个项目"、"初始化客户模块"时自动触发。Create a new KA customer project when user says "create a new customer project", "new project", "init customer module".
---

# 新建 KA 客户项目

为 KA 客户创建独立的定制项目模块，包含后端 Maven 模块和前端页面目录。

---

## 前置条件

- 用户提供 `<项目名>`（英文小写，如 `haier`、`evergrande`）
- 模板源已存在：`jeecg-boot/jeecg-boot-module/project-template/`

---

## 步骤一：复制模板

### 后端模块

从模板复制到目标目录：

| 源 | 目标 |
|---|---|
| `jeecg-boot/jeecg-boot-module/project-template/` | `jeecg-boot/jeecg-boot-module/project-<项目名>/` |

复制后，对 `pom.xml` 做占位符替换：

- `customer-template` → `project-<项目名>`（artifactId）
- `{客户名称}` → `<项目名>`（description）

### 前端目录

创建前端页面目录：
```
jeecgboot-vue3/src/views/project/<项目名>/
```

在该目录下创建初始页面 `index.vue`（占位首页）。

---

## 步骤二：占位符替换

在复制后的所有文件中执行以下替换：

| 占位符 | 替换为 |
|---|---|
| `project-template` | `project-<项目名>`（Maven artifactId） |
| `{项目名称}` | `<项目名>`（.manifest.yml 显示名） |
| `{客户名称}` | `<项目名>`（.manifest.yml customer 字段） |
| `{创建日期}` | 当前日期 YYYY-MM-DD |

### Java 包路径重命名

如果模板中包含 Java 源码，将包路径中的 `template` 替换为 `<项目名>`：

```
src/main/java/org/jeecg/boot/module/project/template/
→ src/main/java/org/jeecg/boot/module/project/<项目名>/
```

### .manifest.yml

替换后的 `.manifest.yml` 应为：

```yaml
# Super Harness 覆盖清单
customer: <项目名>
base_version: 3.9.2
created: <YYYY-MM-DD>

overrides: []

additions: []
```

---

## 步骤三：Maven 注册

### 注册点 1：`jeecg-boot/jeecg-boot-module/pom.xml`

在 `<modules>` 中添加：

```xml
<module>project-<项目名></module>
```

### 注册点 2：`jeecg-boot/jeecg-module-system/jeecg-system-start/pom.xml`

在 `<dependencies>` 中添加：

```xml
<!-- KA 客户定制模块 -->
<dependency>
    <groupId>org.jeecgframework.boot3</groupId>
    <artifactId>project-<项目名></artifactId>
    <version>${jeecgboot.version}</version>
</dependency>
```

---

## 步骤四：Maven 编译验证

```bash
cd jeecg-boot
mvn clean install -pl jeecg-boot-module/project-<项目名> -am -DskipTests
```

---

## 步骤五：数据库初始化

### 角色和用户 SQL

在 `jeecg-boot/jeecg-boot-module/project-<项目名>/src/main/resources/sql/` 下创建初始化 SQL 文件（如 `init-role-user.sql`）。

**密码加密：** 使用 `PasswordUtil.encrypt(username, password, salt)` 生成加密密码。算法 PBEWithMD5AndDES，迭代1000次，参数顺序为 `(用户名, 明文密码, 盐值)`。

```sql
-- 创建项目角色
INSERT INTO sys_role (id, role_name, role_code, description, create_by, create_time, update_by, update_time)
VALUES ('<随机UUID>', '<项目名>角色', '<项目名>', '<项目名>项目角色', 'admin', NOW(), 'admin', NOW());

-- 创建项目管理员用户
INSERT INTO sys_user (id, username, realname, password, salt, status, del_flag, create_by, create_time, update_by, update_time)
VALUES ('<随机UUID>', '<项目名>_admin', '<项目名>管理员', '<加密密码>', '<盐值>', '1', '0', 'admin', NOW(), 'admin', NOW());

-- 绑定用户角色
INSERT INTO sys_user_role (id, user_id, role_id)
VALUES ('<随机UUID>', '<用户ID>', '<角色ID>');
```

### 执行 SQL 到数据库

SQL 文件生成后，检测 MySQL 可用性并自动执行：

1. **检测 MySQL：** `docker ps --filter name=mysql` 或本地 `mysql` 命令
2. **写入加密密码：** 用 `PasswordUtil.encrypt(用户名, 明文密码, 盐值)` 生成正确密文
3. **执行 SQL（关键）：** 必须管道方式传文件，避免 shell 二次编码导致中文乱码

```bash
# ✅ 正确：管道传文件
cat /tmp/init.sql | docker exec -i <容器名> mysql -u root -proot --default-character-set=utf8mb4

# ❌ 错误：-e 参数传中文
# docker exec <容器名> mysql -e "INSERT ... VALUES('中文')"
```

4. **验证编码：** 用 `SELECT HEX(realname)` 确认每个汉字 3 字节（非双重编码）

---

## 步骤六：前端路由

创建路由文件 `jeecgboot-vue3/src/router/routes/modules/<项目名>.ts`：

```typescript
import { LAYOUT } from '/@/router/constant';
import type { AppRouteModule } from '/@/router/types';

const project: AppRouteModule = {
  path: '/project/<项目名>',
  name: '<项目名>',
  component: LAYOUT,
  redirect: '/project/<项目名>/index',
  meta: { orderNo: 9000, title: '<项目名>', icon: 'ion:grid-outline' },
  children: [
    {
      path: 'index',
      name: '<项目名>Index',
      component: () => import('/@/views/project/<项目名>/index.vue'),
      meta: { title: '<项目名>首页' },
    },
  ],
};
export default project;
```

**注意：** 前端路由路径必须与后端菜单配置中的 URL 一致。

---

## 步骤七：激活项目

写入当前项目标记文件：

```
.claude/memory/active-project.md
```

内容：

```markdown
# 当前项目：<项目名>
```

---

## 检查清单

- [ ] 后端模块 `project-<项目名>` 已创建且占位符已替换
- [ ] 前端目录 `views/project/<项目名>/` 已创建
- [ ] Maven 两处注册已完成（boot-module/pom.xml + system-start/pom.xml）
- [ ] Maven 编译通过（`mvn clean install -pl ... -am -DskipTests`）
- [ ] SQL 初始化脚本已创建且已执行到数据库（编码正确）
- [ ] 前端路由文件已创建
- [ ] 激活文件已写入 `.claude/memory/active-project.md`
- [ ] 所有新增文件已 git 暂存
