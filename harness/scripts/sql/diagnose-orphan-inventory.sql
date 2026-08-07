-- ============================================================================
-- /debug 库存总览"（物料已删除）"诊断 SQL
-- ============================================================================
-- 用途：定位 c_mes_inventory 中指向已删除物料的孤儿行
-- 时机：业务人员反馈"库存总览页面大量显示（物料已删除）"时
-- 输出：3 个查询，分别看规模/分类/关联
--
-- ⚠️ 安全提示：
--   1. 所有 SQL 均为 SELECT（只读），不会修改数据
--   2. 建议先在从库/只读实例跑一次确认结果
--   3. 大表查询可能慢，建议加 LIMIT 或在低峰期执行
-- ============================================================================

SELECT '=== Q1. 孤儿行总数 + 总库存 ===' AS step;

-- Q1: 孤儿行总数（物料软删 + 硬删）
SELECT
    COUNT(*)                                                    AS 孤儿行数,
    SUM(CASE WHEN i.current_qty > 0 THEN 1 ELSE 0 END)          AS 有库存孤儿行,
    SUM(CASE WHEN i.current_qty = 0 THEN 1 ELSE 0 END)          AS 零库存孤儿行,
    SUM(i.current_qty)                                          AS 孤儿库存合计,
    SUM(CASE WHEN i.current_qty > 0 THEN i.current_qty ELSE 0 END) AS 有库存合计
FROM c_mes_inventory i
LEFT JOIN c_mes_material m ON i.material_id = m.id
WHERE m.id IS NULL OR m.del_flag = 1;


SELECT '=== Q2. 按风险分组 ===' AS step;

-- Q2: 按分类统计（零库存 vs 有库存 × 软删 vs 硬删）
SELECT
    CASE
        WHEN m.id IS NULL AND i.current_qty > 0 THEN 'A1_硬删_有库存（高危）'
        WHEN m.id IS NULL AND i.current_qty = 0 THEN 'A2_硬删_零库存（低危）'
        WHEN m.del_flag = 1 AND i.current_qty > 0 THEN 'B1_软删_有库存（高危）'
        WHEN m.del_flag = 1 AND i.current_qty = 0 THEN 'B2_软删_零库存（低危）'
    END AS 风险分组,
    COUNT(*)         AS 行数,
    SUM(i.current_qty) AS 总库存
FROM c_mes_inventory i
LEFT JOIN c_mes_material m ON i.material_id = m.id
WHERE m.id IS NULL OR m.del_flag = 1
GROUP BY 风险分组
ORDER BY 风险分组;


SELECT '=== Q3. 高危孤儿行详情（current_qty > 0，必须盘点） ===' AS step;

-- Q3: 有库存的孤儿行（必须先盘点实物！）
SELECT
    i.id              AS 库存行ID,
    i.material_id     AS 物料ID,
    i.warehouse_id    AS 仓库ID,
    i.current_qty     AS 当前库存,
    CASE WHEN m.id IS NULL THEN '物料硬删除'
         WHEN m.del_flag = 1 THEN '物料软删除'
    END              AS 孤儿原因,
    i.create_time     AS 创建时间,
    i.update_time     AS 最后变动,
    -- 关联业务单据数（用于追溯）
    (SELECT COUNT(*) FROM c_mes_completion_receipt_item cri
     WHERE cri.material_id = i.material_id) AS 完工引用数,
    (SELECT COUNT(*) FROM c_mes_sales_outbound_item soi
     WHERE soi.material_id = i.material_id) AS 销售引用数,
    (SELECT COUNT(*) FROM c_mes_purchase_receipt_item pri
     WHERE pri.material_id = i.material_id) AS 采购引用数,
    (SELECT COUNT(*) FROM c_mes_batch b
     WHERE b.material_id = i.material_id AND b.del_flag = 0) AS 批次引用数
FROM c_mes_inventory i
LEFT JOIN c_mes_material m ON i.material_id = m.id
WHERE (m.id IS NULL OR m.del_flag = 1)
  AND i.current_qty > 0
ORDER BY i.current_qty DESC, i.update_time DESC
LIMIT 100;  -- 最多展示 100 行，超出需业务分批处理


SELECT '=== Q4. 零库存孤儿行（可批量清理） ===' AS step;

-- Q4: 零库存孤儿行（清理目标）
SELECT
    i.id              AS 库存行ID,
    i.material_id     AS 物料ID,
    i.warehouse_id    AS 仓库ID,
    i.current_qty     AS 当前库存,
    CASE WHEN m.id IS NULL THEN '硬删除'
         WHEN m.del_flag = 1 THEN '软删除'
    END              AS 孤儿原因,
    i.update_time     AS 最后变动
FROM c_mes_inventory i
LEFT JOIN c_mes_material m ON i.material_id = m.id
WHERE (m.id IS NULL OR m.del_flag = 1)
  AND i.current_qty = 0
ORDER BY i.update_time DESC
LIMIT 100;  -- 仅展示前 100 行


SELECT '=== Q5. 待清理行数预估 ===' AS step;

-- Q5: 清理预估（按 qty 分组，方便业务判断）
SELECT
    CASE
        WHEN i.current_qty > 0 THEN '需要业务确认（高风险）'
        ELSE '可直接清理（低风险）'
    END AS 清理策略,
    COUNT(*) AS 待处理行数
FROM c_mes_inventory i
LEFT JOIN c_mes_material m ON i.material_id = m.id
WHERE m.id IS NULL OR m.del_flag = 1
GROUP BY 清理策略;
