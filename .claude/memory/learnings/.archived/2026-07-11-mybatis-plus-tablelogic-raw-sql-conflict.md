# MyBatis-Plus @TableLogic 与 @Select 原始 SQL 冲突

**触发条件：** 使用 `@Select` 注解查询 `del_flag=1` 的软删除记录时

**现象：** `@Select("SELECT * FROM t WHERE code=? AND del_flag=1")` 查不到已删除记录，MyBatis-Plus 的 `@TableLogic` 拦截器给 SQL 追加了 `AND del_flag=0`，导致实际查询条件变为 `del_flag=1 AND del_flag=0`（永远无结果）

**处理方式：**
- 使用 Spring `JdbcTemplate` 执行原生 SQL，完全绕过 MyBatis-Plus 拦截器
- 不要依赖 `@Select`/`@Update` 注解做软删除相关的绕过查询
- "借尸还魂"模式（软删除+编码回收）的查删+复活操作统一用 JdbcTemplate

**日期：** 2026-07-11
