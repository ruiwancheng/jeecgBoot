-- MES 审计修复 V1.2.0
-- P0-005: 业务唯一索引统一包含 del_flag，防止软删除记录占用唯一索引
-- MySQL 5.7 不支持 DROP INDEX IF EXISTS，改用先建后删策略

-- 仓库表：重建唯一索引（含 del_flag）
ALTER TABLE c_mes_warehouse DROP INDEX uk_code;
ALTER TABLE c_mes_warehouse ADD UNIQUE INDEX uk_mes_wh_code_del (code, del_flag);

-- 库区表：重建唯一索引（含 del_flag）
ALTER TABLE c_mes_zone DROP INDEX uk_mes_zone_wh_code;
ALTER TABLE c_mes_zone ADD UNIQUE INDEX uk_mes_zone_wh_code_del (warehouse_id, code, del_flag);

-- 货架表：重建唯一索引（含 del_flag）
ALTER TABLE c_mes_shelf DROP INDEX uk_mes_shelf_zone_code;
ALTER TABLE c_mes_shelf ADD UNIQUE INDEX uk_mes_shelf_zone_code_del (zone_id, code, del_flag);

-- 库位表：删除旧索引，新增业务维度正确的唯一索引（含 del_flag）
ALTER TABLE c_mes_location DROP INDEX uk_mes_loc_wh_code;
ALTER TABLE c_mes_location ADD UNIQUE INDEX uk_mes_loc_shelf_code_del (shelf_id, code, del_flag);
