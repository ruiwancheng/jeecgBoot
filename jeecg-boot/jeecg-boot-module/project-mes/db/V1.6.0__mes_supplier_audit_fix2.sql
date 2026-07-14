-- MES 供应商审计修复 V1.6.0
-- 1. status 字段默认值从中文文本'潜在'改为字典编码'1'
-- 2. 补充 V1.4.0 建表 SQL 中 status 默认值的在线修正

-- ============================================================
-- 一、status 默认值修复
-- ============================================================
ALTER TABLE c_mes_supplier MODIFY COLUMN status VARCHAR(20) DEFAULT '1' COMMENT '供应商状态(dict:mes_supplier_status)';
