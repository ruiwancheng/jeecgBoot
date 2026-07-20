---
name: setup
description: 初始化客户项目（建库、执行 SQL、编译模块）。当用户说"初始化项目"、"执行建表"、"部署项目"、"运行 SQL"时自动触发。Initialize a customer project (create DB, execute SQL, compile module). Trigger when user says "init project", "run SQL", "deploy project", "setup project".
version: 1.0.0
---

# 项目初始化

对 KA 客户项目执行数据库初始化和 Maven 编译，使项目可运行。

---

## 依赖

- 必须先完成 `/new-project` 创建项目模块
- 最后一步需要 `/restart-backend` 重启后端使新模块生效

---

## 步骤一：执行 SQL 初始化脚本

### SQL 文件位置

```
jeecg-boot/jeecg-boot-module/project-<项目名>/src/main/resources/sql/*.sql
```

### 数据库连接

```bash
mysql -u root -proot -h 127.0.0.1 -P 3306 jeecg-boot
```

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `-u` | `root` | 数据库用户名 |
| `-p` | `root` | 数据库密码 |
| `-h` | `127.0.0.1` | 数据库地址 |
| `-P` | `3306` | 数据库端口 |
| 数据库名 | `jeecg-boot` | 目标数据库 |

### 执行方式

按文件名排序逐个执行：

```bash
for f in $(ls jeecg-boot/jeecg-boot-module/project-<项目名>/src/main/resources/sql/*.sql | sort); do
    echo "执行: $f"
    mysql -u root -proot -h 127.0.0.1 -P 3306 jeecg-boot < "$f"
done
```

### 验证

执行后检查关键表是否创建成功：

```sql
-- 检查项目扩展表是否存在
SHOW TABLES LIKE 'c_<项目名>_%';

-- 检查角色和用户是否创建成功
SELECT id, username, realname FROM sys_user WHERE username = '<项目名>_admin';
SELECT id, role_name, role_code FROM sys_role WHERE role_code = '<项目名>';
```

---

## 步骤二：Maven 编译

### 编译命令

```bash
cd jeecg-boot
mvn clean install -pl jeecg-boot-module/project-<项目名> -am -DskipTests
```

| 参数 | 说明 |
|------|------|
| `clean install` | 清理并安装到本地仓库 |
| `-pl jeecg-boot-module/project-<项目名>` | 指定要构建的模块 |
| `-am` | 同时构建依赖模块（also-make） |
| `-DskipTests` | 跳过测试，加快构建速度 |

### 验证

构建成功标志：终端输出 `BUILD SUCCESS`。

模块 JAR 被安装到本地 Maven 仓库：
```
~/.m2/repository/org/jeecgframework/boot3/project-<项目名>/3.9.2/
```

---

## 步骤三：重启后端

编译完成后，调用 `/restart-backend` 重启应用。

新模块的依赖已在 `jeecg-system-start/pom.xml` 中注册，重启后 Spring Boot 会自动加载该模块中的 Controller、Service、Entity 等组件。

### 验证新模块已加载

```bash
grep "project-<项目名>" /tmp/jeecg-backend.log
```

在启动日志中搜索项目模块名，确认被 Spring Boot 扫描到。

---

## 步骤四：菜单和权限注册（可选）

如果项目 SQL 中包含菜单和权限数据，重启后需要在管理后台执行"刷新权限缓存"操作，或者在数据库中确认菜单已正确挂载：

```sql
SELECT id, name, url, component, parent_id, menu_type
FROM sys_permission
WHERE name LIKE '%<项目名>%'
ORDER BY parent_id;
```

---

## 常见问题

| 问题 | 原因 | 处理 |
|------|------|------|
| SQL 执行报 `Table already exists` | 表已存在 | 检查是否需要 DROP 后重建，或跳过已存在的表 |
| SQL 执行报外键约束 | 依赖的表不存在 | 确认标品表已初始化（`db/jeecgboot-mysql-5.7.sql`） |
| `BUILD FAILURE` | 编译错误 | 检查 pom.xml 占位符是否正确替换，包路径是否正确 |
| 启动后看不到新接口 | 模块未被加载 | 检查 `jeecg-system-start/pom.xml` 是否有依赖 |
| 接口 404 | 路由未匹配 | 检查 Controller 的 `@RequestMapping` 路径 |
