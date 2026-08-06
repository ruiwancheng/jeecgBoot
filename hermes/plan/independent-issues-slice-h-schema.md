# 独立问题修复 Plan (Slice H) — DB schema + 字典完整性

**作者**：pi
**日期**：2026-08-07
**前置**：Phase 1+2+3+4 + Slice A/B/C/D/E/F/G 全部完成。剩余 43 个失败中的类别 A（DB schema）处理。
**目标范围**：traceability-batch-level 5 个 module 测试失败 + 影响 1.5/1.7 dict 反查

---

## 1. 现状（pre-existing 全部）

### 1.1 根因（worker 根因分析 + 实测验证）

跑 `harness/tests/modules/traceability-batch-level.test.js` 实测结果：

```
❌ 1.5 dict 反查字段齐全: 缺失=originType_dictText,status_dictText
❌ 4.1 抽屉接口 200: code=500
   Cause: java.sql.SQLSyntaxErrorException: Unknown column 'remark' in 'field list'
   mapper: MesBatchLedgerMapper.java
❌ 4.5 无效 batchId 不崩溃: code=500
   Cause: Unknown column 'remark' in 'field list'
```

**5 处 SQL 错误的真实根因**（dev DB）：

| 问题 | 现状 | 影响 | 涉及测试 |
|---|---|---|---|
| **A1** `c_mes_batch_ledger.remark` 列缺失 | dev DB 表无 remark 列，MyBatis-Plus 自动生成 SELECT 语句含 remark 字段 → SQL 错误 | listByBatchId 端点 500 | 4.1, 4.2, 4.5, 4.6 |
| **A2** `mes_batch_origin_type` 字典缺失 | sys_dict 表无该 dict_code，DictAspect.step3 查不到翻译 → dictText 不输出 | 列表 originType_dictText 缺失 | 1.5 |
| **A3** `mes_batch_status` 字典缺失 | sys_dict 表无该 dict_code，同上 | 列表 status_dictText 缺失 | 1.5 |

dev DB 验证（`SHOW COLUMNS FROM c_mes_batch_ledger`）：
- ❌ 无 `remark` 列（有 remain_qty 等 17 列）
- ✅ 现有：id, batch_id, material_id, warehouse_id, batch_no, biz_type, biz_id, biz_no, in_qty, out_qty, remain_qty, unit_cost, occur_time, create_by, create_time, update_by, update_time, del_flag

dev DB 字典验证（`SELECT dict_code FROM sys_dict`）：
- ❌ 无 `mes_batch_origin_type`
- ❌ 无 `mes_batch_status`
- ✅ 现有 mes_* 字典：mes_bom_status, mes_completion_status, mes_delivery_status, mes_order_status, mes_other_stock_status, mes_outbound_status, mes_payable_status, mes_picking_status, mes_production_order_status, mes_purchase_apply_status, mes_purchase_order_status, mes_purchase_receipt_status, mes_receivable_status, mes_supplier_status, mes_voucher_status, ...

### 1.2 Schema 文件状态

- V0.0.0__mes_initial_schema.sql 定义了 c_mes_batch_ledger 含 remark 列（dev DB 未执行）
- V8.0.0__mes_batch_init.sql `CREATE TABLE IF NOT EXISTS c_mes_batch_ledger` 含 remark 列（dev DB 未执行）
- V10.0.2__mes_batch_tables.sql 同上
- V10.0.4__mes_dev_db_schema_fix.sql 处理了 biz_type/biz_id/biz_no/occur_time 列名变更，**未处理 remark**
- 字典初始化 SQL：未在 V*.sql 中专门处理 mes_batch_*

**结论**：dev profile `flyway.enabled=false`，所有 migration 都不跑，所以 dev DB 缺少这些列/字典。

---

## 2. 目标

| # | 验收项 | 度量 |
|---|---|---|
| H-1 | `c_mes_batch_ledger.remark` 列在 dev DB 存在 | `SHOW COLUMNS` 含 remark |
| H-2 | `mes_batch_origin_type` 字典在 sys_dict 存在 | `SELECT FROM sys_dict` 返回 |
| H-3 | `mes_batch_status` 字典在 sys_dict 存在 | 同上 |
| H-4 | `traceability-batch-level.test.js` 5 个失败用例全部转 ✅ | 39/39 passed |
| H-5 | 全量 module 切片回归 module-final: 3/9 → ≥ 7/9 通过 | 至少 traceability-batch-level 由 ❌ 转 ✅ |
| H-6 | V10.0.6 SQL 文件 idempotent（可重复执行） | information_schema + IF NOT EXISTS |

---

## 3. 方案

### 3.1 新增 V10.0.6__mes_batch_ledger_remark_and_dicts.sql

位置：`jeecg-boot/jeecg-boot-module/project-mes/db/V10.0.6__mes_batch_ledger_remark_and_dicts.sql`

内容：
1. **ALTER TABLE c_mes_batch_ledger ADD remark**（dev DB 列补齐，幂等）
2. **INSERT mes_batch_origin_type 字典**（idempotent by dict_code unique key）
3. **INSERT mes_batch_status 字典**（idempotent）
4. **INSERT sys_dict_item 字典项**

字典值设计：

**mes_batch_origin_type（4 项）**：
| value | text | 说明 |
|---|---|---|
| 1 | 采购入库 | 来源 = 采购入库单 |
| 2 | 完工入库 | 来源 = 完工入库单 |
| 3 | 生产领料 | 来源 = 生产领料单 |
| 4 | 销售出库 | 来源 = 销售出库单（批次耗尽反向） |

