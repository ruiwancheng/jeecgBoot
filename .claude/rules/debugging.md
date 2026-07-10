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
5. **提出修复方案 + 解释影响范围，等待用户确认 → 确认后才修改**
6. 最小修复，修一处验证一处
7. 3 次无效 → 告知用户具体情况

## JeecgBoot 常见报错
- `Table 'xxx' doesn't exist` → Flyway 未执行或表名错误
- `Could not autowire` → 模块未注册 Maven 依赖
- `ERR_NAME_NOT_RESOLVED` → Docker 内部主机名
- `401/403` → Token 过期或权限不足
- `找不到符号 变量 log` / `@Slf4j` 不生效 → Java 版本过高（Lombok 不兼容 Java 26），切换到 Java 17 编译
- `timeout of 10000ms exceeded` (登录超时) → MySQL/Redis 未启动，后端收到请求后连接池等待超时
- `Unknown column 'xxx' in 'field list'` (新增字段后) → Docker 重建容器导致 ALTER TABLE 丢失，需重新执行 SQL 迁移；或 MySQL 5.7 不支持 `ADD COLUMN IF NOT EXISTS`，改用 `ADD COLUMN`
- `Data too long for column 'code'` → MySQL 严格模式下 `varchar(N)` 超长插入报错，前端加 `maxlength` + 后端 Service 加长度校验给友好提示
- `Data truncation` (字段截断) → 同上，非严格模式下超长数据被静默截断，需前端 `maxlength` 预防
