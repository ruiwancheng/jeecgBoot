# MES Slice 6.1 报告 — traceability-batch-level

## 切片信息

| 项 | 值 |
|---|---|
| Slice ID | 6.1 |
| Slice Name | traceability-batch-level |
| 测试范围 | MES 批次追溯 V10.0.3 API |
| 分支 | fix/regression-2026-08-04 |
| 跑测时间 | 2026-08-04 |
| 后端环境 | http://localhost:8080/jeecg-boot（在线） |
| 测试文件 | `harness/tests/modules/traceability-batch-level.test.js` |

## 跑测结果

| 指标 | 值 |
|---|---|
| 通过数 | **42** |
| 失败数 | **0** |
| 跳过数 | 3（R002 子用例，因测试环境无 guest 账号被跳过） |
| 通过率 | **100%**（42/42 实际执行） |
| 总耗时 | **0.57s** |

## 测试分组明细

| # | 分组 | 用例数 | 结果 |
|---|------|-------|------|
| 1 | 列表接口 `/mes/batch/traceability/list` | 9 | ✅ 全通过 |
| 2 | 搜索 batchNo | 2 | ✅ 全通过 |
| 3 | 搜索 materialId/originType/status | 6 | ✅ 全通过 |
| 4 | 抽屉接口 `/mes/batch/ledger/listByBatchId` | 6 | ✅ 全通过 |
| 5 | 导出 `/mes/batch/traceability/exportXls` | 3 | ✅ 全通过 |
| 6 | R002 越权访问 | 1（跳 3） | ✅ 通过 + 3 跳过 |
| 7 | R003 数值边界 | 5 | ✅ 全通过 |
| 8 | R005 SQL 注入 / 特殊字符 | 7 | ✅ 全通过 |
| 9 | 数据完整性 | 1 | ✅ 通过 |
| 10 | 空数据 | 2 | ✅ 全通过 |

### 关键校验点（已通过）

- **批次级字段**：`batchNo`、`materialId_dictText`、`originType_dictText`、`status_dictText`、`totalInQty`、`ledgerCount` 齐全
- **聚合字段**：`totalInQty`、`ledgerCount` 均为数字
- **字典反查**：`materialId_dictText` 非空（值：生产批次02）
- **抽屉接口**：`listByBatchId` 返回 ledger 数组，流水字段齐全，batchId 匹配
- **导出接口**：响应 200，xlsx 魔数 `504b` 正确，文件 8633 bytes 非空
- **数据完整性**：`ledgerCount` 聚合值与流水表实际行数一致（1 = 1）
- **无效 batchId**：返回空数组 `[]`，不崩溃
- **数值边界**：pageNo=0/-1、pageSize=0/-1/2147483647 均返回 200 无报错
- **SQL 注入 / 特殊字符**：单引号 OR、%、_、DROP、--、中文 + 特殊符号、XSS 均不报错
- **无 token 越权**：返回 401
- **空数据**：超大 pageNo 返回 records=[]，不报错

## 失败明细

**无失败用例。**

唯一非通过项：R002 子用例 6.2-6.4 跳过，原因：
```
⚠️ 无权限账号 guest 不存在或登录失败，跳过 6.2-6.4 (登录失败: 该用户不存在，请注册)
```
属于**测试环境配置缺口**（缺 guest 测试账号），不影响功能本身验证。

## 新发现 Bug

**未发现新 Bug。**

所有功能、边界、安全相关用例均通过。

### 附带观察（建议跟进，非阻塞）

| 观察 | 严重度 | 说明 |
|------|--------|------|
| 测试环境缺少 `guest` 无权限账号 | P3 | R002 完整越权用例（6.2-6.4）无法执行，需在 `sys_user` 表预置无 `mes_admin` 角色的账号以覆盖完整越权矩阵 |
| 边界场景 pageNo=-1 返回 code=200 而非 400 | P3 | 当前实现"宽容处理"非法分页参数，从 UX 角度可接受（不报错即 OK），但若上游契约要求 400 需补校验 |

## 下一步建议

1. **可继续推进 Slice 6.2** — 6.1 批次级追溯验证已完成且全部通过，可直接进入下一切片
2. **可选：补 R002 完整越权用例** — 在测试库预置 `guest` 账号（无 `mes_admin` 角色），覆盖 6.2-6.4 完整越权矩阵
3. **无需代码修复** — 当前批次追溯模块功能、聚合、导出、抽屉接口、SQL 注入防护均工作正常

## 结论

✅ **Slice 6.1 traceability-batch-level 验证通过。**
42/42 用例全绿，无 P0/P1 风险，可标记完成。