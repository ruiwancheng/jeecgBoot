-- MES 采购申请明细加单价/金额字段 V9.5.5
-- ALTER TABLE: c_mes_purchase_apply_item 新增单价和金额列
ALTER TABLE c_mes_purchase_apply_item
    ADD COLUMN unit_price DECIMAL(18,2) COMMENT '单价',
    ADD COLUMN amount     DECIMAL(18,2) COMMENT '金额';
