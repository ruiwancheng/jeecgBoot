-- ============================================================
-- MES 金额精度修复 V10.1.4
-- 背景：B2 · other-stock-in 后端精度丢失（P1 主流程）
-- 症状：totalAmount 计算时 4 位小数被强制截断为 2 位，财务核算精度丢失
-- 根因：5 处 service 文件 .setScale(2, HALF_UP) 强制截断；DB 字段精度也是 18,2
-- 修复：
--   1. DB 字段精度 18,2 → 18,4
--   2. 5 处 setScale(2 → 4) 同步修改
-- 可重复执行（使用条件判断，幂等）
-- ============================================================

-- 1. c_mes_other_stock_in_item.amount
ALTER TABLE c_mes_other_stock_in_item
  MODIFY COLUMN amount DECIMAL(18,4) DEFAULT 0.0000 COMMENT '金额(qty*unit_cost)';

-- 2. c_mes_other_stock_out_item.amount
ALTER TABLE c_mes_other_stock_out_item
  MODIFY COLUMN amount DECIMAL(18,4) DEFAULT 0.0000 COMMENT '金额(qty*unit_cost)';

-- 3. c_mes_stocktake_item.diff_amount
ALTER TABLE c_mes_stocktake_item
  MODIFY COLUMN diff_amount DECIMAL(18,4) DEFAULT 0.0000 COMMENT '差异金额(diff_qty*unit_cost)';
