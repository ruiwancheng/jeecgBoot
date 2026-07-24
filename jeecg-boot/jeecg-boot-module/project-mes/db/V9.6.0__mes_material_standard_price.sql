-- MES 物料标准售价 V9.6.0
-- ALTER: c_mes_material 新增 standard_price 列
-- 轻量化价格体系 MVP — 物料直接维护标准售价，销售订单选物料自动带出

-- MySQL 5.7 兼容：存储过程判断列是否存在
DROP PROCEDURE IF EXISTS add_standard_price_if_missing;
DELIMITER //
CREATE PROCEDURE add_standard_price_if_missing()
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'c_mes_material'
          AND COLUMN_NAME = 'standard_price'
    ) THEN
        ALTER TABLE c_mes_material ADD COLUMN standard_price DECIMAL(18,2) DEFAULT NULL COMMENT '标准售价';
    END IF;
END //
DELIMITER ;
CALL add_standard_price_if_missing();
DROP PROCEDURE IF EXISTS add_standard_price_if_missing;
