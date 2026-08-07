# Flyway migration 在 dev profile 不会自动跑 db/ 下的 SQL

**日期**：2026-08-07
**上下文**：v3 孤儿行清理 V10.2.0__mes_cleanup_audit.sql 没自动建表
**教训**：dev profile 用的 flyway 配置只扫 src/main/resources/flyway/sql/，不扫 db/

## TL;DR

`jeecg-boot-module/project-mes/db/V10.2.0__mes_cleanup_audit.sql` 这个 SQL 文件**从未被 Flyway 自动执行**。

- 它在 `db/` 目录下（手工维护的 DDL 仓库）
- Flyway 配置只扫 `classpath:flyway/sql/mysql`（src/main/resources 内的）
- 业务功能上线时必须**手工 mysql 跑一次**或**改用 Flyway 的命名规则**

## 根本原因

仓库有两个 SQL 目录：

```
project-mes/
├── db/                              ← 手工维护 DDL（不被 Flyway 扫）
│   └── V10.2.0__mes_cleanup_audit.sql
└── src/main/resources/flyway/sql/mysql/   ← Flyway 启动时扫这里
    └── V1.x.x__...sql
```

**Codex 在 Slice 2 实施时把 SQL 放到了 `db/`**，以为这样 Flyway 会自动跑，但实际 Flyway 启动时**只扫 classpath:flyway/sql/mysql**。

## 实际后果

部署后：
- 后端启动成功
- 所有非清理功能正常
- 业务人员点"批量删除孤儿行"按钮 → **500 Internal Server Error**
- 报错：`Table 'jeecg-boot.c_mes_inventory_cleanup_audit' doesn't exist`

因为 audit 表不存在，INSERT 失败。

## 修复方案

### 方案 1（推荐）：把 SQL 移到 Flyway 扫描路径

```bash
mkdir -p src/main/resources/flyway/sql/mysql
mv db/V10.2.0__mes_cleanup_audit.sql \
   src/main/resources/flyway/sql/mysql/V10.2.0__mes_cleanup_audit.sql
```

这样 Flyway 启动会自动执行。

### 方案 2：保留 db/，手工跑 SQL

适用：临时修复或一次性迁移
```bash
mysql -h127.0.0.1 -uroot -proot jeecg-boot < db/V10.2.0__mes_cleanup_audit.sql
```

### 方案 3：让 Flyway 同时扫 db/ + src/main/resources

修改 `application-dev.yml`：
```yaml
flyway:
  locations:
    - classpath:flyway/sql/mysql
    - filesystem:db/  # 加这个（仅 dev 用）
```

## 派 codex 时的检查清单

| 检查 | 说明 |
|---|---|
| 新增 DDL/SQL 放哪个目录？ | **必须**放 `src/main/resources/flyway/sql/mysql/`（自动跑） |
| 不能放 db/ | db/ 是手工维护目录，Flyway 不会扫 |
| 命名规范 V{x.x.x}__xxx.sql | 否则 Flyway 不识别 |

## 教训

1. **不要相信 codex "已自动跑 Flyway"**：Flyway 是否跑了某 SQL，**必须在启动日志确认**
2. **测试要包括"启动后能立即操作新表"**：否则 audit/迁移类表缺失会被掩盖
3. **本地启动后立即 INSERT 一条数据**：最简单验证表是否存在

## 本次实际修复

我手工跑了 `mysql < V10.2.0__mes_cleanup_audit.sql`，临时修好。但**正确做法**是移到 src/main/resources/flyway/sql/mysql/ 并 commit。
