# [2026-07-28] [Harness] Learnings 批量归档操作 — 必须逐条验证等效覆盖

## 触发条件
对 learnings/ 目录通过关键词匹配批量归档 27 条记录，减少 ~33% 文件数。

## 发现
关键词批量匹配效率高但**安全代价大**：
1. MEMORY.md 产生 6 条断链 — 3 条在 rules 中完全无等效覆盖（docker-mysql-backtick、new-project-sql-gap、mysql-hex-encoding-check）
2. 1 条被归档的 learning（`@Select` vs `JdbcTemplate`）与活跃 rule `code-style.md` 存在**技术矛盾**——两个冲突的知识同时存在于体系中
3. 6 条 Harness 设计模式 learnings 的核心实现细节未被等效迁移

## 处理方式
- **批量归档前必做一步交叉验证：** 对每条命中关键词的 learning，搜索活跃 rules 和 MEMORY.md 中是否有引用或等效覆盖
- 在归档文件第一行加 `# Archived: equivalent coverage in <rule>:<line>` 注释
- MEMORY.md 断链用 `[ARCHIVED]` 标记替代删除（保留知识点索引）
- 无等效覆盖的 learnings **恢复为活跃**（不归档）
- 有技术矛盾的 learnings **先在活跃 rules 中解决矛盾，再归档**

## 关联
- [[2026-07-28-dual-ai-audit-complement]] — Orca 评审首次发现本问题
