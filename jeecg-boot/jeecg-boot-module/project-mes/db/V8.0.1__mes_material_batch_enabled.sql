-- MES 物料启用批次管理 V8.0.1
-- material 表加 batch_enabled 字段，标识该物料是否启用批次管理

ALTER TABLE c_mes_material
    ADD COLUMN batch_enabled INT DEFAULT 0 COMMENT '是否启用批次管理(0否/1是,默认0)';
