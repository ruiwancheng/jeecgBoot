-- V9.9.2 库存台账增加备注列（提升可读性：盘点/手工原因可见）
ALTER TABLE c_mes_inventory_ledger ADD COLUMN remark VARCHAR(500) NULL COMMENT '备注(单据原因,如: 盘点单 PD-xxx 自动生成)' AFTER biz_id;
