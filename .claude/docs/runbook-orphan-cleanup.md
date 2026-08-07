# 库存总览孤儿行清理：故障响应 Runbook

最后更新：2026-08-07。关联方案：`hermes/plan/inventory-orphan-cleanup-2026-08-07.md`。

## 1. 处置原则

先保留证据，再执行清理。UI 是业务主流程；SQL 脚本仅由 DBA 使用，默认 DRY-RUN，真实执行前必须完成诊断和备份。任何有库存孤儿行都需要业务确认，不得直接删除。

## 2. 常见场景

### A. 库存总览出现孤儿行

1. DBA 执行 `harness/scripts/sql/diagnose-orphan-inventory.sql`，记录 Q1-Q5 输出。
2. 零库存行由业务人员在 UI 中单删或批删。
3. 紧急处置使用 `cleanup-orphan-inventory.sh clean-zero`，先保持默认 DRY-RUN。

### B. 物料删除返回 500

查看后端日志中的“物料被以下表引用”，并调用 `preCheckDelete` 对引用分布进行确认。若是未关闭订单、批次、库存或台账，交由业务先完成业务流程；若是 checker/schema 不一致，检查启动自检和数据库迁移状态。

### C. 守卫误报或启动失败

检查 `MaterialReferenceCoverageAssertor` 的 missing/extra 表差集、19 个 checker 的 bean 扫描，以及 `del_flag` 和单据 status 的实际字典值。修复 schema 或 checker 后再重启，不要通过禁用守卫绕过。

### D. 批量删除失败

确认请求使用 `POST` JSON body，`ids` 非空且单批不超过 500；并发冲突或行锁超时应拆批、错峰重试。

### E. 审计表超过 100,000 行

确认归档 cron：`crontab -l | grep archive-cleanup-audit`。先执行 `archive-cleanup-audit.sh` 查看 DRY-RUN SQL，确认备份与历史表可写后，再显式执行 `DRY_RUN=0`。归档失败时保留活跃表，不手工删除审计记录。

### F. MySQL 死锁或锁等待

记录死锁日志、batch_id 和请求时间；短期降低并发、拆分批次并重试。长期检查所有批量 SQL 是否按稳定 ID 顺序取锁，并评估锁等待超时和索引命中情况。

## 3. 回滚

单批回滚：

```bash
./harness/scripts/sql/cleanup-orphan-inventory.sh rollback --batch-id biz-sign-YYYY-MM-DD
```

回滚前核对审计行的 `rolled_back=0`、目标 ID 尚未被重新占用，且在事务内完成；重复回滚或跨批次回滚必须拒绝并升级 DBA。涉及整库影响时停服并从经过验证的 `mysqldump` 恢复，禁止直接拼接 ID 执行 DELETE。

## 4. 监控与告警

| 指标 | 阈值 | 检查方式 |
|---|---:|---|
| 新增孤儿行/周 | > 0 | 诊断 SQL Q1 |
| 活跃审计表行数 | > 100,000 | `SELECT COUNT(*)` |
| rollback 次数/周 | > 5 | 审计表 `rolled_back=1` |
| checker 覆盖表数 | != 19 | 应用启动自检日志 |

## 5. RCA 与升级

24 小时内收集日志、诊断 SQL、审计 batch_id 和影响物料；评估订单/库存影响后止血，完成 5-why 根因分析，补 checker 或 SQL 修复，执行 Slice 5 回归测试并记录 learning。后端问题升级 `#mes-backend`，数据库问题升级 DBA/PagerDuty，业务影响升级业务负责人和 on-call。

## 6. 月度作业

```cron
0 2 1 * * cd /path/to/jeecgBoot && DRY_RUN=0 bash harness/scripts/sql/archive-cleanup-audit.sh >> /tmp/archive-cleanup-audit.log 2>&1
```

首次上线和每次改 TTL 前先手工 DRY-RUN；确认 `MES_DB_*` 环境变量、备份策略、历史表权限和日志轮转均已就绪。
