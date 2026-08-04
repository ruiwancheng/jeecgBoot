-- V0.0.0  MES 业务模块 初始建表 SQL
-- 由 2026-08-04 CI 首次跑测发现 V0.x 缺失后用 mysqldump 导出（schema only, no data）
-- 共 54 张 c_mes_* 表
-- update-begin---author:pi---date:2026-08-04---for:[CI fix] V0.0.0 initial schema (CI 之前找不到 c_mes_* 基础表)-----------
DROP TABLE IF EXISTS `c_mes_account_subject`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_account_subject` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '科目编码',
  `name` varchar(100) NOT NULL COMMENT '科目名称',
  `category` varchar(20) NOT NULL COMMENT '科目类别(dict:mes_subject_category)',
  `level` int DEFAULT '1' COMMENT '科目级别',
  `parent_id` varchar(32) DEFAULT NULL COMMENT '上级科目ID',
  `balance_direction` varchar(10) DEFAULT '1' COMMENT '余额方向(dict:mes_balance_direction)',
  `status` varchar(20) DEFAULT '1' COMMENT '状态 1启用 0停用',
  `is_leaf` int DEFAULT '1' COMMENT '是否叶子科目 1是 0否',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_subject_code_del` (`code`,`del_flag`),
  KEY `idx_subject_parent` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-会计科目';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_batch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_batch` (
  `id` varchar(32) NOT NULL COMMENT '涓婚敭',
  `batch_no` varchar(50) NOT NULL COMMENT '批次号(手工录入，不同物料可重号)',
  `material_id` varchar(32) NOT NULL COMMENT '鐗╂枡ID',
  `origin_type` varchar(20) NOT NULL COMMENT '鏉ユ簮绫诲瀷(dict:mes_batch_origin_type)',
  `origin_bill_id` varchar(32) DEFAULT NULL COMMENT '鏉ユ簮鍗曟嵁ID',
  `origin_bill_no` varchar(50) DEFAULT NULL COMMENT '鏉ユ簮鍗曟嵁鍙',
  `qty` decimal(18,4) NOT NULL DEFAULT '0.0000' COMMENT '鍒濆?鎵规?鏁伴噺',
  `production_date` date DEFAULT NULL COMMENT '鐢熶骇鏃ユ湡',
  `shelf_life` int DEFAULT NULL COMMENT '保质期(天)',
  `expiry_date` date DEFAULT NULL COMMENT '鏈夋晥鏈?鍙?┖)',
  `unit_cost` decimal(18,4) DEFAULT '0.0000' COMMENT '鎵规?鍗曚綅鎴愭湰(閲囪喘浠?鍔犳潈骞冲潎鎴愭湰)',
  `status` varchar(20) DEFAULT '1' COMMENT '鐘舵?(dict:mes_batch_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '澶囨敞',
  `create_by` varchar(50) DEFAULT NULL COMMENT '鍒涘缓浜',
  `create_time` datetime DEFAULT NULL COMMENT '鍒涘缓鏃堕棿',
  `update_by` varchar(50) DEFAULT NULL COMMENT '鏇存柊浜',
  `update_time` datetime DEFAULT NULL COMMENT '鏇存柊鏃堕棿',
  `del_flag` int DEFAULT '0' COMMENT '鍒犻櫎鏍囪?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_batch_material_no_del` (`material_id`,`batch_no`,`del_flag`),
  KEY `idx_batch_material` (`material_id`),
  KEY `idx_batch_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-鎵规?涓绘。';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_batch_inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_batch_inventory` (
  `id` varchar(32) NOT NULL COMMENT '涓婚敭',
  `batch_id` varchar(32) NOT NULL COMMENT '鎵规?ID',
  `batch_no` varchar(50) NOT NULL COMMENT '鎵规?鍙?鍐椾綑)',
  `material_id` varchar(32) NOT NULL COMMENT '鐗╂枡ID',
  `warehouse_id` varchar(32) NOT NULL COMMENT '浠撳簱ID',
  `qty` decimal(18,4) NOT NULL DEFAULT '0.0000' COMMENT '褰撳墠鏁伴噺',
  `unit_cost` decimal(18,4) DEFAULT '0.0000' COMMENT '鎵规?鍗曚綅鎴愭湰(鍐椾綑渚夸簬鍑哄簱鍙栧?)',
  `create_by` varchar(50) DEFAULT NULL COMMENT '鍒涘缓浜',
  `create_time` datetime DEFAULT NULL COMMENT '鍒涘缓鏃堕棿',
  `update_by` varchar(50) DEFAULT NULL COMMENT '鏇存柊浜',
  `update_time` datetime DEFAULT NULL COMMENT '鏇存柊鏃堕棿',
  `del_flag` int DEFAULT '0' COMMENT '鍒犻櫎鏍囪?',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_batch_warehouse` (`batch_id`,`warehouse_id`,`del_flag`),
  KEY `idx_bi_batch` (`batch_id`),
  KEY `idx_bi_material_warehouse` (`material_id`,`warehouse_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-鎵规?搴撳瓨';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_batch_ledger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_batch_ledger` (
  `id` varchar(32) NOT NULL COMMENT '涓婚敭',
  `batch_id` varchar(32) NOT NULL COMMENT '鎵规?ID',
  `batch_no` varchar(50) NOT NULL COMMENT '鎵规?鍙?鍐椾綑)',
  `material_id` varchar(32) NOT NULL COMMENT '鐗╂枡ID',
  `warehouse_id` varchar(32) DEFAULT NULL COMMENT '仓库ID(批次创建时可空)',
  `biz_type` varchar(20) NOT NULL COMMENT '涓氬姟绫诲瀷(閲囪喘鍏ュ簱/鐢熶骇鍏ュ簱/棰嗘枡/閿?敭鍑哄簱)',
  `biz_id` varchar(32) DEFAULT NULL COMMENT '涓氬姟鍗曟嵁ID',
  `biz_no` varchar(50) DEFAULT NULL COMMENT '涓氬姟鍗曟嵁鍙',
  `in_qty` decimal(18,4) DEFAULT '0.0000' COMMENT '鍏ュ簱鏁伴噺',
  `out_qty` decimal(18,4) DEFAULT '0.0000' COMMENT '鍑哄簱鏁伴噺',
  `unit_cost` decimal(18,4) DEFAULT '0.0000' COMMENT '鎵规?鍗曚綅鎴愭湰',
  `occur_time` datetime DEFAULT NULL COMMENT '鍙戠敓鏃堕棿',
  `remark` varchar(500) DEFAULT NULL COMMENT '澶囨敞',
  `create_by` varchar(50) DEFAULT NULL COMMENT '鍒涘缓浜',
  `create_time` datetime DEFAULT NULL COMMENT '鍒涘缓鏃堕棿',
  `del_flag` int DEFAULT '0' COMMENT '鍒犻櫎鏍囪?',
  PRIMARY KEY (`id`),
  KEY `idx_bl_batch` (`batch_id`),
  KEY `idx_bl_biz` (`biz_type`,`biz_id`),
  KEY `idx_bl_occur_time` (`occur_time`),
  KEY `idx_bl_batch_del` (`batch_id`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-鎵规?娴佹按';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_bom`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_bom` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT 'BOM编号',
  `product_id` varchar(32) NOT NULL COMMENT '父项物料ID',
  `version` varchar(20) DEFAULT 'V1.0' COMMENT '版本号',
  `effective_date` datetime DEFAULT NULL COMMENT '生效日期',
  `expiry_date` datetime DEFAULT NULL COMMENT '失效日期',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_bom_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_bom_product_version` (`product_id`,`version`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-BOM';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_bom_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_bom_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `bom_id` varchar(32) NOT NULL COMMENT 'BOM ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `material_id` varchar(32) NOT NULL COMMENT '子项物料ID',
  `quantity` decimal(18,4) DEFAULT NULL COMMENT '用量',
  `loss_rate` decimal(5,2) DEFAULT NULL COMMENT '损耗率(%)',
  `is_substitute` varchar(1) DEFAULT '0' COMMENT '是否替代料(yn)',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_item_bom_id` (`bom_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-BOM子项';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_code_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_code_rule` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `rule_code` varchar(30) NOT NULL COMMENT '规则编码(唯一,如SO/PO/MO)',
  `rule_name` varchar(50) NOT NULL COMMENT '规则名称',
  `prefix` varchar(20) NOT NULL COMMENT '前缀',
  `date_format` varchar(20) DEFAULT 'yyyyMMdd' COMMENT '日期格式(java SimpleDateFormat)',
  `seq_length` int DEFAULT '4' COMMENT '流水号位数',
  `reset_cycle` varchar(10) DEFAULT 'DAILY' COMMENT '重置周期: NONE/DAILY/MONTHLY/YEARLY',
  `current_seq` int DEFAULT '0' COMMENT '当前流水号',
  `current_date` varchar(10) DEFAULT NULL COMMENT '当前日期(用于判断重置)',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `biz_type` varchar(30) DEFAULT NULL COMMENT '适用单据(字典 mes_code_biz_type)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code_rule_code` (`rule_code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES编码规则';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_collection`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_collection` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '收款单号',
  `customer_id` varchar(32) NOT NULL COMMENT '客户ID',
  `receivable_id` varchar(32) DEFAULT NULL COMMENT '关联应收单ID',
  `amount` decimal(18,2) NOT NULL COMMENT '收款金额',
  `collection_date` datetime DEFAULT NULL COMMENT '收款日期',
  `payment_method` varchar(20) DEFAULT '1' COMMENT '收款方式(dict:mes_payment_method)',
  `status` varchar(20) DEFAULT '1' COMMENT '状态 1已收款 0已作废',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_col_code_del` (`code`,`del_flag`),
  KEY `idx_col_customer` (`customer_id`),
  KEY `idx_col_receivable` (`receivable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-收款单';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_completion_receipt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_completion_receipt` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '入库单号',
  `production_order_id` varchar(32) NOT NULL COMMENT '生产订单ID',
  `product_id` varchar(32) DEFAULT NULL COMMENT '产品物料ID',
  `warehouse_id` varchar(32) DEFAULT NULL COMMENT '入库仓库ID',
  `receipt_date` datetime DEFAULT NULL COMMENT '入库日期',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_completion_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_completion_code` (`code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-完工入库';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_completion_receipt_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_completion_receipt_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `receipt_id` varchar(32) NOT NULL COMMENT '入库单ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `material_id` varchar(32) NOT NULL COMMENT '产品物料ID',
  `plan_qty` decimal(18,4) DEFAULT NULL COMMENT '计划数量',
  `receipt_qty` decimal(18,4) DEFAULT NULL COMMENT '本次入库数量',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `batch_no` varchar(50) DEFAULT NULL COMMENT '生产批次号(手工录入)',
  `production_date` date DEFAULT NULL COMMENT '生产日期',
  PRIMARY KEY (`id`),
  KEY `idx_item_completion_id` (`receipt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-完工入库行';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_cost_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_cost_log` (
  `id` varchar(32) NOT NULL COMMENT 'ID',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `warehouse_id` varchar(32) DEFAULT NULL COMMENT '仓库ID',
  `biz_type` varchar(50) NOT NULL COMMENT '业务类型(采购入库/采购退货/完工入库/成本调整)',
  `biz_id` varchar(100) NOT NULL COMMENT '业务单号',
  `qty` decimal(18,2) NOT NULL COMMENT '变动数量(+入库/-出库)',
  `unit_cost` decimal(18,4) NOT NULL COMMENT '本次单位成本',
  `amount` decimal(18,2) NOT NULL COMMENT '本次金额',
  `cost_before` decimal(18,4) NOT NULL COMMENT '变动前移动平均成本',
  `cost_after` decimal(18,4) NOT NULL COMMENT '变动后移动平均成本',
  `qty_before` decimal(18,2) NOT NULL COMMENT '变动前库存总数量',
  `qty_after` decimal(18,2) NOT NULL COMMENT '变动后库存总数量',
  `create_by` varchar(50) DEFAULT NULL COMMENT '操作人',
  `create_time` datetime DEFAULT NULL COMMENT '操作时间',
  PRIMARY KEY (`id`),
  KEY `idx_cost_log_material` (`material_id`),
  KEY `idx_cost_log_biz` (`biz_id`),
  KEY `idx_cost_log_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-成本变动日志';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_customer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_customer` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '客户编码',
  `name` varchar(100) NOT NULL COMMENT '客户名称',
  `type` varchar(50) DEFAULT NULL COMMENT '客户类型',
  `grade` varchar(50) DEFAULT NULL COMMENT '瀹㈡埛绛夌骇',
  `credit_limit` decimal(18,4) DEFAULT '0.0000' COMMENT '淇＄敤棰濆害',
  `salesman_id` varchar(32) DEFAULT NULL COMMENT '閿?敭鍛業D',
  `industry` varchar(50) DEFAULT NULL COMMENT '琛屼笟',
  `region` varchar(50) DEFAULT NULL COMMENT '鍦板尯',
  `scale` varchar(50) DEFAULT NULL COMMENT '瑙勬ā',
  `contact` varchar(50) DEFAULT NULL COMMENT '联系人',
  `phone` varchar(20) DEFAULT NULL COMMENT '联系电话',
  `address` varchar(255) DEFAULT NULL COMMENT '地址',
  `status` int DEFAULT '1' COMMENT '状态 1启用 0停用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `invoice_title` varchar(200) DEFAULT NULL COMMENT '鍙戠エ鎶?ご',
  `tax_no` varchar(50) DEFAULT NULL COMMENT '绋庡彿',
  `bank_name` varchar(100) DEFAULT NULL COMMENT '寮?埛閾惰?',
  `bank_account` varchar(50) DEFAULT NULL COMMENT '閾惰?璐﹀彿',
  `invoice_address` varchar(300) DEFAULT NULL COMMENT '寮?エ鍦板潃',
  `invoice_phone` varchar(30) DEFAULT NULL COMMENT '寮?エ鐢佃瘽',
  `invoice_type` varchar(10) DEFAULT NULL COMMENT '鍙戠エ绫诲瀷(dict:invoice_type)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_mes_customer_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-客户表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_customer_address`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_customer_address` (
  `id` varchar(36) NOT NULL COMMENT '主键',
  `customer_id` varchar(36) NOT NULL COMMENT '客户ID',
  `address_type` varchar(20) DEFAULT NULL COMMENT '地址类型(dict:address_type)',
  `contact` varchar(50) DEFAULT NULL COMMENT '联系人',
  `phone` varchar(20) DEFAULT NULL COMMENT '联系电话',
  `province` varchar(50) DEFAULT NULL COMMENT '省',
  `city` varchar(50) DEFAULT NULL COMMENT '市',
  `district` varchar(50) DEFAULT NULL COMMENT '区',
  `detail` varchar(300) DEFAULT NULL COMMENT '详细地址',
  `is_default` tinyint(1) DEFAULT '0' COMMENT '是否默认',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_address_customer_id` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-客户地址';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_customer_contact`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_customer_contact` (
  `id` varchar(36) NOT NULL COMMENT '主键',
  `customer_id` varchar(36) NOT NULL COMMENT '客户ID',
  `name` varchar(50) DEFAULT NULL COMMENT '姓名',
  `title` varchar(50) DEFAULT NULL COMMENT '职务',
  `phone` varchar(20) DEFAULT NULL COMMENT '手机',
  `email` varchar(100) DEFAULT NULL COMMENT '邮箱',
  `social` varchar(100) DEFAULT NULL COMMENT 'QQ/微信',
  `is_default` tinyint(1) DEFAULT '0' COMMENT '是否默认',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_contact_customer_id` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-客户联系人';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_customer_follow_up`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_customer_follow_up` (
  `id` varchar(36) NOT NULL COMMENT '主键',
  `customer_id` varchar(36) NOT NULL COMMENT '客户ID',
  `follow_type` varchar(20) DEFAULT NULL COMMENT '跟进方式(dict:follow_type)',
  `follow_date` datetime DEFAULT NULL COMMENT '跟进日期',
  `content` text COMMENT '跟进内容',
  `follower` varchar(36) DEFAULT NULL COMMENT '跟进人(sys_user.id)',
  `next_date` datetime DEFAULT NULL COMMENT '下次跟进日期',
  `attachment` varchar(500) DEFAULT NULL COMMENT '附件路径',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_followup_customer_id` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-客户跟进记录';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_customer_price`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_customer_price` (
  `id` varchar(36) NOT NULL COMMENT '主键',
  `customer_id` varchar(36) NOT NULL COMMENT '客户ID',
  `product_id` varchar(36) DEFAULT NULL COMMENT '产品ID',
  `price` decimal(18,2) DEFAULT NULL COMMENT '协议单价',
  `begin_date` datetime DEFAULT NULL COMMENT '生效日期（预留）',
  `end_date` datetime DEFAULT NULL COMMENT '失效日期（预留）',
  `min_qty` decimal(18,2) DEFAULT NULL COMMENT '起订数量（预留）',
  `max_qty` decimal(18,2) DEFAULT NULL COMMENT '截止数量（预留）',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  KEY `idx_price_customer_id` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-客户价格表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_delivery_note`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_delivery_note` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '发货单编码',
  `sales_order_id` varchar(32) NOT NULL COMMENT '关联销售订单ID',
  `warehouse_id` varchar(32) NOT NULL COMMENT '发货仓库ID',
  `customer_id` varchar(32) DEFAULT NULL COMMENT '客户ID(冗余)',
  `delivery_date` datetime DEFAULT NULL COMMENT '发货日期',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_delivery_status)',
  `logistics_company` varchar(100) DEFAULT NULL COMMENT '物流公司',
  `tracking_no` varchar(100) DEFAULT NULL COMMENT '运单号',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `total_amount` decimal(18,2) DEFAULT NULL COMMENT '总金额',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_delivery_code_del` (`code`,`del_flag`),
  KEY `idx_delivery_order_id` (`sales_order_id`),
  KEY `idx_delivery_warehouse_id` (`warehouse_id`),
  KEY `idx_delivery_ctime` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-发货单';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_delivery_note_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_delivery_note_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `delivery_id` varchar(32) NOT NULL COMMENT '发货单ID',
  `sales_order_item_id` varchar(32) DEFAULT NULL COMMENT '关联订单明细ID',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `ordered_qty` decimal(18,4) DEFAULT NULL COMMENT '订单数量',
  `delivery_qty` decimal(18,4) DEFAULT NULL COMMENT '本次发货数量',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `unit_price` decimal(18,2) DEFAULT NULL COMMENT '单价',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '金额',
  PRIMARY KEY (`id`),
  KEY `idx_de_item_delivery_id` (`delivery_id`),
  KEY `idx_de_item_material_id` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-发货单明细';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_global_switch`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_global_switch` (
  `id` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '涓婚敭',
  `switch_key` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '寮?叧鏍囪瘑',
  `switch_value` int NOT NULL DEFAULT '0' COMMENT '寮?叧鍊?0鍏?1寮?',
  `switch_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '寮?叧鍚嶇О',
  `description` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '寮?叧鎻忚堪',
  `create_by` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(32) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_switch_key` (`switch_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MES鍏ㄥ眬寮?叧琛';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_inventory`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_inventory` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `warehouse_id` varchar(32) NOT NULL COMMENT '仓库ID',
  `current_qty` decimal(18,4) DEFAULT '0.0000' COMMENT '当前库存数量',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_inv_material_wh` (`material_id`,`warehouse_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-库存快照';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_inventory_ledger`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_inventory_ledger` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `warehouse_id` varchar(32) NOT NULL COMMENT '仓库ID',
  `beginning_qty` decimal(18,4) DEFAULT NULL COMMENT '期初数量',
  `in_qty` decimal(18,4) DEFAULT NULL COMMENT '本期入库',
  `out_qty` decimal(18,4) DEFAULT NULL COMMENT '本期出库',
  `ending_qty` decimal(18,4) DEFAULT NULL COMMENT '期末数量',
  `record_date` datetime DEFAULT NULL COMMENT '记录日期',
  `biz_type` varchar(50) DEFAULT NULL COMMENT '业务类型(采购入库/销售出库/生产领料/完工入库)',
  `biz_id` varchar(32) DEFAULT NULL COMMENT '业务单号',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注(单据原因,如: 盘点单 PD-xxx 自动生成)',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `unit_cost` decimal(18,4) DEFAULT NULL COMMENT '单位成本',
  `in_amount` decimal(18,2) DEFAULT NULL COMMENT '入库金额',
  `out_amount` decimal(18,2) DEFAULT NULL COMMENT '出库金额',
  `beginning_amount` decimal(18,2) DEFAULT '0.00' COMMENT '期初金额',
  `ending_amount` decimal(18,2) DEFAULT '0.00' COMMENT '期末金额',
  PRIMARY KEY (`id`),
  KEY `idx_ledger_material` (`material_id`),
  KEY `idx_ledger_warehouse` (`warehouse_id`),
  KEY `idx_ledger_date` (`record_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-库存台账';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_location` (
  `id` varchar(36) NOT NULL COMMENT '主键',
  `warehouse_id` varchar(36) DEFAULT NULL COMMENT '所属仓库ID',
  `zone_id` varchar(36) DEFAULT NULL COMMENT '所属库区ID',
  `shelf_id` varchar(36) DEFAULT NULL COMMENT '所属货架ID',
  `code` varchar(100) NOT NULL COMMENT '库位编码',
  `name` varchar(100) DEFAULT NULL COMMENT '库位名称',
  `type` varchar(50) DEFAULT NULL COMMENT '库位类型',
  `area` varchar(50) DEFAULT NULL COMMENT '区域',
  `passage_row` int DEFAULT NULL COMMENT '通道行数',
  `passage_col` int DEFAULT NULL COMMENT '通道列数',
  `shelf_row` int DEFAULT NULL COMMENT '货架行数',
  `shelf_col` int DEFAULT NULL COMMENT '货架列数',
  `max_capacity` decimal(10,2) DEFAULT NULL COMMENT '最大容量',
  `load_capacity` decimal(10,2) DEFAULT NULL COMMENT '承重(kg)',
  `storage_limit` varchar(255) DEFAULT NULL COMMENT '存放物料限制',
  `length` decimal(10,2) DEFAULT NULL COMMENT '长(cm)',
  `width` decimal(10,2) DEFAULT NULL COMMENT '宽(cm)',
  `height` decimal(10,2) DEFAULT NULL COMMENT '高(cm)',
  `factory` varchar(100) DEFAULT NULL COMMENT '所属工厂',
  `workshop` varchar(100) DEFAULT NULL COMMENT '所属车间',
  `status` int DEFAULT '1' COMMENT '状态 1启用 0停用',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_mes_loc_shelf_code_del` (`shelf_id`,`code`,`del_flag`),
  KEY `idx_mes_loc_zone` (`zone_id`),
  KEY `idx_mes_loc_shelf` (`shelf_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-库位表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_material`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_material` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '物料编码',
  `name` varchar(100) NOT NULL COMMENT '物料名称',
  `type` varchar(20) DEFAULT NULL COMMENT '物料类型(dict:mes_material_type)',
  `spec` varchar(100) DEFAULT NULL COMMENT '规格型号',
  `unit` varchar(20) DEFAULT NULL COMMENT '单位(dict:mes_material_unit)',
  `status` varchar(20) DEFAULT '1' COMMENT '状态 1启用 0停用',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `safety_stock` decimal(18,4) DEFAULT NULL COMMENT '安全库存',
  `max_stock` decimal(18,4) DEFAULT NULL COMMENT '最高库存',
  `standard_price` decimal(18,2) DEFAULT NULL COMMENT '标准售价',
  `moving_avg_cost` decimal(18,4) DEFAULT '0.0000' COMMENT '移动平均成本',
  `last_purchase_price` decimal(18,4) DEFAULT NULL COMMENT '最近采购价(含税)',
  `last_purchase_date` datetime DEFAULT NULL COMMENT '最近采购日期',
  `batch_enabled` int DEFAULT '0' COMMENT '是否启用批次管理(0否/1是,默认0)',
  `shelf_life` int DEFAULT NULL COMMENT '保质期(天)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_material_code_del` (`code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-物料';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_other_stock_in`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_other_stock_in` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '入库单号',
  `in_type` varchar(20) DEFAULT NULL COMMENT '入库类型(dict:mes_other_stock_in_type)',
  `warehouse_id` varchar(32) DEFAULT NULL COMMENT '仓库ID(单据级,单仓单)',
  `reason` varchar(500) DEFAULT NULL COMMENT '原因(手工填)',
  `stock_date` datetime DEFAULT NULL COMMENT '出入库日期',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_other_stock_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `total_amount` decimal(18,2) DEFAULT '0.00' COMMENT '总金额',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_other_stock_in_code_del` (`code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-其它入库';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_other_stock_in_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_other_stock_in_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `in_id` varchar(32) NOT NULL COMMENT '入库单ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `qty` decimal(18,4) NOT NULL COMMENT '数量',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `unit_cost` decimal(18,4) DEFAULT '0.0000' COMMENT '成本单价(手工录入,审核快照)',
  `amount` decimal(18,2) DEFAULT '0.00' COMMENT '金额(qty*unit_cost)',
  PRIMARY KEY (`id`),
  KEY `idx_item_in_id` (`in_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-其它入库行';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_other_stock_out`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_other_stock_out` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '出库单号',
  `out_type` varchar(20) DEFAULT NULL COMMENT '出库类型(dict:mes_other_stock_out_type)',
  `warehouse_id` varchar(32) DEFAULT NULL COMMENT '仓库ID(单据级,单仓单)',
  `reason` varchar(500) DEFAULT NULL COMMENT '原因(手工填)',
  `stock_date` datetime DEFAULT NULL COMMENT '出入库日期',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_other_stock_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `total_amount` decimal(18,2) DEFAULT '0.00' COMMENT '总金额',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_other_stock_out_code_del` (`code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-其它出库';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_other_stock_out_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_other_stock_out_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `out_id` varchar(32) NOT NULL COMMENT '出库单ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `qty` decimal(18,4) NOT NULL COMMENT '数量',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `unit_cost` decimal(18,4) DEFAULT '0.0000' COMMENT '成本单价(手工录入,审核快照)',
  `amount` decimal(18,2) DEFAULT '0.00' COMMENT '金额(qty*unit_cost)',
  PRIMARY KEY (`id`),
  KEY `idx_item_out_id` (`out_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-其它出库行';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_payable`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_payable` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '应付单号',
  `supplier_id` varchar(32) NOT NULL COMMENT '供应商ID',
  `source_type` varchar(50) DEFAULT NULL COMMENT '来源类型(采购入库)',
  `source_bill_id` varchar(32) DEFAULT NULL COMMENT '来源单据ID',
  `source_bill_no` varchar(50) DEFAULT NULL COMMENT '来源单据号',
  `amount` decimal(18,2) NOT NULL COMMENT '应付金额',
  `paid_amount` decimal(18,2) DEFAULT '0.00' COMMENT '已付金额',
  `unsettled_amount` decimal(18,2) DEFAULT NULL COMMENT '未付金额',
  `credit_period` int DEFAULT '30' COMMENT '账期(天)',
  `due_date` datetime DEFAULT NULL COMMENT '到期日',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_payable_status)',
  `settlement_date` datetime DEFAULT NULL COMMENT '结清日期',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `tax_amount` decimal(18,2) DEFAULT NULL COMMENT '税额',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pay_code_del` (`code`,`del_flag`),
  UNIQUE KEY `uk_pay_source_bill` (`source_bill_id`,`del_flag`),
  KEY `idx_pay_supplier` (`supplier_id`),
  KEY `idx_pay_due_date` (`due_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-应付单';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_payment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_payment` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '付款单号',
  `supplier_id` varchar(32) NOT NULL COMMENT '供应商ID',
  `payable_id` varchar(32) DEFAULT NULL COMMENT '关联应付单ID',
  `amount` decimal(18,2) NOT NULL COMMENT '付款金额',
  `payment_date` datetime DEFAULT NULL COMMENT '付款日期',
  `payment_method` varchar(20) DEFAULT '1' COMMENT '付款方式(dict:mes_payment_method)',
  `status` varchar(20) DEFAULT '1' COMMENT '状态 1已付款 0已作废',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pmt_code_del` (`code`,`del_flag`),
  KEY `idx_pmt_supplier` (`supplier_id`),
  KEY `idx_pmt_payable` (`payable_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-付款单';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_price`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_price` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '价格编码',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `customer_id` varchar(32) DEFAULT NULL COMMENT '客户ID(空=标准售价)',
  `price` decimal(18,2) NOT NULL COMMENT '价格',
  `type` varchar(20) DEFAULT '1' COMMENT '价格类型(dict:mes_price_type)',
  `begin_date` datetime DEFAULT NULL COMMENT '生效日期',
  `end_date` datetime DEFAULT NULL COMMENT '失效日期',
  `status` varchar(20) DEFAULT '1' COMMENT '状态 1启用 0停用',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_price_code_del` (`code`,`del_flag`),
  KEY `idx_price_material` (`material_id`),
  KEY `idx_price_overlap` (`material_id`,`status`,`customer_id`,`begin_date`,`end_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-价格';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_production_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_production_order` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '订单编号',
  `product_id` varchar(32) NOT NULL COMMENT '生产产品ID',
  `bom_id` varchar(32) DEFAULT NULL COMMENT '关联BOM ID',
  `plan_qty` decimal(18,4) DEFAULT NULL COMMENT '计划数量',
  `completed_qty` decimal(18,4) DEFAULT '0.0000' COMMENT '已完工数量',
  `start_date` datetime DEFAULT NULL COMMENT '计划开工日期',
  `end_date` datetime DEFAULT NULL COMMENT '计划完工日期',
  `warehouse_id` varchar(32) DEFAULT NULL COMMENT '完工仓库ID',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_production_order_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_prod_order_code` (`code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-生产订单';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_production_picking`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_production_picking` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '领料单号',
  `production_order_id` varchar(32) NOT NULL COMMENT '生产订单ID',
  `warehouse_id` varchar(32) DEFAULT NULL COMMENT '领料仓库ID',
  `picking_date` datetime DEFAULT NULL COMMENT '领料日期',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_picking_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_picking_code` (`code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-生产领料';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_production_picking_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_production_picking_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `picking_id` varchar(32) NOT NULL COMMENT '领料单ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `quantity` decimal(18,4) DEFAULT NULL COMMENT '领料数量',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_item_picking_id` (`picking_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-生产领料行';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_purchase_apply`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_purchase_apply` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '申请单号',
  `dept_id` varchar(32) DEFAULT NULL COMMENT '申请部门',
  `applicant_id` varchar(32) DEFAULT NULL COMMENT '申请人',
  `apply_date` datetime DEFAULT NULL COMMENT '申请日期',
  `required_date` datetime DEFAULT NULL COMMENT '需求日期',
  `budget_subject` varchar(50) DEFAULT NULL COMMENT '预算科目',
  `total_amount` decimal(18,2) DEFAULT NULL COMMENT '申请金额合计',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_purchase_apply_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `supplier_id` varchar(32) DEFAULT NULL COMMENT '供应商ID',
  `purchase_type` varchar(20) DEFAULT NULL COMMENT '采购类型(dict:mes_purchase_type)',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_apply_code_del` (`code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-采购申请';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_purchase_apply_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_purchase_apply_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `apply_id` varchar(32) NOT NULL COMMENT '申请单ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `quantity` decimal(18,4) DEFAULT NULL COMMENT '申请数量',
  `unit` varchar(20) DEFAULT NULL COMMENT '单位',
  `purpose` varchar(200) DEFAULT NULL COMMENT '用途说明',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `unit_price` decimal(18,2) DEFAULT NULL COMMENT '单价',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '金额',
  `tax_rate` decimal(18,4) DEFAULT '0.1300' COMMENT '税率',
  PRIMARY KEY (`id`),
  KEY `idx_item_apply_id` (`apply_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-采购申请行';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_purchase_invoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_purchase_invoice` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '发票单号',
  `invoice_no` varchar(50) DEFAULT NULL COMMENT '发票号码',
  `supplier_id` varchar(32) NOT NULL COMMENT '供应商ID',
  `purchase_order_id` varchar(32) DEFAULT NULL COMMENT '关联采购订单ID',
  `receipt_id` varchar(32) DEFAULT NULL COMMENT '关联入库单ID',
  `invoice_date` datetime DEFAULT NULL COMMENT '收票日期',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '不含税金额',
  `tax_rate` decimal(5,2) DEFAULT '0.13' COMMENT '税率',
  `tax_amount` decimal(18,2) DEFAULT NULL COMMENT '税额',
  `total_with_tax` decimal(18,2) DEFAULT NULL COMMENT '价税合计',
  `invoice_type` varchar(20) DEFAULT '1' COMMENT '发票类型(dict:mes_invoice_type)',
  `status` varchar(20) DEFAULT '1' COMMENT '状态 1已收票 0已作废',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pi_code_del` (`code`,`del_flag`),
  KEY `idx_pi_supplier` (`supplier_id`),
  KEY `idx_pi_order` (`purchase_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-进项发票';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_purchase_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_purchase_order` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '订单编号',
  `supplier_id` varchar(32) NOT NULL COMMENT '供应商ID',
  `purchase_type` varchar(20) DEFAULT NULL COMMENT '采购类型(dict:mes_purchase_type)',
  `order_date` datetime DEFAULT NULL COMMENT '订单日期',
  `delivery_date` datetime DEFAULT NULL COMMENT '交货日期',
  `payment_terms` varchar(50) DEFAULT NULL COMMENT '付款条款',
  `total_amount` decimal(18,2) DEFAULT NULL COMMENT '不含税金额',
  `tax_amount` decimal(18,2) DEFAULT NULL COMMENT '税额',
  `total_with_tax` decimal(18,2) DEFAULT NULL COMMENT '含税总额',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_purchase_order_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `purchase_apply_id` varchar(32) DEFAULT NULL COMMENT '采购申请单ID',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_po_code_del` (`code`,`del_flag`),
  KEY `idx_po_create_time` (`create_time`),
  KEY `idx_po_status` (`status`),
  KEY `idx_po_apply_id` (`purchase_apply_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-采购订单';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_purchase_order_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_purchase_order_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `order_id` varchar(32) NOT NULL COMMENT '订单ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `quantity` decimal(18,4) DEFAULT NULL COMMENT '数量',
  `received_qty` decimal(18,4) DEFAULT '0.0000' COMMENT '累计入库量(原子扣减防超收)',
  `unit_price` decimal(18,2) DEFAULT NULL COMMENT '单价',
  `tax_rate` decimal(5,2) DEFAULT '0.13' COMMENT '税率',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '金额(服务端计算)',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_item_po_id` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-采购订单行';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_purchase_receipt`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_purchase_receipt` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '入库单号',
  `purchase_order_id` varchar(32) DEFAULT NULL COMMENT '关联采购订单ID',
  `supplier_id` varchar(32) DEFAULT NULL COMMENT '供应商ID',
  `warehouse_id` varchar(32) DEFAULT NULL COMMENT '仓库ID',
  `receipt_date` datetime DEFAULT NULL COMMENT '入库日期',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:yn)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_receipt_code_del` (`code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-采购入库';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_purchase_receipt_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_purchase_receipt_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `receipt_id` varchar(32) NOT NULL COMMENT '入库单ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `order_quantity` decimal(18,4) DEFAULT NULL COMMENT '采购数量',
  `receipt_quantity` decimal(18,4) DEFAULT NULL COMMENT '本次入库数量',
  `qc_result` varchar(20) DEFAULT NULL COMMENT '质检结果(dict:mes_qc_result)',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `unit_price` decimal(18,2) DEFAULT NULL COMMENT '单价(不含税)',
  `tax_rate` decimal(5,2) DEFAULT '0.13' COMMENT '税率(0~1)',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '金额',
  `batch_no` varchar(50) DEFAULT NULL COMMENT '生产批次号(手工录入)',
  `production_date` date DEFAULT NULL COMMENT '生产日期',
  `shelf_life` int DEFAULT NULL COMMENT '保质期(天)',
  `expiry_date` datetime DEFAULT NULL COMMENT '有效期至',
  PRIMARY KEY (`id`),
  KEY `idx_item_receipt_id` (`receipt_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-采购入库行';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_receivable`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_receivable` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '应收单号',
  `customer_id` varchar(32) NOT NULL COMMENT '客户ID',
  `source_type` varchar(50) DEFAULT NULL COMMENT '来源类型(销售出库)',
  `source_bill_id` varchar(32) DEFAULT NULL COMMENT '来源单据ID',
  `source_bill_no` varchar(50) DEFAULT NULL COMMENT '来源单据号',
  `amount` decimal(18,2) NOT NULL COMMENT '应收金额',
  `received_amount` decimal(18,2) DEFAULT '0.00' COMMENT '已收金额',
  `unsettled_amount` decimal(18,2) DEFAULT NULL COMMENT '未结金额',
  `credit_period` int DEFAULT '30' COMMENT '账期(天)',
  `due_date` datetime DEFAULT NULL COMMENT '到期日',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_receivable_status)',
  `settlement_date` datetime DEFAULT NULL COMMENT '结清日期',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `tax_amount` decimal(18,2) DEFAULT NULL COMMENT '税额',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_rec_code_del` (`code`,`del_flag`),
  UNIQUE KEY `uk_rec_source_bill` (`source_bill_id`,`del_flag`),
  KEY `idx_rec_customer` (`customer_id`),
  KEY `idx_rec_due_date` (`due_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-应收单';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_sales_invoice`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_sales_invoice` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '发票单号',
  `invoice_no` varchar(50) DEFAULT NULL COMMENT '发票号码',
  `customer_id` varchar(32) NOT NULL COMMENT '客户ID',
  `sales_order_id` varchar(32) DEFAULT NULL COMMENT '关联订单ID',
  `outbound_id` varchar(32) DEFAULT NULL COMMENT '关联出库单ID',
  `invoice_date` datetime DEFAULT NULL COMMENT '开票日期',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '不含税金额',
  `tax_rate` decimal(5,2) DEFAULT '0.13' COMMENT '税率',
  `tax_amount` decimal(18,2) DEFAULT NULL COMMENT '税额',
  `total_with_tax` decimal(18,2) DEFAULT NULL COMMENT '价税合计',
  `invoice_type` varchar(20) DEFAULT '1' COMMENT '发票类型(dict:mes_invoice_type)',
  `status` varchar(20) DEFAULT '1' COMMENT '状态 1已开票 0已作废',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_si_code_del` (`code`,`del_flag`),
  KEY `idx_si_customer` (`customer_id`),
  KEY `idx_si_order` (`sales_order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-销项发票';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_sales_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_sales_order` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '订单编码',
  `customer_id` varchar(32) NOT NULL COMMENT '客户ID',
  `order_date` datetime DEFAULT NULL COMMENT '订单日期',
  `delivery_date` datetime DEFAULT NULL COMMENT '交货日期',
  `status` varchar(20) DEFAULT '1' COMMENT '订单状态(dict:mes_order_status)',
  `total_amount` decimal(18,2) DEFAULT NULL COMMENT '订单总金额',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_code_del` (`code`,`del_flag`),
  KEY `idx_order_customer_id` (`customer_id`),
  KEY `idx_order_ctime` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-销售订单';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_sales_order_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_sales_order_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `order_id` varchar(32) NOT NULL COMMENT '订单ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `quantity` decimal(18,4) DEFAULT NULL COMMENT '数量',
  `unit_price` decimal(18,2) DEFAULT NULL COMMENT '单价',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '金额',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tax_rate` decimal(5,2) DEFAULT '0.13' COMMENT '税率',
  `tax_amount` decimal(18,2) DEFAULT NULL COMMENT '税额',
  PRIMARY KEY (`id`),
  KEY `idx_item_order_id` (`order_id`),
  KEY `idx_item_material_id` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-销售订单行';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_sales_outbound`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_sales_outbound` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '出库单编码',
  `delivery_note_id` varchar(32) DEFAULT NULL COMMENT '发货单ID',
  `sales_order_id` varchar(32) DEFAULT NULL COMMENT '销售订单ID',
  `warehouse_id` varchar(32) NOT NULL COMMENT '出库仓库ID',
  `customer_id` varchar(32) DEFAULT NULL COMMENT '客户ID(冗余)',
  `outbound_date` datetime DEFAULT NULL COMMENT '出库日期',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_outbound_status)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  `total_amount` decimal(18,2) DEFAULT NULL COMMENT '总金额',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_outbound_code_del` (`code`,`del_flag`),
  KEY `idx_outbound_delivery` (`delivery_note_id`),
  KEY `idx_outbound_status` (`status`),
  KEY `idx_outbound_ctime` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-销售出库单';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_sales_outbound_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_sales_outbound_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `outbound_id` varchar(32) NOT NULL COMMENT '出库单ID',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `delivery_qty` decimal(18,4) DEFAULT NULL COMMENT '发货数量',
  `actual_qty` decimal(18,4) DEFAULT NULL COMMENT '实出数量',
  `batch` varchar(50) DEFAULT NULL COMMENT '批次',
  `location` varchar(50) DEFAULT NULL COMMENT '库位',
  `remark` varchar(200) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `unit_price` decimal(18,2) DEFAULT NULL COMMENT '单价',
  `amount` decimal(18,2) DEFAULT NULL COMMENT '金额',
  PRIMARY KEY (`id`),
  KEY `idx_obi_outbound_id` (`outbound_id`),
  KEY `idx_obi_material_id` (`material_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-销售出库明细';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_shelf`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_shelf` (
  `id` varchar(36) NOT NULL COMMENT '主键',
  `zone_id` varchar(36) NOT NULL COMMENT '所属库区ID',
  `warehouse_id` varchar(36) DEFAULT NULL COMMENT '所属仓库ID(冗余加速)',
  `code` varchar(50) NOT NULL COMMENT '货架编码',
  `name` varchar(100) DEFAULT NULL COMMENT '货架名称',
  `sort_no` int DEFAULT '0' COMMENT '排序号',
  `status` int DEFAULT '1' COMMENT '状态 1启用 0停用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_mes_shelf_zone_code_del` (`zone_id`,`code`,`del_flag`),
  KEY `idx_mes_shelf_zone` (`zone_id`),
  KEY `idx_mes_shelf_wh` (`warehouse_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-货架表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_stocktake`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_stocktake` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '盘点单号',
  `warehouse_id` varchar(32) NOT NULL COMMENT '仓库ID(单仓盘点)',
  `take_type` varchar(20) DEFAULT '1' COMMENT '盘点类型(dict:mes_stocktake_type 1全盘2抽盘)',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_other_stock_status)',
  `take_date` datetime DEFAULT NULL COMMENT '盘点日期',
  `snapshot_time` datetime DEFAULT NULL COMMENT '账面快照时间(book_qty取数时点)',
  `total_diff_amount` decimal(18,2) DEFAULT NULL COMMENT '差异金额合计(冗余展示)',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_stocktake_code_del` (`code`,`del_flag`),
  KEY `idx_stocktake_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-盘点单';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_stocktake_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_stocktake_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `take_id` varchar(32) NOT NULL COMMENT '盘点单ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `material_id` varchar(32) NOT NULL COMMENT '物料ID',
  `book_qty` decimal(18,4) NOT NULL COMMENT '账面数量(快照)',
  `actual_qty` decimal(18,4) DEFAULT NULL COMMENT '实盘数量(全盘默认=账面,抽盘必填)',
  `diff_qty` decimal(18,4) DEFAULT NULL COMMENT '差异数量(实盘-账面)',
  `unit_cost` decimal(18,4) DEFAULT NULL COMMENT '成本单价(快照移动平均)',
  `diff_amount` decimal(18,2) DEFAULT NULL COMMENT '差异金额(diff_qty*unit_cost)',
  `generated_in_id` varchar(32) DEFAULT NULL COMMENT '盘盈生成的入库单ID',
  `generated_out_id` varchar(32) DEFAULT NULL COMMENT '盘亏生成的出库单ID',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`),
  KEY `idx_item_take_id` (`take_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-盘点单行';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_supplier`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_supplier` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '供应商编码',
  `name` varchar(100) NOT NULL COMMENT '供应商名称',
  `type` varchar(20) DEFAULT NULL COMMENT '供应商类型(dict:mes_supplier_type)',
  `status` varchar(20) DEFAULT '1' COMMENT '供应商状态(dict:mes_supplier_status)',
  `grade` varchar(20) DEFAULT NULL COMMENT '供应商等级(dict:mes_supplier_grade)',
  `blacklist_flag` tinyint(1) DEFAULT '0' COMMENT '黑名单标记 0否 1是',
  `contact` varchar(100) DEFAULT NULL COMMENT '联系人',
  `phone` varchar(50) DEFAULT NULL COMMENT '联系电话',
  `address` varchar(255) DEFAULT NULL COMMENT '地址',
  `invoice_title` varchar(200) DEFAULT NULL COMMENT '发票抬头',
  `tax_no` varchar(50) DEFAULT NULL COMMENT '税号',
  `bank_name` varchar(100) DEFAULT NULL COMMENT '开户银行',
  `bank_account` varchar(50) DEFAULT NULL COMMENT '银行账号',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_supplier_code_del` (`code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-供应商';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_voucher`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_voucher` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `voucher_no` varchar(50) NOT NULL COMMENT '凭证号',
  `voucher_date` datetime DEFAULT NULL COMMENT '凭证日期',
  `status` varchar(20) DEFAULT '1' COMMENT '状态(dict:mes_voucher_status)',
  `source_type` varchar(20) DEFAULT '1' COMMENT '来源类型 1手工 2业务',
  `source_bill_id` varchar(32) DEFAULT NULL COMMENT '来源单据ID',
  `total_debit` decimal(18,2) DEFAULT NULL COMMENT '借方合计',
  `total_credit` decimal(18,2) DEFAULT NULL COMMENT '贷方合计',
  `remark` varchar(500) DEFAULT NULL COMMENT '摘要',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_voucher_no_del` (`voucher_no`,`del_flag`),
  KEY `idx_voucher_date` (`voucher_date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-凭证';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_voucher_item`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_voucher_item` (
  `id` varchar(32) NOT NULL COMMENT '主键',
  `voucher_id` varchar(32) NOT NULL COMMENT '凭证ID',
  `line_no` int DEFAULT NULL COMMENT '行号',
  `summary` varchar(200) DEFAULT NULL COMMENT '摘要',
  `subject_id` varchar(32) NOT NULL COMMENT '科目ID',
  `debit_amount` decimal(18,2) DEFAULT '0.00' COMMENT '借方金额',
  `credit_amount` decimal(18,2) DEFAULT '0.00' COMMENT '贷方金额',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_vi_voucher_id` (`voucher_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-凭证明细';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_warehouse`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_warehouse` (
  `id` varchar(36) NOT NULL COMMENT '主键',
  `code` varchar(50) NOT NULL COMMENT '仓库编码',
  `name` varchar(100) NOT NULL COMMENT '仓库名称',
  `type` varchar(50) DEFAULT NULL COMMENT '仓库类型',
  `address` varchar(300) DEFAULT NULL COMMENT '仓库地址',
  `manager` varchar(50) DEFAULT NULL COMMENT '负责人',
  `phone` varchar(20) DEFAULT NULL COMMENT '联系电话',
  `factory` varchar(100) DEFAULT NULL COMMENT '所属工厂',
  `workshop` varchar(100) DEFAULT NULL COMMENT '所属车间',
  `status` int DEFAULT '1' COMMENT '状态 1启用 0停用',
  `remark` varchar(500) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(50) DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_mes_wh_code_del` (`code`,`del_flag`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-仓库表';
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `c_mes_zone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `c_mes_zone` (
  `id` varchar(36) NOT NULL COMMENT '主键',
  `warehouse_id` varchar(36) NOT NULL COMMENT '所属仓库ID',
  `code` varchar(50) NOT NULL COMMENT '库区编码',
  `name` varchar(100) DEFAULT NULL COMMENT '库区名称',
  `sort_no` int DEFAULT '0' COMMENT '排序号',
  `status` int DEFAULT '1' COMMENT '状态 1启用 0停用',
  `remark` varchar(255) DEFAULT NULL COMMENT '备注',
  `create_by` varchar(50) DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除标记',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_mes_zone_wh_code_del` (`warehouse_id`,`code`,`del_flag`),
  KEY `idx_mes_zone_wh` (`warehouse_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci COMMENT='MES-库区表';
/*!40101 SET character_set_client = @saved_cs_client */;

-- update-end---author:pi---date:2026-08-04---for:[CI fix] V0.0.0 initial schema-----------