# [2026-07-21] [数据库] MySQL保留字作列名 → DDL ERROR 1064 → 部署静默失败

## 触发条件
建表 SQL 中使用了 MySQL 保留字作为列名（如 `current_date`、`order`、`status`），
部署控制台执行时报 `ERROR 1064: syntax error near 'current_date VARCHAR(10)...'`。

## 根因
MySQL 解析器将 `current_date` 识别为内置函数 `CURRENT_DATE()`，而非列名。
部署控制台执行失败后**不记录校验码**（只有成功的 SQL 才去重），导致每次部署都重试→每次报同样错误。

## 正确处理
```sql
-- 错误
current_date VARCHAR(10) DEFAULT NULL

-- 正确：加反引号
`current_date` VARCHAR(10) DEFAULT NULL COMMENT '当前日期'
```

**INSERT 列清单同样要加反引号（2026-07-21 补充）：**

```sql
-- 错误（部署时 ERROR 1064，INSERT 静默失败，种子数据从未落库）
INSERT INTO t (id, ..., current_seq, current_date, ...) VALUES ...

-- 正确
INSERT INTO t (id, ..., current_seq, `current_date`, ...) VALUES ...
```

**种子数据脚本不要用 DELETE+INSERT 保幂等（同日补充）：** 会重置流水号等运行数据（本次 PO 流水被重置回 0001）。改用 `INSERT IGNORE` + 固定 id。

同时 Java Entity 加注解：
```java
@TableField("`current_date`")
private String currentDate;
```

## 诊断方法
1. 部署后 API 报 `Table 'xxx' doesn't exist` → 查部署日志
2. 部署日志中搜索 `ERROR 1064` → 定位具体 SQL 行
3. 核对 MySQL 保留字列表确认列名是否冲突

## MySQL 5.7 常见保留字陷阱
`current_date`, `current_time`, `current_timestamp`, `order`, `group`, `key`,
`status`, `type`, `name`, `desc`, `range`, `match`, `level`, `offset`, `rank`
