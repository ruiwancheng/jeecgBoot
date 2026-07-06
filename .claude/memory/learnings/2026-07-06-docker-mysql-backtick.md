---
name: docker-mysql-backtick
description: Docker 中执行 MySQL 命令时，含连字符的库名必须用反引号包裹
metadata:
  type: reference
---

# Docker 中 MySQL 连字符库名引用

## 问题

通过 `docker exec` 执行 MySQL 命令时，数据库名 `jeecg-boot` 含连字符，直接使用会导致语法错误：

```bash
# ❌ 错误 — 连字符被解析为减法
docker exec jeecg-boot-mysql mysql -u root -proot -e "SELECT * FROM jeecg-boot.sys_user;"
# → ERROR 1064: SQL syntax error near '-boot.sys_user'
```

## 解决

使用反引号包裹数据库名：

```bash
# ✅ 正确
docker exec jeecg-boot-mysql mysql -u root -proot -e "SELECT * FROM \`jeecg-boot\`.sys_user;"
```

**Why:** MySQL 将 `jeecg-boot` 解析为 `jeecg - boot`（减法表达式），反引号强制将其作为标识符处理。在 shell 中需要转义反引号（`\``），否则会被 shell 解释为命令替换。

**How to apply:** 所有通过 Docker 执行的 MySQL 命令中，含特殊字符（连字符、空格等）的数据库名、表名、列名一律用反引号包裹，shell 中需转义。
