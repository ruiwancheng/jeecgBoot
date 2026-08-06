-- ============================================================
-- V10.0.6  MES 批次流水 remark 列补齐 + 批次字典初始化
-- 作者:pi  日期:2026-08-07
--
-- 业务改动：
--   - dev profile flyway.enabled=false，所有 V10.0.5 之前 migration 都不自动跑
--   - 导致 c_mes_batch_ledger.remark 列缺失（V8.0.0/V10.0.2 schema 都有定义）
--   - MyBatis-Plus 自动 SELECT 实体所有字段含 remark → SQLSyntaxErrorException
--   - /mes/batch/ledger/listByBatchId 端点 500（5 处 SQL 错误）
--   - 同时 sys_dict 缺 mes_batch_origin_type / mes_batch_status 两个字典
--   - 导致 MesBatchTraceabilityVO.@Dict 反查不输出 dictText（1.5 失败）
--
-- 修复：
--   1) ALTER TABLE c_mes_batch_ledger ADD COLUMN remark（幂等）
--   2) INSERT sys_dict + sys_dict_item：mes_batch_origin_type（4 项）
--   3) INSERT sys_dict + sys_dict_item：mes_batch_status（3 项）
--   所有 INSERT 用 WHERE NOT EXISTS 守卫，重复执行无副作用
--
-- 字典值设计：
--   mes_batch_origin_type:
--     1 = 采购入库   2 = 完工入库   3 = 生产领料   4 = 销售出库
--   mes_batch_status:
--     1 = 正常       2 = 已冻结     3 = 已耗尽
--
-- 验收：
--   node harness/tests/modules/traceability-batch-level.test.js
--   预期 39/39 passed（之前 34/39）
-- ============================================================

-- ============================================================
-- 1) c_mes_batch_ledger + remark 列（idempotent ALTER）
-- ============================================================
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE table_schema = DATABASE()
    AND table_name = 'c_mes_batch_ledger'
    AND column_name = 'remark');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_batch_ledger ADD COLUMN remark VARCHAR(500) DEFAULT NULL COMMENT ''备注''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ============================================================
-- 2) mes_batch_origin_type 字典（sys_dict + sys_dict_item）
-- ============================================================

-- 2.1 字典主记录（idempotent：dict_code UNIQUE）
INSERT INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, type, tenant_id)
SELECT 'mes_batch_origin_type_v1006', '批次来源类型', 'mes_batch_origin_type',
       'MES批次主档-来源类型', 0, 'admin', NOW(), 0, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict WHERE dict_code = 'mes_batch_origin_type');

-- 2.2 字典项（4 项）
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, sort_order, status, create_by, create_time)
SELECT 'mes_bot_1_v1006', 'mes_batch_origin_type_v1006', '采购入库', '1', 1, 1, 'admin', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item
                  WHERE dict_id = 'mes_batch_origin_type_v1006' AND item_value = '1');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, sort_order, status, create_by, create_time)
SELECT 'mes_bot_2_v1006', 'mes_batch_origin_type_v1006', '完工入库', '2', 2, 1, 'admin', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item
                  WHERE dict_id = 'mes_batch_origin_type_v1006' AND item_value = '2');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, sort_order, status, create_by, create_time)
SELECT 'mes_bot_3_v1006', 'mes_batch_origin_type_v1006', '生产领料', '3', 3, 1, 'admin', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item
                  WHERE dict_id = 'mes_batch_origin_type_v1006' AND item_value = '3');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, sort_order, status, create_by, create_time)
SELECT 'mes_bot_4_v1006', 'mes_batch_origin_type_v1006', '销售出库', '4', 4, 1, 'admin', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item
                  WHERE dict_id = 'mes_batch_origin_type_v1006' AND item_value = '4');

-- ============================================================
-- 3) mes_batch_status 字典（sys_dict + sys_dict_item）
-- ============================================================

-- 3.1 字典主记录
INSERT INTO sys_dict (id, dict_name, dict_code, description, del_flag, create_by, create_time, type, tenant_id)
SELECT 'mes_batch_status_v1006', '批次状态', 'mes_batch_status',
       'MES批次主档-状态', 0, 'admin', NOW(), 0, 0
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict WHERE dict_code = 'mes_batch_status');

-- 3.2 字典项（3 项）
INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, sort_order, status, create_by, create_time)
SELECT 'mes_bs_1_v1006', 'mes_batch_status_v1006', '正常', '1', 1, 1, 'admin', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item
                  WHERE dict_id = 'mes_batch_status_v1006' AND item_value = '1');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, sort_order, status, create_by, create_time)
SELECT 'mes_bs_2_v1006', 'mes_batch_status_v1006', '已冻结', '2', 2, 1, 'admin', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item
                  WHERE dict_id = 'mes_batch_status_v1006' AND item_value = '2');

INSERT INTO sys_dict_item (id, dict_id, item_text, item_value, sort_order, status, create_by, create_time)
SELECT 'mes_bs_3_v1006', 'mes_batch_status_v1006', '已耗尽', '3', 3, 1, 'admin', NOW()
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM sys_dict_item
                  WHERE dict_id = 'mes_batch_status_v1006' AND item_value = '3');

-- ============================================================
-- 4) 版本锚点（便于 flyway history 追踪）
-- ============================================================
SELECT 'V10.0.6 mes_batch_ledger.remark + 批次字典' AS applied;