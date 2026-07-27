---
name: security
description: 安全——禁止危险操作、保护敏感信息
glob: "**/*"
version: 1.0
---

# 安全规范

- 不改 `.env`，不写死密码/Token/API Key
- 不执行 `git push --force`、`DROP TABLE`、无 WHERE 的 DELETE
- SQL 用 MyBatis-Plus 参数化，不拼字符串
- 敏感配置通过环境变量注入