**mes_batch_status（3 项）**：
| value | text | 说明 |
|---|---|---|
| 1 | 正常 | 可用 |
| 2 | 已冻结 | 手工冻结（不可出库） |
| 3 | 已耗尽 | 库存 0，自动设置 |

### 3.2 ID 生成策略

- sys_dict.id 用 32 字符标准 ID（`UUID()` 或固定 32 hex）
- 选固定 ID 便于 idempotent INSERT（用 `WHERE NOT EXISTS`）
- 字典项 ID 用 `CONCAT(dict_id_prefix, sequence)` 模式，便于复用

### 3.3 SQL 模板

```sql
-- 1) c_mes_batch_ledger.remark 列补齐（dev DB 缺）
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_batch_ledger' AND column_name = 'remark');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_batch_ledger ADD COLUMN remark VARCHAR(500) DEFAULT NULL COMMENT ''备注''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) mes_batch_origin_type 字典（idempotent）
INSERT INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, type, tenant_id)
SELECT 'mes_batch_origin_type_v1006', '批次来源类型', 'mes_batch_origin_type', 'MES批次主档-来源类型', 0, 'admin', NOW(), 0, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict WHERE dict_code = 'mes_batch_origin_type');

-- 3) mes_batch_origin_type 字典项（4 项）
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, sort_order, status, create_by, create_time)
SELECT 'mes_batch_origin_type_1_v1006', 'mes_batch_origin_type_v1006', '采购入库', '1', 1, 1, 'admin', NOW()
FROM DUAL WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item WHERE dict_id = 'mes_batch_origin_type_v1006' AND item_value = '1');
-- ... 同样模式插入 2/3/4 项

-- 4) mes_batch_status 字典（idempotent）
INSERT INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, type, tenant_id)
SELECT 'mes_batch_status_v1006', '批次状态', 'mes_batch_status', 'MES批次主档-状态', 0, 'admin', NOW(), 0, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict WHERE dict_code = 'mes_batch_status');

-- 5) mes_batch_status 字典项（3 项）
-- ... 同样模式插入 1/2/3 项
```

### 3.4 直接验证方式

dev profile `flyway.enabled=false`，migration 不会自动跑，需手动执行：
```bash
mysql -h 127.0.0.1 -uroot -proot jeecg-boot < V10.0.6__mes_batch_ledger_remark_and_dicts.sql
```

production profile `flyway.enabled=true` 会自动跑。

---

## 4. 风险与缓解

| 风险 | 缓解 |
|---|---|
| 重复执行 V10.0.6 导致唯一键冲突 | sys_dict.dict_code 是 UNIQUE，使用 `WHERE NOT EXISTS` 守卫 |
| sys_dict_item 没有 (dict_id, item_value) UNIQUE 约束 | 同上用 `WHERE NOT EXISTS` |
| ID 命名冲突（与已有字典 ID 撞） | 使用带 `_v1006` 后缀的固定 ID，避免与 sys_dict 已有 ID 冲突 |
| dev DB 不重启 service 时 DictAspect 缓存 | 测试前重启 jeecg-boot 或清 redis 字典缓存 |
| 别处有相同 dict_code 已存在但 dict_item 不同 | `WHERE NOT EXISTS` 仅检查 dict_code 是否存在，存在则整个字典插入跳过 |

---

## 5. 执行计划

| 步骤 | 命令 / 操作 | 预期 |
|---|---|---|
| 1 | 写 `V10.0.6__mes_batch_ledger_remark_and_dicts.sql` | 文件就绪 |
| 2 | 手动跑：`mysql ... < V10.0.6__mes_batch_ledger_remark_and_dicts.sql` | dev DB schema 更新 |
| 3 | 重启 jeecg-boot（或 spring-boot restart） | DictAspect 加载新字典 |
| 4 | `cd harness && node tests/modules/traceability-batch-level.test.js` | 39/39 passed |
| 5 | `node harness/scripts/run-batch.js module final` | module-final: ≥ 7/9 通过 |
| 6 | 写 plan 文档（本文件） | 已写 |

---

## 6. 不做的（Out of Scope）

- 已耗尽 status="3" 的自动设置（业务侧自动行为，非本次修复范围）
- 其他 c_mes_* 表可能缺的列（仅修本次测试暴露的）
- importExcel 500 等其它独立 issue（Slice G 类目独立处理）

---

## 7. 参考

- latest run: `harness/.regression-runs/20260807-010744/`
- failure logs:
  - `harness/.regression-runs/20260807-010744/logs/e2e-purchase-sales.attempt-1.log` (traceabilityBatch 测试 3/4 失败)
  - `harness/.regression-runs/20260807-010744/logs/module-final.attempt-1.log` (traceability-batch-level ❌)
- 实体类：`jeecg-boot/.../entity/MesBatchLedger.java`（含 remark 字段）
- VO：`jeecg-boot/.../entity/MesBatchTraceabilityVO.java`（@Dict originType/status）
- 历史 migration 模板：`jeecg-boot/.../db/V10.0.4__mes_dev_db_schema_fix.sql`（类似 idempotent ALTER）

---

## 8. Plan 修订记录

| 版本 | 日期 | 修订 | 来源 |
|---|---|---|---|
| v1 | 2026-08-07 | 初版 | PI /plan |