-- ============================================================
-- V10.0.2  批次相关表初始化（Docker 数据库未执行 V0.0.0 初始化脚本）
-- 作者: ruiwancheng  日期: 2026-08-06
-- ============================================================

-- 1) 批次主档 c_mes_batch
CREATE TABLE IF NOT EXISTS `c_mes_batch` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `batch_no` varchar(50) NOT NULL COMMENT '批次号(手工录入，不同物料可重号)',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `origin_type` varchar(20) NOT NULL COMMENT '来源类型(dict:mes_batch_origin_type)',
  `origin_bill_id` varchar(32) DEFAULT NULL COMMENT '来源单据ID',
  `origin_bill_no` varchar(50) DEFAULT NULL COMMENT '来源单据号',
  `qty` decimal(18,4) NOT NULL DEFAULT '0.0000' COMMENT '批次初始数量',
  `production_date` date DEFAULT NULL COMMENT '生产日期',
  `shelf_life` int DEFAULT NULL COMMENT '保质期(天)',
  `expiry_date` date DEFAULT NULL COMMENT '有效期至',
  `unit_cost` decimal(18,4) DEFAULT '0.0000' COMMENT '批次单位成本',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_batch_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_batch_material_no_del` (`material_id`,`batch_no`,`del_flag`),
  KEY `idx_batch_material` (`material_id`),
  KEY `idx_batch_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-批次主档';

-- 2) 批次库存 c_mes_batch_inventory
CREATE TABLE IF NOT EXISTS `c_mes_batch_inventory` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `batch_id` varchar(32) NOT NULL COMMENT '批次ID',
  `warehouse_id` varchar(32) NOT NULL COMMENT '仓库ID',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `batch_no` varchar(50) DEFAULT NULL COMMENT '批次号(冗余)',
  `qty` decimal(18,4) NOT NULL DEFAULT '0.0000' COMMENT '可用数量',
  `frozen_qty` decimal(18,4) NOT NULL DEFAULT '0.0000' COMMENT '冻结数量',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_bi_batch_warehouse` (`batch_id`,`warehouse_id`,`del_flag`),
  KEY `idx_bi_batch` (`batch_id`),
  KEY `idx_bi_warehouse` (`warehouse_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-批次库存';

-- 3) 批次台账 c_mes_batch_ledger
CREATE TABLE IF NOT EXISTS `c_mes_batch_ledger` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `batch_id` varchar(32) NOT NULL COMMENT '批次ID',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `warehouse_id` varchar(32) NOT NULL COMMENT '仓库ID',
  `batch_no` varchar(50) DEFAULT NULL COMMENT '批次号(冗余)',
  `source_bill_type` varchar(50) DEFAULT NULL COMMENT '来源单据类型',
  `source_bill_id` varchar(32) DEFAULT NULL COMMENT '来源单据ID',
  `source_bill_no` varchar(50) DEFAULT NULL COMMENT '来源单据号',
  `in_qty` decimal(18,4) NOT NULL DEFAULT '0.0000' COMMENT '入库数量',
  `out_qty` decimal(18,4) NOT NULL DEFAULT '0.0000' COMMENT '出库数量',
  `remain_qty` decimal(18,4) NOT NULL DEFAULT '0.0000' COMMENT '剩余数量',
  `unit_cost` decimal(18,4) DEFAULT '0.0000' COMMENT '单位成本',
  `record_date` datetime DEFAULT NULL COMMENT '记录时间',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_bl_batch` (`batch_id`),
  KEY `idx_bl_material` (`material_id`),
  KEY `idx_bl_bill` (`source_bill_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-批次台账';
