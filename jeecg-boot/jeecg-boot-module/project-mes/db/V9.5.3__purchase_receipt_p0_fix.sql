-- V9.5.3 — 采购收货 P0 修复（铁拳团审计 + orca-review 外部评审吸纳）
-- 1) c_mes_purchase_order_item 增加 received_qty(累计入库量)，支持原子扣减防超收
-- 2) 历史数据回填（已审核入库单的 SUM(receipt_quantity)）

-- 1) 加列
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_order_item' AND column_name = 'received_qty');
SET @sql = IF(@col_exists = 0, 'ALTER TABLE c_mes_purchase_order_item ADD COLUMN received_qty DECIMAL(18,4) DEFAULT 0 COMMENT ''累计入库量(原子扣减防超收)'' AFTER quantity', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2) 历史回填：从已审核(status='2')的入库单行聚合 SUM(receipt_quantity) → 写入订单行 received_qty
UPDATE c_mes_purchase_order_item poi
SET poi.received_qty = COALESCE((
  SELECT SUM(pri.receipt_quantity)
  FROM c_mes_purchase_receipt_item pri
  JOIN c_mes_purchase_receipt pr ON pr.id = pri.receipt_id AND pr.del_flag = 0
  WHERE pr.status = '2'
    AND pr.purchase_order_id = poi.order_id
    AND pri.material_id = poi.material_id
), 0)
WHERE EXISTS (
  SELECT 1 FROM c_mes_purchase_receipt pr2
  JOIN c_mes_purchase_receipt_item pri2 ON pri2.receipt_id = pr2.id
  WHERE pr2.status = '2' AND pr2.purchase_order_id = poi.order_id AND pri2.material_id = poi.material_id
);
