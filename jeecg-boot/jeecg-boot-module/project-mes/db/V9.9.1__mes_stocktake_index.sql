-- V9.9.1 盘点单铁拳团P1-2修复：create_time 索引（MySQL 5.7 兼容，幂等）
SET @idx := (SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema = DATABASE() AND table_name = 'c_mes_stocktake' AND index_name = 'idx_stocktake_create_time');
SET @sql := IF(@idx = 0, 'ALTER TABLE c_mes_stocktake ADD INDEX idx_stocktake_create_time (create_time)', 'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
