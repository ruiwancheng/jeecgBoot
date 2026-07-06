---
name: debugging
description: 标准化调试——不猜测，按步骤排查
glob: "**/*"
version: 1.0
---

# 调试规范

## 黄金法则
不猜测，按步骤。同一修复失败 3 次必须停下来。

## 流程
1. 完整读报错，不只看一行
2. 从栈中找项目代码文件名和行号
3. Read 上下文（前后 20 行）
4. `git diff` 查看近期改动
5. 最小修复，修一处验证一处
6. 3 次无效 → 告知用户具体情况

## JeecgBoot 常见报错
- `Table 'xxx' doesn't exist` → Flyway 未执行或表名错误
- `Could not autowire` → 模块未注册 Maven 依赖
- `ERR_NAME_NOT_RESOLVED` → Docker 内部主机名
- `401/403` → Token 过期或权限不足
