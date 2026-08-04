-- V0.0.0  完整 schema（platform + MES）初始化 SQL
-- 由 2026-08-04 CI 首次跑测发现 schema 冲突后用 mysqldump 导出
-- 包含 374 张表（sys_* platform + c_mes_* MES + QRTZ_* 等）
-- 跳过 --add-drop-table（让 V1.x ALTER 不与 V0.0.0 schema 冲突）
-- update-begin---author:pi---date:2026-08-04---for:[CI fix] V0.0.0 full schema (含 platform + MES + Quartz)-----------

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `jeecg-boot` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `jeecg-boot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `aigc_word_template` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '模版名称',
  `code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '模版编码',
  `header` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci COMMENT '页眉',
  `footer` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci COMMENT '页脚',
  `main` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci COMMENT '主体内容',
  `margins` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '页边距',
  `width` int DEFAULT NULL COMMENT '宽度',
  `height` int DEFAULT NULL COMMENT '高度',
  `paper_direction` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '纸张方向 vertical纵向 horizontal横向',
  `watermark` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '水印',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Word模版';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_app` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用名称',
  `descr` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用描述',
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用图标',
  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用类型',
  `prologue` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '开场白',
  `prompt` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '提示词',
  `model_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '模型id',
  `knowledge_ids` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '知识库',
  `flow_id` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '流程id（多个以逗号分隔）',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态（enable=启用、disable=禁用、release=发布）',
  `msg_num` int DEFAULT NULL COMMENT '历史消息数',
  `metadata` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '元数据',
  `preset_question` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '预设问题',
  `quick_command` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '快捷指令',
  `plugins` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '插件',
  `memory_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '记忆库(知识库的id)',
  `variables` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '存放变量的配置',
  `iz_open_memory` int DEFAULT NULL COMMENT '是否开启记忆(0 不开启，1开启)',
  `memory_prompt` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '记忆和变量提示词',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_ext_data` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '主键ID',
  `biz_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '业务类型标识（ evaluator:评估器；track:测试追踪 ）',
  `name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '名称',
  `descr` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '描述信息',
  `tags` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标签，多个用逗号分隔',
  `data_value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '实际存储内容，json',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态（run:进行中 completed：已完成）',
  `dataset_value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '评测集数据',
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '元数据，用于存储补充业务数据信息',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `version` int DEFAULT NULL COMMENT '版本1开始',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_biz` (`biz_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='通用扩展数据表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_flow` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `application_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用名称',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '名称',
  `descr` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '描述',
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用图标',
  `chain` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '编排规则',
  `design` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '编排设计',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态（enable=启用、disable=禁用、release=发布）',
  `metadata` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '元数据',
  `trigger_cron` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'cron定时任务触发器配置JSON',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_knowledge` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '知识库名称',
  `descr` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '描述',
  `embed_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '向量模型id',
  `status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态',
  `type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '类型(knowledge知识 memory 记忆)',
  `metadata` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '元数据',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_knowledge_doc` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `knowledge_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '知识库id',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标题',
  `type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '类型',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '内容',
  `status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态',
  `metadata` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '元数据',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_mcp` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '图标',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '名称',
  `descr` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '描述',
  `category` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'mcp' COMMENT '类型（plugin=插件，mcp=MCP）',
  `type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'mcp类型（sse：sse类型；stdio：标准类型）',
  `endpoint` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '服务端点（SSE类型为URL，stdio类型为命令）',
  `headers` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '请求头（sse类型）、环境变量（stdio类型）',
  `tools` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '工具列表',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态（enable=启用、disable=禁用）',
  `synced` int DEFAULT NULL COMMENT '是否同步',
  `metadata` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '元数据',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='AI MCP';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_model` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '名称',
  `provider` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '供应者',
  `model_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '模型名称',
  `credential` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '凭证信息',
  `base_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'API域名',
  `model_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '模型类型',
  `model_params` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '模型参数',
  `activate_flag` int DEFAULT NULL COMMENT '是否激活（1=是，0=否）',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_prompts` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '主键ID',
  `name` varchar(125) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '提示词名称',
  `prompt_key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '提示词key',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '提示词功能描述',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '提示词模板内容，支持变量占位符如 {{variable}}',
  `category` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '提示词分类',
  `tags` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标签，多个逗号分割',
  `model_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '适配的大模型ID',
  `model_param` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '大模型的参数配置',
  `status` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '0' COMMENT '状态（0:未发布 1:已发布）',
  `version` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '版本号(格式 0.0.1)',
  `del_flag` int DEFAULT NULL COMMENT '删除状态（0未删除 1已删除）',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  UNIQUE KEY `uni_key` (`prompt_key`) USING BTREE,
  KEY `idx_category` (`category`) USING BTREE,
  KEY `idx_status` (`status`) USING BTREE,
  KEY `idx_name` (`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='AI提示词表';
/*!40101 SET character_set_client = @saved_cs_client */;
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
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chat2bi_table_meta` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '主键',
  `db_source_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '数据源来源表标识, 如: db_source / api_source / file_source / system_source',
  `db_source_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '对应来源表的主键ID',
  `schema_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Schema名',
  `table_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '表名',
  `source_comment` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '表注释-源(同步写入, 每次同步覆盖)',
  `table_comment` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '表注释-用户(用户手动填写, 同步不覆盖)',
  `columns_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '列定义[{name,type,source_comment,comment,is_primary,sample_values,nulltable}]',
  `relations_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '关联关系[{column,ref_table,ref_column,type}]',
  `is_enabled` tinyint NOT NULL DEFAULT '1' COMMENT '对LLM可见: 0=否 1=是',
  `synced_time` datetime DEFAULT NULL COMMENT '最近同步时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` int DEFAULT NULL COMMENT '多租户标识',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_source_table` (`db_source_type`,`db_source_id`,`schema_name`,`table_name`) USING BTREE,
  KEY `idx_source` (`db_source_type`,`db_source_id`) USING BTREE,
  KEY `idx_table_name` (`table_name`) USING BTREE,
  KEY `idx_table_name_comment` (`table_name`,`source_comment`(320),`table_comment`(320)) USING BTREE,
  KEY `idx_table_comment` (`table_comment`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='表元数据(同步+手动维护, 支持多数据源表)';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `demo` (
  `id` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `name` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '姓名',
  `key_word` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关键词',
  `punch_time` datetime DEFAULT NULL COMMENT '打卡时间',
  `salary_money` decimal(10,3) DEFAULT NULL COMMENT '工资',
  `bonus_money` double(10,2) DEFAULT NULL COMMENT '奖金',
  `sex` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '性别 {男:1,女:2}',
  `age` int DEFAULT NULL COMMENT '年龄',
  `birthday` date DEFAULT NULL COMMENT '生日',
  `email` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '邮箱',
  `content` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '个人简介',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门编码',
  `tenant_id` int DEFAULT '0',
  `update_count` int DEFAULT NULL COMMENT '乐观锁测试',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `flyway_schema_history` (
  `installed_rank` int NOT NULL,
  `version` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `script` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `checksum` int DEFAULT NULL,
  `installed_by` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `installed_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `execution_time` int NOT NULL,
  `success` tinyint(1) NOT NULL,
  PRIMARY KEY (`installed_rank`) USING BTREE,
  KEY `flyway_schema_history_s_idx` (`success`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jeecg_order_customer` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '客户名',
  `sex` varchar(4) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '性别',
  `idcard` varchar(18) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '身份证号码',
  `idcard_pic` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '身份证扫描件',
  `telphone` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '电话1',
  `order_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '外键',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jeecg_order_main` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `order_code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '订单号',
  `ctype` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '订单类型',
  `order_date` datetime DEFAULT NULL COMMENT '订单日期',
  `order_money` double(10,3) DEFAULT NULL COMMENT '订单金额',
  `content` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '订单备注',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `bpm_status` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '流程状态',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jeecg_order_ticket` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `ticket_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '航班号',
  `tickect_date` datetime DEFAULT NULL COMMENT '航班时间',
  `order_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '外键',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_dict` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `dict_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典名称',
  `dict_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典编码',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `del_flag` int DEFAULT NULL COMMENT '删除状态',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `type` int(1) unsigned zerofill DEFAULT '0' COMMENT '字典类型0为string,1为number',
  `tenant_id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多租户标识',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_sd_dict_code` (`dict_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_dict_item` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `dict_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典id',
  `item_text` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典项文本',
  `item_value` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典项值',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `sort_order` int DEFAULT NULL COMMENT '排序',
  `status` int DEFAULT NULL COMMENT '状态（1启用 0不启用）',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sdi_role_dict_id` (`dict_id`) USING BTREE,
  KEY `idx_sdi_role_sort_order` (`sort_order`) USING BTREE,
  KEY `idx_sdi_status` (`status`) USING BTREE,
  KEY `idx_sdi_dict_val` (`dict_id`,`item_value`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '编码',
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '名称',
  `note` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '说明',
  `status` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '状态',
  `type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型',
  `json_str` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'json字符串',
  `api_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求地址',
  `thumb` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '缩略图',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `del_flag` tinyint(1) DEFAULT NULL COMMENT '删除标识0-正常,1-已删除',
  `api_method` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求方法0-get,1-post',
  `api_code` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求编码',
  `template` tinyint(1) DEFAULT NULL COMMENT '是否是模板 0不是,1是',
  `view_count` bigint DEFAULT '0' COMMENT '浏览次数',
  `css_str` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'css增强',
  `js_str` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'js增强',
  `py_str` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'py增强',
  `tenant_id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多租户标识',
  `update_count` int DEFAULT '0' COMMENT '乐观锁版本',
  `submit_form` tinyint(1) DEFAULT NULL COMMENT '是否填报报表 0不是,1是',
  `is_multi_sheet` tinyint DEFAULT NULL COMMENT '是否多sheet报表 1是 0否',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_jmreport_code` (`code`) USING BTREE,
  KEY `uniq_jmreport_createby` (`create_by`) USING BTREE,
  KEY `uniq_jmreport_delflag` (`del_flag`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='在线excel设计器';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_category` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '分类名称',
  `parent_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '父级id',
  `iz_leaf` int DEFAULT NULL COMMENT '是否为叶子节点(0 否 1是)',
  `source_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '来源类型( report 积木报表 screen 大屏  drag 仪表盘)',
  `del_flag` int DEFAULT NULL COMMENT '删除标识(0 正常 1 已删除)',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` timestamp NULL DEFAULT NULL COMMENT '更新时间',
  `tenant_id` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '租户id',
  `sort_no` int DEFAULT NULL COMMENT '排序',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='分类';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_data_source` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据源名称',
  `report_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '报表_id',
  `code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '编码',
  `remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `db_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据库类型',
  `db_driver` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '驱动类',
  `db_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据源地址',
  `db_username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户名',
  `db_password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '密码',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `connect_times` int DEFAULT '0' COMMENT '连接失败次数',
  `tenant_id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多租户标识',
  `type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '类型(report:报表;drag:仪表盘)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_jmdatasource_report_id` (`report_id`) USING BTREE,
  KEY `idx_jmdatasource_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_db` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `jimu_report_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主键字段',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `db_code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据集编码',
  `db_ch_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据集名字',
  `db_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据源类型',
  `db_table_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据库表名',
  `db_dyn_sql` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '动态查询SQL',
  `db_key` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据源KEY',
  `tb_db_key` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '填报数据源',
  `tb_db_table_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '填报数据表',
  `java_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'java类数据集  类型（spring:springkey,class:java类名）',
  `java_value` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'java类数据源  数值（bean key/java类名）',
  `api_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求地址',
  `api_method` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求方法0-get,1-post',
  `is_list` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '是否是列表0否1是 默认0',
  `is_page` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否作为分页,0:不分页，1:分页',
  `db_source` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据源',
  `db_source_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据库类型 MYSQL ORACLE SQLSERVER',
  `json_data` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'json数据，直接解析json内容',
  `api_convert` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'api转换器',
  `iz_shared_source` int DEFAULT NULL COMMENT '是否为共享数据源(0 否 1 是)',
  `jimu_shared_source_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '指向共享数据集的id',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_jmreportdb_db_key` (`db_key`) USING BTREE,
  KEY `idx_jimu_report_id` (`jimu_report_id`) USING BTREE,
  KEY `idx_db_source_id` (`db_source`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_db_field` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `jimu_report_db_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据源ID',
  `field_name` varchar(80) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段名',
  `field_name_physics` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '物理字段名（文件数据集使用，存的是excel的字段标题）',
  `field_text` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段文本',
  `widget_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '控件类型',
  `widget_width` int DEFAULT NULL COMMENT '控件宽度',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `search_flag` int DEFAULT '0' COMMENT '查询标识0否1是 默认0',
  `search_mode` int DEFAULT NULL COMMENT '查询模式1简单2范围',
  `dict_code` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典编码支持从表中取数据',
  `search_value` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询默认值',
  `search_format` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询时间格式化表达式',
  `ext_json` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '参数配置',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_jrdf_jimu_report_db_id` (`jimu_report_db_id`) USING BTREE,
  KEY `idx_dbfield_order_num` (`order_num`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_db_param` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `jimu_report_head_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '动态报表ID',
  `param_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '参数字段',
  `param_txt` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数文本',
  `param_value` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数默认值',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `search_flag` int DEFAULT NULL COMMENT '查询标识0否1是 默认0',
  `widget_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询控件类型',
  `search_mode` int DEFAULT NULL COMMENT '查询模式1简单2范围',
  `dict_code` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典',
  `search_format` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询时间格式化表达式',
  `ext_json` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '参数配置',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_jrdp_jimu_report_head_id` (`jimu_report_head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_export_job` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '任务名称',
  `begin_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `exec_interval` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '执行频率',
  `report_conf` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '导出报表配置',
  `last_run_time` datetime DEFAULT NULL COMMENT '最后执行时间',
  `receiver_email` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '接收通知的邮件',
  `file_sync_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '文件同步路径',
  `status` int DEFAULT NULL COMMENT '状态(0:停止;1:启动)',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `tenant_id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多租户标识',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='积木报表导出计划表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_export_log` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `batch_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '批次编号',
  `export_channel` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '导出渠道',
  `export_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '导出类型',
  `report_id` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '报表id',
  `download_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '下载路径',
  `status` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '状态',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多租户标识',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='积木报表自动导出记录表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_ext_data` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键ID',
  `biz_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '业务类型标识，如 report_share、temp_config 等',
  `name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '名称，展示用',
  `descr` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '描述信息',
  `tags` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '标签，多个用逗号分隔',
  `data_value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '实际存储内容',
  `metadata` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '元数据，用于存储补充信息',
  `status` tinyint DEFAULT '1' COMMENT '状态标识：1正常 0禁用',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_biz` (`biz_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通用扩展数据表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_icon_lib` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '图片名称',
  `type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '图片类型',
  `image_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '图片地址',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` int DEFAULT NULL COMMENT '租户id',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='积木图库表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_link` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键id',
  `report_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '积木设计器id',
  `parameter` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '参数',
  `eject_type` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '弹出方式（0 当前页面 1 新窗口）',
  `link_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '链接名称',
  `api_method` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '请求方法0-get,1-post',
  `link_type` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '链接方式(0 网络报表 1 网络连接 2 图表联动)',
  `api_url` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '外网api',
  `link_chart_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '联动图表的ID',
  `expression` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '表达式',
  `requirement` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '条件',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `uniq_link_reportid` (`report_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='超链接配置表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_map` (
  `id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `label` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '地图名称',
  `name` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '地图编码',
  `data` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '地图数据',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `del_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '0表示未删除,1表示删除',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_jmreport_map_name` (`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='地图配置表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_share` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `report_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '在线excel设计器id',
  `preview_url` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '预览地址',
  `preview_lock` varchar(4) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '密码锁',
  `last_update_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  `term_of_validity` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '有效期(0:永久有效，1:1天，2:7天)',
  `status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '是否过期(0未过期，1已过期)',
  `preview_lock_status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '是否为密码锁(0 否,1是)',
  `share_token` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '分享token',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_report_id` (`report_id`) USING BTREE,
  UNIQUE KEY `uniq_jrs_report_id` (`report_id`) USING BTREE COMMENT '报表id唯一索引',
  KEY `idx_jrs_share_token` (`share_token`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='积木报表预览权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_sheet` (
  `id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键（Sheet ID）',
  `report_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '报表ID',
  `sheet_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Sheet名称',
  `sheet_order` int NOT NULL COMMENT '排序（可以为负数，负数表示在默认sheet前面）',
  `json_str` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '该sheet的完整jsonStr',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_report_id` (`report_id`) USING BTREE,
  KEY `idx_sheet_order` (`report_id`,`sheet_order`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='报表Sheet表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `joa_demo` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'ID',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请假人',
  `days` int DEFAULT NULL COMMENT '请假天数',
  `begin_date` datetime DEFAULT NULL COMMENT '开始时间',
  `end_date` datetime DEFAULT NULL COMMENT '请假结束时间',
  `reason` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请假原因',
  `bpm_status` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '1' COMMENT '流程状态',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人id',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='流程测试';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `oauth2_registered_client` (
  `id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `client_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `client_id_issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `client_secret` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `client_secret_expires_at` timestamp NULL DEFAULT NULL,
  `client_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `client_authentication_methods` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `authorization_grant_types` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `redirect_uris` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `post_logout_redirect_uris` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `scopes` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `client_settings` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `token_settings` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_auth_data` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `cgform_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'online表ID',
  `rule_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则名',
  `rule_column` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则列',
  `rule_operator` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则条件 大于小于like',
  `rule_value` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则值',
  `status` int DEFAULT NULL COMMENT '1有效 0无效',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_auth_page` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT ' 主键',
  `cgform_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'online表id',
  `code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '字段名/按钮编码',
  `type` int DEFAULT NULL COMMENT '1字段 2按钮',
  `control` int DEFAULT NULL COMMENT '3可编辑 5可见(仅支持两种状态值3,5)',
  `page` int DEFAULT NULL COMMENT '3列表 5表单(仅支持两种状态值3,5)',
  `status` int DEFAULT NULL COMMENT '1有效 0无效',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_onl_auth_page_code` (`code`) USING BTREE,
  KEY `idx_onl_auth_page_cgform_id` (`cgform_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_auth_relation` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `role_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '角色id',
  `auth_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '权限id',
  `type` int DEFAULT NULL COMMENT '1字段 2按钮 3数据权限',
  `cgform_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'online表单ID',
  `auth_mode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '授权方式role角色，depart部门，user人',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_button` (
  `ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `BUTTON_CODE` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮编码',
  `BUTTON_ICON` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮图标',
  `BUTTON_NAME` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮名称',
  `BUTTON_STATUS` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮状态',
  `BUTTON_STYLE` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮样式',
  `EXP` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表达式',
  `CGFORM_HEAD_ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单ID',
  `OPT_TYPE` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮类型',
  `ORDER_NUM` int DEFAULT NULL COMMENT '排序',
  `OPT_POSITION` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮位置1侧面 2底部',
  PRIMARY KEY (`ID`) USING BTREE,
  KEY `idx_ocb_CGFORM_HEAD_ID` (`CGFORM_HEAD_ID`) USING BTREE,
  KEY `idx_ocb_BUTTON_CODE` (`BUTTON_CODE`) USING BTREE,
  KEY `idx_ocb_BUTTON_STATUS` (`BUTTON_STATUS`) USING BTREE,
  KEY `idx_ocb_ORDER_NUM` (`ORDER_NUM`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='Online表单自定义按钮';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_enhance_java` (
  `ID` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `BUTTON_CODE` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮编码',
  `CG_JAVA_TYPE` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '类型',
  `CG_JAVA_VALUE` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '数值',
  `CGFORM_HEAD_ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表单ID',
  `ACTIVE_STATUS` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '1' COMMENT '生效状态',
  `EVENT` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT 'end' COMMENT '事件状态(end:结束，start:开始)',
  PRIMARY KEY (`ID`) USING BTREE,
  KEY `idx_ejava_cgform_head_id` (`CGFORM_HEAD_ID`) USING BTREE,
  KEY `idx_ocej_BUTTON_CODE` (`BUTTON_CODE`) USING BTREE,
  KEY `idx_ocej_ACTIVE_STATUS` (`ACTIVE_STATUS`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_enhance_js` (
  `ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `CG_JS` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'JS增强内容',
  `CG_JS_TYPE` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型',
  `CONTENT` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `CGFORM_HEAD_ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单ID',
  PRIMARY KEY (`ID`) USING BTREE,
  KEY `idx_ejs_cgform_head_id` (`CGFORM_HEAD_ID`) USING BTREE,
  KEY `idx_ejs_cg_js_type` (`CG_JS_TYPE`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_enhance_sql` (
  `ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `BUTTON_CODE` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮编码',
  `CGB_SQL` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'SQL内容',
  `CGB_SQL_NAME` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'Sql名称',
  `CONTENT` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `CGFORM_HEAD_ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单ID',
  PRIMARY KEY (`ID`) USING BTREE,
  KEY `idx_oces_CGFORM_HEAD_ID` (`CGFORM_HEAD_ID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_field` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `cgform_head_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表ID',
  `db_field_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字段名字',
  `db_field_txt` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段备注',
  `db_field_name_old` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '原字段名',
  `db_is_key` tinyint(1) DEFAULT NULL COMMENT '是否主键 0否 1是',
  `db_is_null` tinyint(1) DEFAULT NULL COMMENT '是否允许为空0否 1是',
  `db_is_persist` tinyint(1) DEFAULT NULL COMMENT '是否需要同步数据库字段， 1是0否',
  `db_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '数据库字段类型',
  `db_length` int NOT NULL COMMENT '数据库字段长度',
  `db_point_length` int DEFAULT NULL COMMENT '小数点',
  `db_default_val` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表字段默认值',
  `dict_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典code',
  `dict_table` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典表',
  `dict_text` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典Text',
  `field_show_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单控件类型',
  `field_href` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '跳转URL',
  `field_length` int DEFAULT NULL COMMENT '表单控件长度',
  `field_valid_type` varchar(300) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单字段校验规则',
  `field_must_input` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段是否必填',
  `field_extend_json` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '扩展参数JSON',
  `field_default_value` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '控件默认值，不同的表达式展示不同的结果。\r\n1. 纯字符串直接赋给默认值；\r\n2. #{普通变量}；\r\n3. {{ 动态JS表达式 }}；\r\n4. ${填值规则编码}；\r\n填值规则表达式只允许存在一个，且不能和其他规则混用。',
  `is_query` tinyint(1) DEFAULT NULL COMMENT '是否查询条件0否 1是',
  `is_show_form` tinyint(1) DEFAULT NULL COMMENT '表单是否显示0否 1是',
  `is_show_list` tinyint(1) DEFAULT NULL COMMENT '列表是否显示0否 1是',
  `is_read_only` tinyint(1) DEFAULT '0' COMMENT '是否是只读（1是 0否）',
  `query_mode` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询模式',
  `main_table` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '外键主表名',
  `main_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '外键主键字段',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `converter` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '自定义值转换器',
  `query_def_val` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询默认值',
  `query_dict_text` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询配置字典text',
  `query_dict_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询配置字典code',
  `query_dict_table` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询配置字典table',
  `query_show_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询显示控件',
  `query_config_flag` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否启用查询配置1是0否',
  `query_valid_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询字段校验类型',
  `query_must_input` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询字段是否必填1是0否',
  `sort_flag` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否支持排序1是0否',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ocf_cgform_head_id` (`cgform_head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_head` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `table_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表名',
  `table_type` int NOT NULL COMMENT '表类型: 0单表、1主表、2附表',
  `table_version` int DEFAULT '1' COMMENT '表版本',
  `table_txt` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表说明',
  `is_checkbox` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '是否带checkbox',
  `is_db_synch` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT 'N' COMMENT '同步数据库状态',
  `is_page` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '是否分页',
  `is_tree` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '是否是树',
  `id_sequence` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主键生成序列',
  `id_type` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主键类型',
  `query_mode` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询模式',
  `relation_type` int DEFAULT NULL COMMENT '映射关系 0一对多  1一对一',
  `sub_table_str` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '子表',
  `tab_order_num` int DEFAULT NULL COMMENT '附表排序序号',
  `tree_parent_id_field` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '树形表单父id',
  `tree_id_field` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '树表主键字段',
  `tree_fieldname` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '树开表单列字段',
  `form_category` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT 'bdfl_ptbd' COMMENT '表单分类',
  `form_template` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'PC表单模板',
  `form_template_mobile` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单模板样式(移动端)',
  `scroll` int DEFAULT '0' COMMENT '是否有横向滚动条',
  `copy_version` int DEFAULT NULL COMMENT '复制版本号',
  `copy_type` int DEFAULT '0' COMMENT '复制表类型1为复制表 0为原始表',
  `physic_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '原始表ID',
  `ext_config_json` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '扩展JSON',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `theme_template` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主题模板',
  `is_des_form` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否用设计器表单',
  `des_form_code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '设计器表单编码',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `low_app_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关联的应用ID',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_och_cgform_head_id` (`table_name`) USING BTREE,
  KEY `idx_och_table_name` (`form_template`) USING BTREE,
  KEY `idx_och_form_template_mobile` (`form_template_mobile`) USING BTREE,
  KEY `idx_och_table_version` (`table_version`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_index` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `cgform_head_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主表id',
  `index_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '索引名称',
  `index_name_old` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '原索引名称',
  `index_field` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '索引栏位',
  `index_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '索引类型',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `is_db_synch` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT 'N' COMMENT '是否同步数据库 N未同步 Y已同步',
  `del_flag` int DEFAULT '0' COMMENT '是否删除 0未删除 1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_oci_cgform_head_id` (`cgform_head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgreport_head` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '报表编码',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '报表名字',
  `cgr_sql` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '报表SQL',
  `return_val_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '返回值字段',
  `return_txt_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '返回文本字段',
  `return_type` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '1' COMMENT '返回类型，单选或多选',
  `db_source` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '动态数据源',
  `content` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `low_app_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关联的应用ID',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人id',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人id',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `index_onlinereport_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgreport_item` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `cgrhead_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '报表ID',
  `field_name` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字段名字',
  `field_txt` varchar(300) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段文本',
  `field_width` int DEFAULT NULL,
  `field_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段类型',
  `search_mode` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询模式',
  `is_order` int DEFAULT '0' COMMENT '是否排序  0否,1是',
  `is_search` int DEFAULT '0' COMMENT '是否查询  0否,1是',
  `dict_code` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典CODE',
  `field_href` varchar(120) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段跳转URL',
  `is_show` int DEFAULT '1' COMMENT '是否显示  0否,1显示',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `replace_val` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '取值表达式',
  `is_total` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否合计 0否,1是（仅对数值有效）',
  `group_title` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '分组标题',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_oci_cgrhead_id` (`cgrhead_id`) USING BTREE,
  KEY `idx_oci_is_show` (`is_show`) USING BTREE,
  KEY `idx_oci_order_num` (`order_num`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgreport_param` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `cgrhead_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '动态报表ID',
  `param_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '参数字段',
  `param_txt` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数文本',
  `param_value` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数默认值',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ocp_cgrhead_id` (`cgrhead_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_comp` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `parent_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `comp_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '组件名称',
  `comp_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `icon` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '图标',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `type_id` int DEFAULT NULL COMMENT '组件类型',
  `comp_config` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '组件配置',
  `status` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '状态0:无效 1:有效',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='组件库';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_dataset_head` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '名称',
  `code` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '编码',
  `parent_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '父id',
  `db_source` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '动态数据源',
  `query_sql` varchar(5000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '查询数据SQL',
  `content` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `iz_agent` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT 'iz_agent',
  `data_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据类型',
  `api_method` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'api方法：get/post',
  `create_time` datetime DEFAULT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `low_app_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '应用ID',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_dataset_item` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `head_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主表ID',
  `field_name` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段名',
  `field_txt` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段文本',
  `field_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段类型',
  `widget_type` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '控件类型',
  `dict_code` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典Code',
  `dict_table` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `dict_text` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `iz_show` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否列表显示',
  `iz_search` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否查询',
  `iz_total` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否计算总计（仅对数值有效）',
  `search_mode` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询模式',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_oddi_head_id` (`head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_dataset_param` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `head_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '动态报表ID',
  `param_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '参数字段',
  `param_txt` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数文本',
  `param_value` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数默认值',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `iz_search` int DEFAULT NULL COMMENT '查询标识0否1是 默认0',
  `widget_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询控件类型',
  `search_mode` int DEFAULT NULL COMMENT '查询模式1简单2范围',
  `dict_code` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_oddp_head_id` (`head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_page` (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '界面名称',
  `path` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '访问路径',
  `background_color` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '背景色',
  `background_image` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '背景图',
  `design_type` int DEFAULT NULL COMMENT '设计模式(1:pc,2:手机,3:平板)',
  `theme` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '主题色',
  `style` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '面板主题',
  `cover_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '封面图',
  `des_json` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '仪表盘主配置JSON',
  `template` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '布局json',
  `protection_code` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '保护码',
  `type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属分类',
  `iz_template` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '0' COMMENT '是否模板(1:是；0不是)',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `low_app_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '应用ID',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  `update_count` int DEFAULT '1',
  `visits_num` int DEFAULT NULL COMMENT '访问次数',
  `del_flag` int DEFAULT NULL COMMENT '删除状态( 0未删除 1已删除)',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='可视化拖拽界面';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_page_comp` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `parent_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '父组件ID',
  `page_Id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '界面ID',
  `comp_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '组件库ID',
  `component` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '组件名称',
  `config` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '组件配置',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='可视化拖拽页面组件';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_share` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `drag_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '在线仪表盘设计器id',
  `preview_url` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '预览地址',
  `preview_lock` varchar(4) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '密码锁',
  `last_update_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  `term_of_validity` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '有效期(0:永久有效，1:1天，7:7天)',
  `status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '是否过期(0未过期，1已过期)',
  `preview_lock_status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '是否为密码锁(0 否,1是)',
  `share_token` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '分享token',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_ods_drag_id` (`drag_id`) USING BTREE COMMENT '仪表盘id唯一索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='仪表盘预览分享表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_table_relation` (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `aggregation_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '聚合表名称',
  `aggregation_desc` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '聚合表描述',
  `relation_forms` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '关联表单',
  `filter_condition` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '过滤条件',
  `header_fields` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '表头字段',
  `calculate_fields` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '公式字段',
  `validate_info` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '校验信息',
  `del_flag` tinyint(1) DEFAULT NULL COMMENT '删除状态(0-正常,1-已删除)',
  `low_app_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '应用ID',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_aggregation_name` (`aggregation_name`) USING BTREE,
  KEY `idx_del_flag` (`del_flag`) USING BTREE,
  KEY `idx_tenant_id` (`tenant_id`) USING BTREE,
  KEY `idx_create_by` (`create_by`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='仪表盘聚合表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_graphreport_head` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '图表名称',
  `code` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '图表编码',
  `cgr_sql` varchar(5000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '查询数据SQL',
  `xaxis_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '' COMMENT 'X轴数据字段',
  `yaxis_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '' COMMENT 'Y轴数据字段',
  `yaxis_text` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '' COMMENT 'y轴文字描述',
  `content` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `extend_js` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '扩展JS',
  `graph_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '图表类型',
  `is_combination` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT 'combination' COMMENT '是否组合',
  `display_template` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '展示模板',
  `data_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据类型',
  `db_source` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '动态数据源',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `low_app_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关联的应用ID',
  `create_time` datetime DEFAULT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_gpreport_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_graphreport_item` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `graphreport_head_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主表ID',
  `field_name` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段名',
  `field_txt` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段文本',
  `is_show` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否列表显示',
  `is_total` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否计算总计（仅对数值有效）',
  `search_flag` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否查询',
  `search_mode` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询模式',
  `dict_code` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典Code',
  `field_href` varchar(120) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段href',
  `field_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段类型',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `replace_val` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '取值表达式',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ogi_graphreport_head_id` (`graphreport_head_id`) USING BTREE,
  KEY `idx_ogi_is_show` (`is_show`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='jform_graphreport_item';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_graphreport_params` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `head_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'Online图表ID',
  `param_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '参数字段',
  `param_txt` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数文本',
  `param_value` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数默认值',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `onl_graphreport_param_head_id` (`head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='Online图表：参数表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_graphreport_templet` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `templet_code` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `templet_name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '报表名称',
  `templet_style` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '报表风格模板（单排、双排、Tab模式、分组模式-根据配置动态展示、可自定义...）',
  `create_time` datetime DEFAULT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_graphreport_templet_item` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `graphreport_templet_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `graphreport_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '图表编码',
  `graphreport_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '图表类型（饼状图、曲线图、柱状图、数据列表等）',
  `group_num` int DEFAULT NULL COMMENT '组合数字，默认值0 非必填',
  `group_style` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组合展示风格（1 卡片，2 tab）非必填',
  `group_txt` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '分组描述',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `is_show` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否显示 1显示 0不显示，默认1',
  `create_time` datetime DEFAULT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ogti_grreport_tempid` (`graphreport_templet_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `open_api` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '接口名称',
  `request_method` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '请求方法',
  `request_url` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '接口地址',
  `white_list` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'IP白名单，支持IP、CIDR、通配符，逗号或换行分隔',
  `comment` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '白名单备注说明',
  `body` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '请求体内容',
  `origin_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '原始地址',
  `status` int DEFAULT NULL COMMENT '状态',
  `del_flag` int DEFAULT NULL COMMENT '删除标识',
  `create_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `headers_json` json DEFAULT NULL COMMENT '请求头json',
  `params_json` json DEFAULT NULL COMMENT '请求参数json',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='接口表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `open_api_auth` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '授权名称',
  `ak` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'AK',
  `sk` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'SK',
  `create_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `system_user_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '关联系统用户名',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `open_api_log` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `api_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '接口ID',
  `call_auth_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '调用ID',
  `call_time` datetime DEFAULT NULL COMMENT '调用时间',
  `used_time` bigint DEFAULT NULL COMMENT '耗时',
  `response_time` datetime DEFAULT NULL COMMENT '响应时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='调用记录表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `open_api_permission` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `api_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '接口ID',
  `api_auth_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '认证ID',
  `create_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='openapi授权';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `oss_file` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `file_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件名称',
  `url` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件地址',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='Oss File';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_blob_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `BLOB_DATA` blob,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_blob_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `qrtz_triggers` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_calendars` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `CALENDAR_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `CALENDAR` blob NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`CALENDAR_NAME`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_cron_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `CRON_EXPRESSION` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TIME_ZONE_ID` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_cron_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `qrtz_triggers` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_fired_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `ENTRY_ID` varchar(95) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `INSTANCE_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `FIRED_TIME` bigint NOT NULL,
  `SCHED_TIME` bigint NOT NULL,
  `PRIORITY` int NOT NULL,
  `STATE` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `JOB_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `IS_NONCONCURRENT` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `REQUESTS_RECOVERY` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`SCHED_NAME`,`ENTRY_ID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_job_details` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `DESCRIPTION` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `JOB_CLASS_NAME` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `IS_DURABLE` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `IS_NONCONCURRENT` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `IS_UPDATE_DATA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `REQUESTS_RECOVERY` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_DATA` blob,
  PRIMARY KEY (`SCHED_NAME`,`JOB_NAME`,`JOB_GROUP`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_locks` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `LOCK_NAME` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`LOCK_NAME`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_paused_trigger_grps` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_GROUP`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_scheduler_state` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `INSTANCE_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `LAST_CHECKIN_TIME` bigint NOT NULL,
  `CHECKIN_INTERVAL` bigint NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`INSTANCE_NAME`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_simple_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `REPEAT_COUNT` bigint NOT NULL,
  `REPEAT_INTERVAL` bigint NOT NULL,
  `TIMES_TRIGGERED` bigint NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_simple_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `qrtz_triggers` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_simprop_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `STR_PROP_1` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `STR_PROP_2` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `STR_PROP_3` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `INT_PROP_1` int DEFAULT NULL,
  `INT_PROP_2` int DEFAULT NULL,
  `LONG_PROP_1` bigint DEFAULT NULL,
  `LONG_PROP_2` bigint DEFAULT NULL,
  `DEC_PROP_1` decimal(13,4) DEFAULT NULL,
  `DEC_PROP_2` decimal(13,4) DEFAULT NULL,
  `BOOL_PROP_1` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `BOOL_PROP_2` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_simprop_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `qrtz_triggers` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `DESCRIPTION` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `NEXT_FIRE_TIME` bigint DEFAULT NULL,
  `PREV_FIRE_TIME` bigint DEFAULT NULL,
  `PRIORITY` int DEFAULT NULL,
  `TRIGGER_STATE` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_TYPE` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `START_TIME` bigint NOT NULL,
  `END_TIME` bigint DEFAULT NULL,
  `CALENDAR_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `MISFIRE_INSTR` smallint DEFAULT NULL,
  `JOB_DATA` blob,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  KEY `SCHED_NAME` (`SCHED_NAME`,`JOB_NAME`,`JOB_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `JOB_NAME`, `JOB_GROUP`) REFERENCES `qrtz_job_details` (`SCHED_NAME`, `JOB_NAME`, `JOB_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_dxtj` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '姓名',
  `gtime` datetime DEFAULT NULL COMMENT '雇佣日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '职务',
  `jphone` varchar(125) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '家庭电话',
  `birth` datetime DEFAULT NULL COMMENT '出生日期',
  `hukou` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '户口所在地',
  `laddress` varchar(125) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '联系地址',
  `jperson` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '紧急联系人',
  `sex` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'xingbie',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_employee` (
  `id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `num` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '编号',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '姓名',
  `sex` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '性别',
  `birthday` datetime DEFAULT NULL COMMENT '出生日期',
  `nation` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '民族',
  `political` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '政治面貌',
  `native_place` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '籍贯',
  `height` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '身高',
  `weight` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '体重',
  `health` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '健康状况',
  `id_card` varchar(80) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '身份证号',
  `education` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '学历',
  `school` varchar(80) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '毕业学校',
  `major` varchar(80) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '专业',
  `address` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '联系地址',
  `zip_code` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '邮编',
  `email` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'Email',
  `phone` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '手机号',
  `foreign_language` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '外语语种',
  `foreign_language_level` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '外语水平',
  `computer_level` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '计算机水平',
  `graduation_time` datetime DEFAULT NULL COMMENT '毕业时间',
  `arrival_time` datetime DEFAULT NULL COMMENT '到职时间',
  `positional_titles` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职称',
  `education_experience` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '教育经历',
  `work_experience` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '工作经历',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `del_flag` tinyint(1) DEFAULT NULL COMMENT '删除标识0-正常,1-已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_gongsi` (
  `id` int NOT NULL AUTO_INCREMENT,
  `gname` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '货品名称',
  `gdata` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '返利',
  `tdata` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '备注',
  `didian` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `zhaiyao` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `num` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_jianpiao` (
  `id` int NOT NULL AUTO_INCREMENT,
  `bnum` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `ftime` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `sfkong` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `kaishi` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `jieshu` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `hezairen` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `jpnum` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `shihelv` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `s_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=87 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_order_main` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `order_code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '订单编码',
  `order_date` datetime DEFAULT NULL COMMENT '下单时间',
  `descc` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `xiala` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '下拉多选',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_order_product` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `product_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '产品名字',
  `price` double(32,0) DEFAULT NULL COMMENT '价格',
  `num` int DEFAULT NULL COMMENT '数量',
  `descc` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `order_fk_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '订单外键ID',
  `pro_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '产品类型',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_announcement` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `titile` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '标题',
  `msg_content` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '内容',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `sender` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发布人',
  `priority` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '优先级（L低，M中，H高）',
  `msg_category` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '2' COMMENT '消息类型1:通知公告2:系统消息',
  `msg_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '通告对象类型（USER:指定用户，ALL:全体用户）',
  `send_status` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发布状态（0未发布，1已发布，2已撤销）',
  `send_time` datetime DEFAULT NULL COMMENT '发布时间',
  `cancel_time` datetime DEFAULT NULL COMMENT '撤销时间',
  `del_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '删除状态（0，正常，1已删除）',
  `bus_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '业务类型(email:邮件 bpm:流程 tenant_invite:租户邀请)',
  `bus_id` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '业务id',
  `open_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '打开方式(组件：component 路由：url)',
  `open_page` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组件/路由 地址',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `user_ids` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '指定用户',
  `msg_abstract` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '摘要/扩展业务参数',
  `dt_task_id` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '钉钉task_id，用于撤回消息',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `files` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '附件',
  `visits_num` int DEFAULT NULL COMMENT '访问次数',
  `iz_top` int DEFAULT '0' COMMENT '是否置顶（0:否;  1:是）',
  `iz_approval` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否审批（0否 1是）',
  `bpm_status` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '流程状态',
  `msg_classify` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '消息归类',
  `notice_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '通知类型(system:系统消息、file:知识库、flow:流程、plan:日程计划、meeting:会议)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sanno_endtime` (`end_time`) USING BTREE,
  KEY `idx_sanno_start_time` (`start_time`) USING BTREE,
  KEY `idx_sanno_msg_type` (`msg_type`) USING BTREE,
  KEY `idx_sanno_send_status` (`send_status`) USING BTREE,
  KEY `idx_sanno_del_flag` (`del_flag`) USING BTREE,
  KEY `idx_sanno_tenant_id` (`tenant_id`) USING BTREE,
  KEY `idx_sanno_sender` (`sender`) USING BTREE,
  KEY `idx_sanno_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='系统通告表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_announcement_send` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `annt_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '通告ID',
  `user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户id',
  `read_flag` int DEFAULT NULL COMMENT '阅读状态（0未读，1已读）',
  `read_time` datetime DEFAULT NULL COMMENT '阅读时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `star_flag` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '标星状态( 1为标星 空/0没有标星)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sacm_annt_id` (`annt_id`) USING BTREE,
  KEY `idx_sacm_user_id` (`user_id`) USING BTREE,
  KEY `idx_sacm_read_flag` (`read_flag`) USING BTREE,
  KEY `idx_sacm_star_flag` (`star_flag`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户通告阅读标记表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_category` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `pid` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '父级节点',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型名称',
  `code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型编码',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门',
  `has_child` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否有子节点',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `index_scg_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_check_rule` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `rule_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则名称',
  `rule_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则Code',
  `rule_json` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则JSON',
  `rule_description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则描述',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_scr_rule_code` (`rule_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_comment` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `table_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表名',
  `table_data_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '数据id',
  `from_user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '来源用户id',
  `to_user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发送给用户id(允许为空)',
  `comment_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '评论id(允许为空，不为空时，则为回复)',
  `comment_content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '回复内容',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_table_data_id` (`table_name`,`table_data_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='系统评论回复表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_data_log` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人真实名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `data_table` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表名',
  `data_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据ID',
  `data_content` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '数据内容',
  `data_version` int DEFAULT NULL COMMENT '版本号',
  `type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT 'json' COMMENT '类型',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sdl_data_table_id` (`data_table`,`data_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_data_source` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据源编码',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据源名称',
  `remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `db_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据库类型',
  `db_driver` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '驱动类',
  `db_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据源地址',
  `db_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据库名称',
  `db_username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户名',
  `db_password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '密码',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_sdc_rule_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_depart` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'ID',
  `parent_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '父机构ID',
  `depart_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '机构/部门名称',
  `depart_name_en` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '英文名',
  `depart_name_abbr` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '缩写',
  `depart_order` int DEFAULT '0' COMMENT '排序',
  `description` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `org_category` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '1' COMMENT '机构类别 1公司，2部门，3岗位，4子公司',
  `org_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '树深度层级level',
  `org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '机构编码',
  `mobile` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '手机号',
  `fax` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '传真',
  `address` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '地址',
  `memo` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `status` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '状态（1启用，0不启用）',
  `del_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '删除状态（0，正常，1已删除）',
  `qywx_identifier` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '对接企业微信的ID',
  `ding_identifier` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '对接钉钉部门的ID',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `iz_leaf` tinyint(1) DEFAULT '0' COMMENT '是否有叶子节点: 1是0否',
  `position_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职级id',
  `dep_post_parent_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '上级岗位id',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_depart_org_code` (`org_code`) USING BTREE,
  KEY `idx_sd_parent_id` (`parent_id`) USING BTREE,
  KEY `idx_sd_depart_order` (`depart_order`) USING BTREE,
  KEY `idx_sd_position_id` (`position_id`) USING BTREE,
  KEY `idx_sd_dep_post_parent_id` (`dep_post_parent_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='组织机构表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_depart_permission` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `depart_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门id',
  `permission_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '权限id',
  `data_rule_ids` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据规则id',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='部门权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_depart_role` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `depart_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门id',
  `role_name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门角色名称',
  `role_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门角色编码',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='部门角色表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_depart_role_permission` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `depart_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门id',
  `role_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '角色id',
  `permission_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '权限id',
  `data_rule_ids` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据权限ids',
  `operate_date` datetime DEFAULT NULL COMMENT '操作时间',
  `operate_ip` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '操作ip',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sdrp_role_per_id` (`role_id`,`permission_id`) USING BTREE,
  KEY `idx_sdrp_role_id` (`role_id`) USING BTREE,
  KEY `idx_sdrp_per_id` (`permission_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='部门角色权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_depart_role_user` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户id',
  `drole_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '角色id',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sdr_user_id` (`user_id`) USING BTREE,
  KEY `idx_sdr_role_id` (`drole_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='部门角色用户表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_dict` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `dict_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典名称',
  `dict_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典编码',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `del_flag` int DEFAULT NULL COMMENT '删除状态',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `type` int(1) unsigned zerofill DEFAULT '0' COMMENT '字典类型0为string,1为number',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `low_app_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '低代码应用ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_sd_dict_code` (`dict_code`) USING BTREE,
  KEY `uk_sd_tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_dict_item` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `dict_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典id',
  `item_text` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典项文本',
  `item_value` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典项值',
  `item_color` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典项颜色',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `sort_order` int DEFAULT NULL COMMENT '排序',
  `status` int DEFAULT NULL COMMENT '状态（1启用 0不启用）',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sditem_role_dict_id` (`dict_id`) USING BTREE,
  KEY `idx_sditem_role_sort_order` (`sort_order`) USING BTREE,
  KEY `idx_sditem_status` (`status`) USING BTREE,
  KEY `idx_sditem_dict_val` (`dict_id`,`item_value`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_files` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `file_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件名称',
  `url` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件地址',
  `file_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文档类型（folder:文件夹 excel:excel doc:word ppt:ppt image:图片  archive:其他文档 video:视频 pdf:pdf）',
  `store_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件上传类型(temp/本地上传(临时文件) manage/知识库)',
  `parent_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '父级id',
  `tenant_id` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '租户id',
  `file_size` double(13,2) DEFAULT NULL COMMENT '文件大小（kb）',
  `iz_folder` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否文件夹(1：是  0：否)',
  `iz_root_folder` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否为1级文件夹，允许为空 (1：是 )',
  `iz_star` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否标星(1：是  0：否)',
  `down_count` int DEFAULT NULL COMMENT '下载次数',
  `read_count` int DEFAULT NULL COMMENT '阅读次数',
  `share_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '分享链接',
  `share_perms` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '分享权限(1.关闭分享 2.允许所有联系人查看 3.允许任何人查看)',
  `enable_down` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否允许下载(1：是  0：否)',
  `enable_updat` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否允许修改(1：是  0：否)',
  `del_flag` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '删除状态(0-正常,1-删除至回收站)',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_tenant_id` (`tenant_id`) USING BTREE,
  KEY `index_del_flag` (`del_flag`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='知识库-文档管理';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_fill_rule` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `rule_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则名称',
  `rule_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则Code',
  `rule_class` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则实现类',
  `rule_params` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则参数',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_sfr_rule_code` (`rule_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_form_file` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `table_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表名',
  `table_data_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '数据id',
  `file_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关联文件id',
  `file_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件类型(text:文本, excel:excel doc:word ppt:ppt image:图片  archive:其他文档 video:视频 pdf:pdf）)',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_table_form` (`table_name`,`table_data_id`) USING BTREE,
  KEY `index_file_id` (`file_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_gateway_route` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `router_id` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '路由ID',
  `name` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '服务名',
  `uri` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '服务地址',
  `predicates` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '断言',
  `filters` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '过滤器',
  `retryable` int DEFAULT NULL COMMENT '是否重试:0-否 1-是',
  `strip_prefix` int DEFAULT NULL COMMENT '是否忽略前缀0-否 1-是',
  `persistable` int DEFAULT NULL COMMENT '是否为保留数据:0-否 1-是',
  `show_api` int DEFAULT NULL COMMENT '是否在接口文档中展示:0-否 1-是',
  `status` int DEFAULT NULL COMMENT '状态:0-无效 1-有效',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门',
  `del_flag` int DEFAULT NULL COMMENT '删除状态',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_log` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `log_type` int DEFAULT NULL COMMENT '日志类型（1登录日志，2操作日志, 3.租户操作日志）',
  `log_content` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '日志内容',
  `operate_type` int DEFAULT NULL COMMENT '操作类型',
  `userid` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '操作用户账号',
  `username` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '操作用户名称',
  `ip` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'IP',
  `method` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求java方法',
  `request_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求路径',
  `request_param` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '请求参数',
  `request_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求类型',
  `cost_time` bigint DEFAULT NULL COMMENT '耗时',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  `client_type` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '客户端类型 pc:电脑端 app:手机端 h5:移动网页端',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sl_userid` (`userid`) USING BTREE,
  KEY `idx_sl_log_type` (`log_type`) USING BTREE,
  KEY `idx_sl_operate_type` (`operate_type`) USING BTREE,
  KEY `idx_sl_create_time` (`create_time`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='系统日志表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_permission` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `parent_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '父id',
  `name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '菜单标题',
  `url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '路径',
  `component` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组件',
  `is_route` tinyint(1) DEFAULT '1' COMMENT '是否路由菜单: 0:不是  1:是（默认值1）',
  `component_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组件名字',
  `redirect` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '一级菜单跳转地址',
  `menu_type` int DEFAULT NULL COMMENT '菜单类型(0:一级菜单; 1:子菜单:2:按钮权限)',
  `perms` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '菜单权限编码',
  `perms_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '权限策略1显示2禁用',
  `sort_no` double(8,2) DEFAULT NULL COMMENT '菜单排序',
  `always_show` tinyint(1) DEFAULT NULL COMMENT '聚合子路由: 1是0否',
  `icon` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '菜单图标',
  `is_leaf` tinyint(1) DEFAULT NULL COMMENT '是否叶子节点:    1是0否',
  `keep_alive` tinyint(1) DEFAULT NULL COMMENT '是否缓存该页面:    1:是   0:不是',
  `hidden` tinyint DEFAULT '0' COMMENT '是否隐藏路由: 0否,1是',
  `hide_tab` tinyint DEFAULT NULL COMMENT '是否隐藏tab: 0否,1是',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `create_by` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除状态 0正常 1已删除',
  `rule_flag` int DEFAULT '0' COMMENT '是否添加数据权限1是0否',
  `status` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮权限状态(0无效1有效)',
  `internal_or_external` tinyint(1) DEFAULT NULL COMMENT '外链菜单打开方式 0/内部打开 1/外部打开',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_menu_type` (`menu_type`) USING BTREE,
  KEY `index_menu_hidden` (`hidden`) USING BTREE,
  KEY `index_menu_status` (`status`) USING BTREE,
  KEY `index_menu_del_flag` (`del_flag`) USING BTREE,
  KEY `index_menu_url` (`url`) USING BTREE,
  KEY `index_menu_sort_no` (`sort_no`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='菜单权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_permission_data_rule` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'ID',
  `permission_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '菜单ID',
  `rule_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '规则名称',
  `rule_column` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段',
  `rule_conditions` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '条件',
  `rule_value` varchar(300) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '规则值',
  `status` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '权限有效状态1有0否',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_spdr_permission_id` (`permission_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_position` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职务编码',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职务级别名称',
  `post_level` int DEFAULT NULL COMMENT '职务等级',
  `company_id` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '公司id',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `sys_org_code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组织机构编码',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='职务级别';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_quartz_job` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `del_flag` int DEFAULT NULL COMMENT '删除状态',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `job_class_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '任务类名',
  `cron_expression` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'cron表达式',
  `parameter` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `status` int DEFAULT NULL COMMENT '状态 0正常 -1停止',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `role_name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '角色名称',
  `role_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '角色编码',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_sys_role_role_code` (`role_code`) USING BTREE,
  KEY `idx_sysrole_tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='角色表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role_index` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `role_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '角色编码',
  `url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '路由地址',
  `component` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组件',
  `is_route` tinyint(1) DEFAULT '1' COMMENT '是否路由菜单: 0:不是  1:是（默认值1）',
  `priority` int DEFAULT '0' COMMENT '优先级',
  `status` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '状态0:无效 1:有效',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门',
  `relation_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '关联关系(ROLE:角色 USER:用户)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sri_role_code` (`role_code`) USING BTREE,
  KEY `idx_sri_status` (`status`) USING BTREE,
  KEY `idx_sri_priority` (`priority`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色首页表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role_permission` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `role_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '角色id',
  `permission_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '权限id',
  `data_rule_ids` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据权限ids',
  `operate_date` datetime DEFAULT NULL COMMENT '操作时间',
  `operate_ip` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '操作ip',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_srp_role_per_id` (`role_id`,`permission_id`) USING BTREE,
  KEY `idx_srp_role_id` (`role_id`) USING BTREE,
  KEY `idx_srp_permission_id` (`permission_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='角色权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_sms` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'ID',
  `es_title` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '消息标题',
  `es_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发送方式：参考枚举MessageTypeEnum',
  `es_receiver` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '接收人',
  `es_param` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发送所需参数Json格式',
  `es_content` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '推送内容',
  `es_send_time` datetime DEFAULT NULL COMMENT '推送时间',
  `es_send_status` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '推送状态 0未推送 1推送成功 2推送失败 -1失败不再发送',
  `es_send_num` int DEFAULT NULL COMMENT '发送次数 超过5次不再发送',
  `es_result` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '推送失败原因',
  `remark` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ss_es_type` (`es_type`) USING BTREE,
  KEY `idx_ss_es_receiver` (`es_receiver`) USING BTREE,
  KEY `idx_ss_es_send_time` (`es_send_time`) USING BTREE,
  KEY `idx_ss_es_send_status` (`es_send_status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_sms_template` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `template_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '模板标题',
  `template_code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '模板CODE',
  `template_type` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '模板类型：1短信 2邮件 3微信',
  `template_category` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '模版分类：notice通知公告 other其他',
  `template_content` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '模板内容',
  `template_test_json` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '模板测试json',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `use_status` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否使用中 1是0否',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_sst_template_code` (`template_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_table_white_list` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键id',
  `table_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '允许的表名',
  `field_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '允许的字段名，多个用逗号分割',
  `status` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '1' COMMENT '状态，1=启用，0=禁用',
  `create_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_sys_table_white_list_table_name` (`table_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='系统表白名单';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_tenant` (
  `id` int NOT NULL COMMENT '租户编码',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '租户名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `begin_date` datetime DEFAULT NULL COMMENT '开始时间',
  `end_date` datetime DEFAULT NULL COMMENT '结束时间',
  `status` int DEFAULT NULL COMMENT '状态 1正常 0冻结',
  `trade` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属行业',
  `company_size` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '公司规模',
  `company_address` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '公司地址',
  `company_logo` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '公司logo',
  `house_number` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '门牌号',
  `work_place` varchar(100) CHARACTER SET utf32 COLLATE utf32_general_ci DEFAULT NULL COMMENT '工作地点',
  `secondary_domain` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '二级域名',
  `login_bkgd_img` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '登录背景图片',
  `position` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '职级',
  `department` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '部门',
  `del_flag` tinyint(1) DEFAULT '0' COMMENT '删除状态(0-正常,1-已删除)',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `apply_status` int DEFAULT NULL COMMENT '允许申请管理员 1允许 0不允许',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='多租户信息表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_tenant_pack` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键id',
  `tenant_id` int DEFAULT NULL COMMENT '租户id',
  `pack_name` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '产品包名',
  `status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '开启状态(0 未开启 1开启)',
  `remarks` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` date DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` date DEFAULT NULL COMMENT '更新时间',
  `pack_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '编码,默认添加的三个管理员需要设置编码',
  `pack_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'custom' COMMENT '产品包类型(default 默认产品包 custom 自定义产品包)',
  `iz_sysn` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '自动分配给用户(0否 1是)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx__stp_tenant_id_pack_code` (`tenant_id`,`pack_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='租户产品包';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_tenant_pack_perms` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键编号',
  `pack_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '租户产品包名称',
  `permission_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '菜单id',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` date DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` date DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_stpp_pack_id` (`pack_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='租户产品包和菜单关系表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_tenant_pack_user` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `pack_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '租户产品包ID',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户ID',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `status` int DEFAULT NULL COMMENT '状态 正常状态1 申请状态0',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_tpu_pack_id` (`pack_id`) USING BTREE,
  KEY `idx_tpu_user_id` (`user_id`) USING BTREE,
  KEY `idx_tpu_tenant_id` (`tenant_id`) USING BTREE,
  KEY `idx_tpu_status` (`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='租户套餐人员表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_third_account` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '编号',
  `sys_user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '第三方登录id',
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '头像',
  `status` tinyint(1) DEFAULT NULL COMMENT '状态(1-正常,2-冻结)',
  `del_flag` tinyint(1) DEFAULT NULL COMMENT '删除状态(0-正常,1-已删除)',
  `realname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '真实姓名',
  `tenant_id` int DEFAULT '0' COMMENT '租户id',
  `third_user_uuid` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '第三方账号',
  `third_user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '第三方app用户账号',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `third_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '登录来源',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_stat_third_type_user_id` (`third_type`,`third_user_id`) USING BTREE,
  UNIQUE KEY `uniq_sta_third_user_id_third_type` (`third_user_id`,`third_type`,`tenant_id`) USING BTREE,
  UNIQUE KEY `uniq_sta_third_user_uuid_third_type` (`third_user_uuid`,`third_type`,`tenant_id`) USING BTREE,
  KEY `idx_sta_sys_user_id_third_type` (`sys_user_id`,`third_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_third_app_config` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `tenant_id` int NOT NULL DEFAULT '0' COMMENT '租户id',
  `agent_id` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '钉钉/企业微信应用id',
  `client_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '钉钉/企业微信 应用id',
  `client_secret` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '钉钉/企业微信应用id对应的秘钥',
  `corp_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '钉钉企业id',
  `third_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '第三方类别(dingtalk 钉钉 wechat_enterprise 企业微信)',
  `status` int DEFAULT '1' COMMENT '是否启用(0-否,1-是)',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_stac_tenant_id` (`tenant_id`) USING BTREE,
  KEY `idx_stac_third_type` (`third_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='租户第三方配置表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_ugroup` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `group_name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户组名称',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_su_tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户组表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_ugroup_user` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户id',
  `group_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户组id',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_suu_user_id` (`user_id`) USING BTREE,
  KEY `idx_suu_group_id` (`group_id`) USING BTREE,
  KEY `idx_suu_user_role_id` (`user_id`,`group_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户组关系表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `username` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '登录账号',
  `realname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '真实姓名',
  `password` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '密码',
  `salt` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'md5密码盐',
  `avatar` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '头像',
  `birthday` date DEFAULT NULL COMMENT '生日',
  `sex` tinyint(1) DEFAULT NULL COMMENT '性别(0-默认未知,1-男,2-女)',
  `email` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '电子邮件',
  `phone` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '电话',
  `org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '登录会话的机构编码',
  `status` tinyint(1) DEFAULT NULL COMMENT '性别(1-正常,2-冻结)',
  `del_flag` tinyint(1) DEFAULT NULL COMMENT '删除状态(0-正常,1-已删除)',
  `third_id` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '第三方登录的唯一标识',
  `third_type` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '第三方类型',
  `activiti_sync` tinyint(1) DEFAULT NULL COMMENT '同步工作流引擎(1-同步,0-不同步)',
  `work_no` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '工号，唯一键',
  `telephone` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '座机号',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `user_identity` tinyint(1) DEFAULT NULL COMMENT '身份（1普通成员 2上级）',
  `depart_ids` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '负责部门',
  `client_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '设备ID',
  `login_tenant_id` int DEFAULT NULL COMMENT '上次登录选择租户ID',
  `bpm_status` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '流程入职离职状态',
  `sign_enable` tinyint(1) DEFAULT NULL COMMENT '是否启用个性签名（0 否 1是）',
  `sign` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '个性签名',
  `main_dep_post_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主岗位（部门岗位id）',
  `position_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职务(字典)',
  `last_pwd_update_time` datetime DEFAULT NULL COMMENT '上一次修改密码的时间',
  `sort` int DEFAULT NULL COMMENT '排序',
  `iz_hide_contact` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否隐藏联系方式（0 否 1是）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_sys_user_work_no` (`work_no`) USING BTREE,
  UNIQUE KEY `uniq_sys_user_username` (`username`) USING BTREE,
  UNIQUE KEY `uniq_sys_user_phone` (`phone`) USING BTREE,
  UNIQUE KEY `uniq_sys_user_email` (`email`) USING BTREE,
  KEY `idx_su_status` (`status`) USING BTREE,
  KEY `idx_su_del_flag` (`del_flag`) USING BTREE,
  KEY `idx_su_del_username` (`username`,`del_flag`) USING BTREE,
  KEY `idx_su_main_dep_post_id` (`main_dep_post_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_dep_post` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户id',
  `dep_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '部门岗位id',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sudp_user_id` (`user_id`) USING BTREE,
  KEY `idx_sudp_dep_id` (`dep_id`) USING BTREE,
  KEY `idx_sudp_user_dep_id` (`user_id`,`dep_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_depart` (
  `ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户id',
  `dep_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门id',
  PRIMARY KEY (`ID`) USING BTREE,
  UNIQUE KEY `idx_sud_user_dep_id` (`user_id`,`dep_id`) USING BTREE,
  KEY `idx_sud_user_id` (`user_id`) USING BTREE,
  KEY `idx_sud_dep_id` (`dep_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_position` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户id',
  `position_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '职位id',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sup_user_id` (`user_id`) USING BTREE,
  KEY `idx_sup_position_id` (`position_id`) USING BTREE,
  KEY `idx_sup_user_position_id` (`user_id`,`position_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_role` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户id',
  `role_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '角色id',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sur_user_id` (`user_id`) USING BTREE,
  KEY `idx_sur_role_id` (`role_id`) USING BTREE,
  KEY `idx_sur_user_role_id` (`user_id`,`role_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户角色表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_tenant` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键id',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户id',
  `tenant_id` int DEFAULT NULL COMMENT '租户id',
  `status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '状态(1 正常 2 离职 3 待审核 4 拒绝 5 邀请加入)',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sut_user_id` (`user_id`) USING BTREE,
  KEY `idx_sut_tenant_id` (`tenant_id`) USING BTREE,
  KEY `idx_sut_user_rel_tenant` (`user_id`,`tenant_id`) USING BTREE,
  KEY `idx_sut_status` (`status`) USING BTREE,
  KEY `idx_sut_userid_status` (`user_id`,`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='用户租户关系表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_demo` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户名',
  `sex` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '性别',
  `age` int DEFAULT NULL COMMENT '年龄',
  `descc` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `birthday` datetime DEFAULT NULL COMMENT '生日',
  `user_code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户编码',
  `file_kk` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '附件',
  `top_pic` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '头像',
  `chegnshi` varchar(300) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '城市',
  `ceck` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'checkbox',
  `xiamuti` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '下拉多选',
  `search_sel` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '搜索下拉',
  `pop` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '弹窗',
  `sel_table` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '下拉字典表',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_enhance_select` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `province` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '省份',
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '市',
  `area` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '区',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_note` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属部门',
  `name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户名',
  `age` int DEFAULT NULL COMMENT '年龄',
  `sex` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '性别',
  `birthday` datetime DEFAULT NULL COMMENT '生日',
  `contents` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '请假原因',
  `year` date DEFAULT NULL COMMENT '年',
  `sheng` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '地区',
  `month` date DEFAULT NULL COMMENT '月',
  `begin_time` date DEFAULT NULL COMMENT '开始时间',
  `long_ids` bigint DEFAULT NULL COMMENT '长类型',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_online_link` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `pid` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'pid',
  `name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'name',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_order_customer` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属部门',
  `name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '客户名字',
  `sex` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '性别',
  `age` int DEFAULT NULL COMMENT '年龄',
  `birthday` date DEFAULT NULL COMMENT '生日',
  `order_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '订单id',
  `address` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '地址',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_order_main` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `order_code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '订单编码',
  `order_date` datetime DEFAULT NULL COMMENT '下单时间',
  `descc` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `xiala` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '下拉多选',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_order_product` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `product_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '产品名字',
  `price` double(32,0) DEFAULT NULL COMMENT '价格',
  `num` int DEFAULT NULL COMMENT '数量',
  `descc` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `order_fk_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '订单外键ID',
  `pro_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '产品类型',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_person` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sex` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '性别',
  `name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户名',
  `content` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '请假原因',
  `be_date` datetime DEFAULT NULL COMMENT '请假时间',
  `qj_days` int DEFAULT NULL COMMENT '请假天数',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_shoptype_tree` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属部门',
  `type_name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '商品分类',
  `pic` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '分类图片',
  `pid` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '父级节点',
  `has_child` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '是否有子节点',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `jeecg-boot` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `jeecg-boot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `aigc_word_template` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '模版名称',
  `code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '模版编码',
  `header` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci COMMENT '页眉',
  `footer` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci COMMENT '页脚',
  `main` text CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci COMMENT '主体内容',
  `margins` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '页边距',
  `width` int DEFAULT NULL COMMENT '宽度',
  `height` int DEFAULT NULL COMMENT '高度',
  `paper_direction` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '纸张方向 vertical纵向 horizontal横向',
  `watermark` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_unicode_ci DEFAULT NULL COMMENT '水印',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='Word模版';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_app` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用名称',
  `descr` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用描述',
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用图标',
  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用类型',
  `prologue` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '开场白',
  `prompt` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '提示词',
  `model_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '模型id',
  `knowledge_ids` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '知识库',
  `flow_id` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '流程id（多个以逗号分隔）',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态（enable=启用、disable=禁用、release=发布）',
  `msg_num` int DEFAULT NULL COMMENT '历史消息数',
  `metadata` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '元数据',
  `preset_question` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '预设问题',
  `quick_command` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '快捷指令',
  `plugins` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '插件',
  `memory_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '记忆库(知识库的id)',
  `variables` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '存放变量的配置',
  `iz_open_memory` int DEFAULT NULL COMMENT '是否开启记忆(0 不开启，1开启)',
  `memory_prompt` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '记忆和变量提示词',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_ext_data` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '主键ID',
  `biz_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '业务类型标识（ evaluator:评估器；track:测试追踪 ）',
  `name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '名称',
  `descr` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '描述信息',
  `tags` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标签，多个用逗号分隔',
  `data_value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '实际存储内容，json',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态（run:进行中 completed：已完成）',
  `dataset_value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '评测集数据',
  `metadata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '元数据，用于存储补充业务数据信息',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `version` int DEFAULT NULL COMMENT '版本1开始',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_biz` (`biz_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='通用扩展数据表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_flow` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `application_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用名称',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '名称',
  `descr` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '描述',
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '应用图标',
  `chain` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '编排规则',
  `design` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '编排设计',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态（enable=启用、disable=禁用、release=发布）',
  `metadata` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '元数据',
  `trigger_cron` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'cron定时任务触发器配置JSON',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_knowledge` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '知识库名称',
  `descr` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '描述',
  `embed_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '向量模型id',
  `status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态',
  `type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '类型(knowledge知识 memory 记忆)',
  `metadata` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '元数据',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_knowledge_doc` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `knowledge_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '知识库id',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标题',
  `type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '类型',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '内容',
  `status` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态',
  `metadata` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '元数据',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_mcp` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `icon` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '图标',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '名称',
  `descr` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '描述',
  `category` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'mcp' COMMENT '类型（plugin=插件，mcp=MCP）',
  `type` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'mcp类型（sse：sse类型；stdio：标准类型）',
  `endpoint` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '服务端点（SSE类型为URL，stdio类型为命令）',
  `headers` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '请求头（sse类型）、环境变量（stdio类型）',
  `tools` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '工具列表',
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '状态（enable=启用、disable=禁用）',
  `synced` int DEFAULT NULL COMMENT '是否同步',
  `metadata` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '元数据',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='AI MCP';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_model` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '名称',
  `provider` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '供应者',
  `model_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '模型名称',
  `credential` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '凭证信息',
  `base_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'API域名',
  `model_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '模型类型',
  `model_params` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '模型参数',
  `activate_flag` int DEFAULT NULL COMMENT '是否激活（1=是，0=否）',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `airag_prompts` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '主键ID',
  `name` varchar(125) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '提示词名称',
  `prompt_key` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '提示词key',
  `description` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '提示词功能描述',
  `content` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '提示词模板内容，支持变量占位符如 {{variable}}',
  `category` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '提示词分类',
  `tags` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '标签，多个逗号分割',
  `model_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '适配的大模型ID',
  `model_param` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '大模型的参数配置',
  `status` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '0' COMMENT '状态（0:未发布 1:已发布）',
  `version` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '版本号(格式 0.0.1)',
  `del_flag` int DEFAULT NULL COMMENT '删除状态（0未删除 1已删除）',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '租户id',
  UNIQUE KEY `uni_key` (`prompt_key`) USING BTREE,
  KEY `idx_category` (`category`) USING BTREE,
  KEY `idx_status` (`status`) USING BTREE,
  KEY `idx_name` (`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='AI提示词表';
/*!40101 SET character_set_client = @saved_cs_client */;
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
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `chat2bi_table_meta` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '主键',
  `db_source_type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '数据源来源表标识, 如: db_source / api_source / file_source / system_source',
  `db_source_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '对应来源表的主键ID',
  `schema_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Schema名',
  `table_name` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '表名',
  `source_comment` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '表注释-源(同步写入, 每次同步覆盖)',
  `table_comment` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '表注释-用户(用户手动填写, 同步不覆盖)',
  `columns_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '列定义[{name,type,source_comment,comment,is_primary,sample_values,nulltable}]',
  `relations_json` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '关联关系[{column,ref_table,ref_column,type}]',
  `is_enabled` tinyint NOT NULL DEFAULT '1' COMMENT '对LLM可见: 0=否 1=是',
  `synced_time` datetime DEFAULT NULL COMMENT '最近同步时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` int DEFAULT NULL COMMENT '多租户标识',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_source_table` (`db_source_type`,`db_source_id`,`schema_name`,`table_name`) USING BTREE,
  KEY `idx_source` (`db_source_type`,`db_source_id`) USING BTREE,
  KEY `idx_table_name` (`table_name`) USING BTREE,
  KEY `idx_table_name_comment` (`table_name`,`source_comment`(320),`table_comment`(320)) USING BTREE,
  KEY `idx_table_comment` (`table_comment`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='表元数据(同步+手动维护, 支持多数据源表)';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `demo` (
  `id` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `name` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '姓名',
  `key_word` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关键词',
  `punch_time` datetime DEFAULT NULL COMMENT '打卡时间',
  `salary_money` decimal(10,3) DEFAULT NULL COMMENT '工资',
  `bonus_money` double(10,2) DEFAULT NULL COMMENT '奖金',
  `sex` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '性别 {男:1,女:2}',
  `age` int DEFAULT NULL COMMENT '年龄',
  `birthday` date DEFAULT NULL COMMENT '生日',
  `email` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '邮箱',
  `content` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '个人简介',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门编码',
  `tenant_id` int DEFAULT '0',
  `update_count` int DEFAULT NULL COMMENT '乐观锁测试',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `flyway_schema_history` (
  `installed_rank` int NOT NULL,
  `version` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `script` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `checksum` int DEFAULT NULL,
  `installed_by` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `installed_on` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `execution_time` int NOT NULL,
  `success` tinyint(1) NOT NULL,
  PRIMARY KEY (`installed_rank`) USING BTREE,
  KEY `flyway_schema_history_s_idx` (`success`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jeecg_order_customer` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '客户名',
  `sex` varchar(4) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '性别',
  `idcard` varchar(18) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '身份证号码',
  `idcard_pic` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '身份证扫描件',
  `telphone` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '电话1',
  `order_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '外键',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jeecg_order_main` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `order_code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '订单号',
  `ctype` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '订单类型',
  `order_date` datetime DEFAULT NULL COMMENT '订单日期',
  `order_money` double(10,3) DEFAULT NULL COMMENT '订单金额',
  `content` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '订单备注',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `bpm_status` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '流程状态',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jeecg_order_ticket` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `ticket_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '航班号',
  `tickect_date` datetime DEFAULT NULL COMMENT '航班时间',
  `order_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '外键',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_dict` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `dict_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典名称',
  `dict_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典编码',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `del_flag` int DEFAULT NULL COMMENT '删除状态',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `type` int(1) unsigned zerofill DEFAULT '0' COMMENT '字典类型0为string,1为number',
  `tenant_id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多租户标识',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_sd_dict_code` (`dict_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_dict_item` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `dict_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典id',
  `item_text` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典项文本',
  `item_value` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典项值',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `sort_order` int DEFAULT NULL COMMENT '排序',
  `status` int DEFAULT NULL COMMENT '状态（1启用 0不启用）',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sdi_role_dict_id` (`dict_id`) USING BTREE,
  KEY `idx_sdi_role_sort_order` (`sort_order`) USING BTREE,
  KEY `idx_sdi_status` (`status`) USING BTREE,
  KEY `idx_sdi_dict_val` (`dict_id`,`item_value`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '编码',
  `name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '名称',
  `note` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '说明',
  `status` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '状态',
  `type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型',
  `json_str` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'json字符串',
  `api_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求地址',
  `thumb` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '缩略图',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `del_flag` tinyint(1) DEFAULT NULL COMMENT '删除标识0-正常,1-已删除',
  `api_method` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求方法0-get,1-post',
  `api_code` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求编码',
  `template` tinyint(1) DEFAULT NULL COMMENT '是否是模板 0不是,1是',
  `view_count` bigint DEFAULT '0' COMMENT '浏览次数',
  `css_str` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'css增强',
  `js_str` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'js增强',
  `py_str` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'py增强',
  `tenant_id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多租户标识',
  `update_count` int DEFAULT '0' COMMENT '乐观锁版本',
  `submit_form` tinyint(1) DEFAULT NULL COMMENT '是否填报报表 0不是,1是',
  `is_multi_sheet` tinyint DEFAULT NULL COMMENT '是否多sheet报表 1是 0否',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_jmreport_code` (`code`) USING BTREE,
  KEY `uniq_jmreport_createby` (`create_by`) USING BTREE,
  KEY `uniq_jmreport_delflag` (`del_flag`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='在线excel设计器';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_category` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '分类名称',
  `parent_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '父级id',
  `iz_leaf` int DEFAULT NULL COMMENT '是否为叶子节点(0 否 1是)',
  `source_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '来源类型( report 积木报表 screen 大屏  drag 仪表盘)',
  `del_flag` int DEFAULT NULL COMMENT '删除标识(0 正常 1 已删除)',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` timestamp NULL DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` timestamp NULL DEFAULT NULL COMMENT '更新时间',
  `tenant_id` varchar(11) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '租户id',
  `sort_no` int DEFAULT NULL COMMENT '排序',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='分类';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_data_source` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据源名称',
  `report_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '报表_id',
  `code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '编码',
  `remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `db_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据库类型',
  `db_driver` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '驱动类',
  `db_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据源地址',
  `db_username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户名',
  `db_password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '密码',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `connect_times` int DEFAULT '0' COMMENT '连接失败次数',
  `tenant_id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多租户标识',
  `type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '类型(report:报表;drag:仪表盘)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_jmdatasource_report_id` (`report_id`) USING BTREE,
  KEY `idx_jmdatasource_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_db` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `jimu_report_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主键字段',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `db_code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据集编码',
  `db_ch_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据集名字',
  `db_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据源类型',
  `db_table_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据库表名',
  `db_dyn_sql` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '动态查询SQL',
  `db_key` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据源KEY',
  `tb_db_key` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '填报数据源',
  `tb_db_table_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '填报数据表',
  `java_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'java类数据集  类型（spring:springkey,class:java类名）',
  `java_value` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'java类数据源  数值（bean key/java类名）',
  `api_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求地址',
  `api_method` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求方法0-get,1-post',
  `is_list` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '是否是列表0否1是 默认0',
  `is_page` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否作为分页,0:不分页，1:分页',
  `db_source` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据源',
  `db_source_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据库类型 MYSQL ORACLE SQLSERVER',
  `json_data` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'json数据，直接解析json内容',
  `api_convert` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'api转换器',
  `iz_shared_source` int DEFAULT NULL COMMENT '是否为共享数据源(0 否 1 是)',
  `jimu_shared_source_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '指向共享数据集的id',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_jmreportdb_db_key` (`db_key`) USING BTREE,
  KEY `idx_jimu_report_id` (`jimu_report_id`) USING BTREE,
  KEY `idx_db_source_id` (`db_source`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_db_field` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `jimu_report_db_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据源ID',
  `field_name` varchar(80) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段名',
  `field_name_physics` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '物理字段名（文件数据集使用，存的是excel的字段标题）',
  `field_text` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段文本',
  `widget_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '控件类型',
  `widget_width` int DEFAULT NULL COMMENT '控件宽度',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `search_flag` int DEFAULT '0' COMMENT '查询标识0否1是 默认0',
  `search_mode` int DEFAULT NULL COMMENT '查询模式1简单2范围',
  `dict_code` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典编码支持从表中取数据',
  `search_value` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询默认值',
  `search_format` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询时间格式化表达式',
  `ext_json` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '参数配置',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_jrdf_jimu_report_db_id` (`jimu_report_db_id`) USING BTREE,
  KEY `idx_dbfield_order_num` (`order_num`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_db_param` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `jimu_report_head_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '动态报表ID',
  `param_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '参数字段',
  `param_txt` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数文本',
  `param_value` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数默认值',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `search_flag` int DEFAULT NULL COMMENT '查询标识0否1是 默认0',
  `widget_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询控件类型',
  `search_mode` int DEFAULT NULL COMMENT '查询模式1简单2范围',
  `dict_code` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典',
  `search_format` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询时间格式化表达式',
  `ext_json` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '参数配置',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_jrdp_jimu_report_head_id` (`jimu_report_head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_export_job` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '任务名称',
  `begin_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `exec_interval` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '执行频率',
  `report_conf` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '导出报表配置',
  `last_run_time` datetime DEFAULT NULL COMMENT '最后执行时间',
  `receiver_email` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '接收通知的邮件',
  `file_sync_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '文件同步路径',
  `status` int DEFAULT NULL COMMENT '状态(0:停止;1:启动)',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `tenant_id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多租户标识',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='积木报表导出计划表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_export_log` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `batch_no` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '批次编号',
  `export_channel` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '导出渠道',
  `export_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '导出类型',
  `report_id` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '报表id',
  `download_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '下载路径',
  `status` varchar(15) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '状态',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '多租户标识',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='积木报表自动导出记录表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_ext_data` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键ID',
  `biz_type` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '业务类型标识，如 report_share、temp_config 等',
  `name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '名称，展示用',
  `descr` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '描述信息',
  `tags` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '标签，多个用逗号分隔',
  `data_value` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '实际存储内容',
  `metadata` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '元数据，用于存储补充信息',
  `status` tinyint DEFAULT '1' COMMENT '状态标识：1正常 0禁用',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_biz` (`biz_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='通用扩展数据表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_icon_lib` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '图片名称',
  `type` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '图片类型',
  `image_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '图片地址',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` int DEFAULT NULL COMMENT '租户id',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='积木图库表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_link` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键id',
  `report_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '积木设计器id',
  `parameter` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '参数',
  `eject_type` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '弹出方式（0 当前页面 1 新窗口）',
  `link_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '链接名称',
  `api_method` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '请求方法0-get,1-post',
  `link_type` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '链接方式(0 网络报表 1 网络连接 2 图表联动)',
  `api_url` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '外网api',
  `link_chart_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '联动图表的ID',
  `expression` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '表达式',
  `requirement` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '条件',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `uniq_link_reportid` (`report_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='超链接配置表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_map` (
  `id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `label` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '地图名称',
  `name` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '地图编码',
  `data` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '地图数据',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `del_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '0表示未删除,1表示删除',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_jmreport_map_name` (`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='地图配置表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_share` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `report_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '在线excel设计器id',
  `preview_url` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '预览地址',
  `preview_lock` varchar(4) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '密码锁',
  `last_update_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  `term_of_validity` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '有效期(0:永久有效，1:1天，2:7天)',
  `status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '是否过期(0未过期，1已过期)',
  `preview_lock_status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '是否为密码锁(0 否,1是)',
  `share_token` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '分享token',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_report_id` (`report_id`) USING BTREE,
  UNIQUE KEY `uniq_jrs_report_id` (`report_id`) USING BTREE COMMENT '报表id唯一索引',
  KEY `idx_jrs_share_token` (`share_token`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='积木报表预览权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jimu_report_sheet` (
  `id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键（Sheet ID）',
  `report_id` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '报表ID',
  `sheet_name` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Sheet名称',
  `sheet_order` int NOT NULL COMMENT '排序（可以为负数，负数表示在默认sheet前面）',
  `json_str` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '该sheet的完整jsonStr',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `create_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `update_by` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_report_id` (`report_id`) USING BTREE,
  KEY `idx_sheet_order` (`report_id`,`sheet_order`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='报表Sheet表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `joa_demo` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'ID',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请假人',
  `days` int DEFAULT NULL COMMENT '请假天数',
  `begin_date` datetime DEFAULT NULL COMMENT '开始时间',
  `end_date` datetime DEFAULT NULL COMMENT '请假结束时间',
  `reason` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请假原因',
  `bpm_status` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '1' COMMENT '流程状态',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人id',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='流程测试';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `oauth2_registered_client` (
  `id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `client_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `client_id_issued_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `client_secret` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `client_secret_expires_at` timestamp NULL DEFAULT NULL,
  `client_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `client_authentication_methods` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `authorization_grant_types` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `redirect_uris` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `post_logout_redirect_uris` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `scopes` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `client_settings` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `token_settings` varchar(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_auth_data` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `cgform_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'online表ID',
  `rule_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则名',
  `rule_column` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则列',
  `rule_operator` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则条件 大于小于like',
  `rule_value` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则值',
  `status` int DEFAULT NULL COMMENT '1有效 0无效',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_auth_page` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT ' 主键',
  `cgform_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'online表id',
  `code` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '字段名/按钮编码',
  `type` int DEFAULT NULL COMMENT '1字段 2按钮',
  `control` int DEFAULT NULL COMMENT '3可编辑 5可见(仅支持两种状态值3,5)',
  `page` int DEFAULT NULL COMMENT '3列表 5表单(仅支持两种状态值3,5)',
  `status` int DEFAULT NULL COMMENT '1有效 0无效',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_onl_auth_page_code` (`code`) USING BTREE,
  KEY `idx_onl_auth_page_cgform_id` (`cgform_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_auth_relation` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `role_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '角色id',
  `auth_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '权限id',
  `type` int DEFAULT NULL COMMENT '1字段 2按钮 3数据权限',
  `cgform_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'online表单ID',
  `auth_mode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '授权方式role角色，depart部门，user人',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_button` (
  `ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `BUTTON_CODE` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮编码',
  `BUTTON_ICON` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮图标',
  `BUTTON_NAME` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮名称',
  `BUTTON_STATUS` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮状态',
  `BUTTON_STYLE` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮样式',
  `EXP` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表达式',
  `CGFORM_HEAD_ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单ID',
  `OPT_TYPE` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮类型',
  `ORDER_NUM` int DEFAULT NULL COMMENT '排序',
  `OPT_POSITION` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮位置1侧面 2底部',
  PRIMARY KEY (`ID`) USING BTREE,
  KEY `idx_ocb_CGFORM_HEAD_ID` (`CGFORM_HEAD_ID`) USING BTREE,
  KEY `idx_ocb_BUTTON_CODE` (`BUTTON_CODE`) USING BTREE,
  KEY `idx_ocb_BUTTON_STATUS` (`BUTTON_STATUS`) USING BTREE,
  KEY `idx_ocb_ORDER_NUM` (`ORDER_NUM`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='Online表单自定义按钮';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_enhance_java` (
  `ID` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `BUTTON_CODE` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮编码',
  `CG_JAVA_TYPE` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '类型',
  `CG_JAVA_VALUE` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '数值',
  `CGFORM_HEAD_ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表单ID',
  `ACTIVE_STATUS` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '1' COMMENT '生效状态',
  `EVENT` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT 'end' COMMENT '事件状态(end:结束，start:开始)',
  PRIMARY KEY (`ID`) USING BTREE,
  KEY `idx_ejava_cgform_head_id` (`CGFORM_HEAD_ID`) USING BTREE,
  KEY `idx_ocej_BUTTON_CODE` (`BUTTON_CODE`) USING BTREE,
  KEY `idx_ocej_ACTIVE_STATUS` (`ACTIVE_STATUS`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_enhance_js` (
  `ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `CG_JS` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'JS增强内容',
  `CG_JS_TYPE` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型',
  `CONTENT` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `CGFORM_HEAD_ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单ID',
  PRIMARY KEY (`ID`) USING BTREE,
  KEY `idx_ejs_cgform_head_id` (`CGFORM_HEAD_ID`) USING BTREE,
  KEY `idx_ejs_cg_js_type` (`CG_JS_TYPE`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_enhance_sql` (
  `ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `BUTTON_CODE` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮编码',
  `CGB_SQL` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT 'SQL内容',
  `CGB_SQL_NAME` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'Sql名称',
  `CONTENT` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `CGFORM_HEAD_ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单ID',
  PRIMARY KEY (`ID`) USING BTREE,
  KEY `idx_oces_CGFORM_HEAD_ID` (`CGFORM_HEAD_ID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_field` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `cgform_head_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表ID',
  `db_field_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字段名字',
  `db_field_txt` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段备注',
  `db_field_name_old` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '原字段名',
  `db_is_key` tinyint(1) DEFAULT NULL COMMENT '是否主键 0否 1是',
  `db_is_null` tinyint(1) DEFAULT NULL COMMENT '是否允许为空0否 1是',
  `db_is_persist` tinyint(1) DEFAULT NULL COMMENT '是否需要同步数据库字段， 1是0否',
  `db_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '数据库字段类型',
  `db_length` int NOT NULL COMMENT '数据库字段长度',
  `db_point_length` int DEFAULT NULL COMMENT '小数点',
  `db_default_val` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表字段默认值',
  `dict_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典code',
  `dict_table` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典表',
  `dict_text` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典Text',
  `field_show_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单控件类型',
  `field_href` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '跳转URL',
  `field_length` int DEFAULT NULL COMMENT '表单控件长度',
  `field_valid_type` varchar(300) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单字段校验规则',
  `field_must_input` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段是否必填',
  `field_extend_json` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '扩展参数JSON',
  `field_default_value` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '控件默认值，不同的表达式展示不同的结果。\r\n1. 纯字符串直接赋给默认值；\r\n2. #{普通变量}；\r\n3. {{ 动态JS表达式 }}；\r\n4. ${填值规则编码}；\r\n填值规则表达式只允许存在一个，且不能和其他规则混用。',
  `is_query` tinyint(1) DEFAULT NULL COMMENT '是否查询条件0否 1是',
  `is_show_form` tinyint(1) DEFAULT NULL COMMENT '表单是否显示0否 1是',
  `is_show_list` tinyint(1) DEFAULT NULL COMMENT '列表是否显示0否 1是',
  `is_read_only` tinyint(1) DEFAULT '0' COMMENT '是否是只读（1是 0否）',
  `query_mode` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询模式',
  `main_table` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '外键主表名',
  `main_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '外键主键字段',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `converter` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '自定义值转换器',
  `query_def_val` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询默认值',
  `query_dict_text` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询配置字典text',
  `query_dict_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询配置字典code',
  `query_dict_table` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询配置字典table',
  `query_show_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询显示控件',
  `query_config_flag` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否启用查询配置1是0否',
  `query_valid_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询字段校验类型',
  `query_must_input` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询字段是否必填1是0否',
  `sort_flag` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否支持排序1是0否',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ocf_cgform_head_id` (`cgform_head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_head` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `table_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表名',
  `table_type` int NOT NULL COMMENT '表类型: 0单表、1主表、2附表',
  `table_version` int DEFAULT '1' COMMENT '表版本',
  `table_txt` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表说明',
  `is_checkbox` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '是否带checkbox',
  `is_db_synch` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT 'N' COMMENT '同步数据库状态',
  `is_page` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '是否分页',
  `is_tree` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '是否是树',
  `id_sequence` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主键生成序列',
  `id_type` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主键类型',
  `query_mode` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询模式',
  `relation_type` int DEFAULT NULL COMMENT '映射关系 0一对多  1一对一',
  `sub_table_str` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '子表',
  `tab_order_num` int DEFAULT NULL COMMENT '附表排序序号',
  `tree_parent_id_field` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '树形表单父id',
  `tree_id_field` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '树表主键字段',
  `tree_fieldname` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '树开表单列字段',
  `form_category` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT 'bdfl_ptbd' COMMENT '表单分类',
  `form_template` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'PC表单模板',
  `form_template_mobile` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表单模板样式(移动端)',
  `scroll` int DEFAULT '0' COMMENT '是否有横向滚动条',
  `copy_version` int DEFAULT NULL COMMENT '复制版本号',
  `copy_type` int DEFAULT '0' COMMENT '复制表类型1为复制表 0为原始表',
  `physic_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '原始表ID',
  `ext_config_json` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '扩展JSON',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `theme_template` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主题模板',
  `is_des_form` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否用设计器表单',
  `des_form_code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '设计器表单编码',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `low_app_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关联的应用ID',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_och_cgform_head_id` (`table_name`) USING BTREE,
  KEY `idx_och_table_name` (`form_template`) USING BTREE,
  KEY `idx_och_form_template_mobile` (`form_template_mobile`) USING BTREE,
  KEY `idx_och_table_version` (`table_version`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgform_index` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `cgform_head_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主表id',
  `index_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '索引名称',
  `index_name_old` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '原索引名称',
  `index_field` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '索引栏位',
  `index_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '索引类型',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `is_db_synch` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT 'N' COMMENT '是否同步数据库 N未同步 Y已同步',
  `del_flag` int DEFAULT '0' COMMENT '是否删除 0未删除 1删除',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_oci_cgform_head_id` (`cgform_head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgreport_head` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '报表编码',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '报表名字',
  `cgr_sql` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '报表SQL',
  `return_val_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '返回值字段',
  `return_txt_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '返回文本字段',
  `return_type` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '1' COMMENT '返回类型，单选或多选',
  `db_source` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '动态数据源',
  `content` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `low_app_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关联的应用ID',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人id',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人id',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `index_onlinereport_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgreport_item` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `cgrhead_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '报表ID',
  `field_name` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字段名字',
  `field_txt` varchar(300) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段文本',
  `field_width` int DEFAULT NULL,
  `field_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段类型',
  `search_mode` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询模式',
  `is_order` int DEFAULT '0' COMMENT '是否排序  0否,1是',
  `is_search` int DEFAULT '0' COMMENT '是否查询  0否,1是',
  `dict_code` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典CODE',
  `field_href` varchar(120) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段跳转URL',
  `is_show` int DEFAULT '1' COMMENT '是否显示  0否,1显示',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `replace_val` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '取值表达式',
  `is_total` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否合计 0否,1是（仅对数值有效）',
  `group_title` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '分组标题',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_oci_cgrhead_id` (`cgrhead_id`) USING BTREE,
  KEY `idx_oci_is_show` (`is_show`) USING BTREE,
  KEY `idx_oci_order_num` (`order_num`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_cgreport_param` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `cgrhead_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '动态报表ID',
  `param_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '参数字段',
  `param_txt` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数文本',
  `param_value` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数默认值',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ocp_cgrhead_id` (`cgrhead_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_comp` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `parent_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `comp_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '组件名称',
  `comp_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `icon` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '图标',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `type_id` int DEFAULT NULL COMMENT '组件类型',
  `comp_config` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '组件配置',
  `status` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '状态0:无效 1:有效',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='组件库';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_dataset_head` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '名称',
  `code` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '编码',
  `parent_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '父id',
  `db_source` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '动态数据源',
  `query_sql` varchar(5000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '查询数据SQL',
  `content` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `iz_agent` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT 'iz_agent',
  `data_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据类型',
  `api_method` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'api方法：get/post',
  `create_time` datetime DEFAULT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `low_app_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '应用ID',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_dataset_item` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `head_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主表ID',
  `field_name` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段名',
  `field_txt` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段文本',
  `field_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段类型',
  `widget_type` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '控件类型',
  `dict_code` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典Code',
  `dict_table` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `dict_text` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `iz_show` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否列表显示',
  `iz_search` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否查询',
  `iz_total` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否计算总计（仅对数值有效）',
  `search_mode` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询模式',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_oddi_head_id` (`head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_dataset_param` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `head_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '动态报表ID',
  `param_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '参数字段',
  `param_txt` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数文本',
  `param_value` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数默认值',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `iz_search` int DEFAULT NULL COMMENT '查询标识0否1是 默认0',
  `widget_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询控件类型',
  `search_mode` int DEFAULT NULL COMMENT '查询模式1简单2范围',
  `dict_code` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_oddp_head_id` (`head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_page` (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '界面名称',
  `path` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '访问路径',
  `background_color` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '背景色',
  `background_image` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '背景图',
  `design_type` int DEFAULT NULL COMMENT '设计模式(1:pc,2:手机,3:平板)',
  `theme` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '主题色',
  `style` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '面板主题',
  `cover_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '封面图',
  `des_json` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '仪表盘主配置JSON',
  `template` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '布局json',
  `protection_code` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '保护码',
  `type` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属分类',
  `iz_template` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '0' COMMENT '是否模板(1:是；0不是)',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `low_app_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '应用ID',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  `update_count` int DEFAULT '1',
  `visits_num` int DEFAULT NULL COMMENT '访问次数',
  `del_flag` int DEFAULT NULL COMMENT '删除状态( 0未删除 1已删除)',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='可视化拖拽界面';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_page_comp` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `parent_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '父组件ID',
  `page_Id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '界面ID',
  `comp_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '组件库ID',
  `component` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '组件名称',
  `config` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '组件配置',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='可视化拖拽页面组件';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_share` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `drag_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '在线仪表盘设计器id',
  `preview_url` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '预览地址',
  `preview_lock` varchar(4) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '密码锁',
  `last_update_time` datetime DEFAULT NULL COMMENT '最后更新时间',
  `term_of_validity` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '有效期(0:永久有效，1:1天，7:7天)',
  `status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '是否过期(0未过期，1已过期)',
  `preview_lock_status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '是否为密码锁(0 否,1是)',
  `share_token` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '分享token',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_ods_drag_id` (`drag_id`) USING BTREE COMMENT '仪表盘id唯一索引'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='仪表盘预览分享表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_drag_table_relation` (
  `id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `aggregation_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '聚合表名称',
  `aggregation_desc` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '聚合表描述',
  `relation_forms` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '关联表单',
  `filter_condition` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '过滤条件',
  `header_fields` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '表头字段',
  `calculate_fields` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '公式字段',
  `validate_info` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci COMMENT '校验信息',
  `del_flag` tinyint(1) DEFAULT NULL COMMENT '删除状态(0-正常,1-已删除)',
  `low_app_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '应用ID',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_aggregation_name` (`aggregation_name`) USING BTREE,
  KEY `idx_del_flag` (`del_flag`) USING BTREE,
  KEY `idx_tenant_id` (`tenant_id`) USING BTREE,
  KEY `idx_create_by` (`create_by`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='仪表盘聚合表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_graphreport_head` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '图表名称',
  `code` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '图表编码',
  `cgr_sql` varchar(5000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '查询数据SQL',
  `xaxis_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '' COMMENT 'X轴数据字段',
  `yaxis_field` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '' COMMENT 'Y轴数据字段',
  `yaxis_text` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '' COMMENT 'y轴文字描述',
  `content` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `extend_js` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '扩展JS',
  `graph_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '图表类型',
  `is_combination` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT 'combination' COMMENT '是否组合',
  `display_template` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '展示模板',
  `data_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据类型',
  `db_source` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '动态数据源',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `low_app_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关联的应用ID',
  `create_time` datetime DEFAULT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_gpreport_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_graphreport_item` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `graphreport_head_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主表ID',
  `field_name` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段名',
  `field_txt` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段文本',
  `is_show` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否列表显示',
  `is_total` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否计算总计（仅对数值有效）',
  `search_flag` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否查询',
  `search_mode` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '查询模式',
  `dict_code` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典Code',
  `field_href` varchar(120) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段href',
  `field_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段类型',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `replace_val` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '取值表达式',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ogi_graphreport_head_id` (`graphreport_head_id`) USING BTREE,
  KEY `idx_ogi_is_show` (`is_show`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='jform_graphreport_item';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_graphreport_params` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `head_id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'Online图表ID',
  `param_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '参数字段',
  `param_txt` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数文本',
  `param_value` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数默认值',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `onl_graphreport_param_head_id` (`head_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='Online图表：参数表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_graphreport_templet` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `templet_code` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `templet_name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '报表名称',
  `templet_style` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '报表风格模板（单排、双排、Tab模式、分组模式-根据配置动态展示、可自定义...）',
  `create_time` datetime DEFAULT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `onl_graphreport_templet_item` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `graphreport_templet_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `graphreport_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '图表编码',
  `graphreport_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '图表类型（饼状图、曲线图、柱状图、数据列表等）',
  `group_num` int DEFAULT NULL COMMENT '组合数字，默认值0 非必填',
  `group_style` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组合展示风格（1 卡片，2 tab）非必填',
  `group_txt` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '分组描述',
  `order_num` int DEFAULT NULL COMMENT '排序',
  `is_show` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否显示 1显示 0不显示，默认1',
  `create_time` datetime DEFAULT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ogti_grreport_tempid` (`graphreport_templet_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `open_api` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '接口名称',
  `request_method` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '请求方法',
  `request_url` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '接口地址',
  `white_list` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT 'IP白名单，支持IP、CIDR、通配符，逗号或换行分隔',
  `comment` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci COMMENT '白名单备注说明',
  `body` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '请求体内容',
  `origin_url` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '原始地址',
  `status` int DEFAULT NULL COMMENT '状态',
  `del_flag` int DEFAULT NULL COMMENT '删除标识',
  `create_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `headers_json` json DEFAULT NULL COMMENT '请求头json',
  `params_json` json DEFAULT NULL COMMENT '请求参数json',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='接口表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `open_api_auth` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '授权名称',
  `ak` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'AK',
  `sk` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'SK',
  `create_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `system_user_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '关联系统用户名',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `open_api_log` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `api_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '接口ID',
  `call_auth_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '调用ID',
  `call_time` datetime DEFAULT NULL COMMENT '调用时间',
  `used_time` bigint DEFAULT NULL COMMENT '耗时',
  `response_time` datetime DEFAULT NULL COMMENT '响应时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='调用记录表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `open_api_permission` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `api_id` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '接口ID',
  `api_auth_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '认证ID',
  `create_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC COMMENT='openapi授权';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `oss_file` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `file_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件名称',
  `url` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件地址',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='Oss File';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_blob_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `BLOB_DATA` blob,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_blob_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `qrtz_triggers` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_calendars` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `CALENDAR_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `CALENDAR` blob NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`CALENDAR_NAME`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_cron_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `CRON_EXPRESSION` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TIME_ZONE_ID` varchar(80) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_cron_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `qrtz_triggers` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_fired_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `ENTRY_ID` varchar(95) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `INSTANCE_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `FIRED_TIME` bigint NOT NULL,
  `SCHED_TIME` bigint NOT NULL,
  `PRIORITY` int NOT NULL,
  `STATE` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `JOB_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `IS_NONCONCURRENT` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `REQUESTS_RECOVERY` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`SCHED_NAME`,`ENTRY_ID`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_job_details` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `DESCRIPTION` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `JOB_CLASS_NAME` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `IS_DURABLE` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `IS_NONCONCURRENT` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `IS_UPDATE_DATA` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `REQUESTS_RECOVERY` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_DATA` blob,
  PRIMARY KEY (`SCHED_NAME`,`JOB_NAME`,`JOB_GROUP`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_locks` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `LOCK_NAME` varchar(40) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`LOCK_NAME`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_paused_trigger_grps` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_GROUP`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_scheduler_state` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `INSTANCE_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `LAST_CHECKIN_TIME` bigint NOT NULL,
  `CHECKIN_INTERVAL` bigint NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`INSTANCE_NAME`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_simple_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `REPEAT_COUNT` bigint NOT NULL,
  `REPEAT_INTERVAL` bigint NOT NULL,
  `TIMES_TRIGGERED` bigint NOT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_simple_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `qrtz_triggers` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_simprop_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `STR_PROP_1` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `STR_PROP_2` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `STR_PROP_3` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `INT_PROP_1` int DEFAULT NULL,
  `INT_PROP_2` int DEFAULT NULL,
  `LONG_PROP_1` bigint DEFAULT NULL,
  `LONG_PROP_2` bigint DEFAULT NULL,
  `DEC_PROP_1` decimal(13,4) DEFAULT NULL,
  `DEC_PROP_2` decimal(13,4) DEFAULT NULL,
  `BOOL_PROP_1` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `BOOL_PROP_2` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_simprop_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) REFERENCES `qrtz_triggers` (`SCHED_NAME`, `TRIGGER_NAME`, `TRIGGER_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `qrtz_triggers` (
  `SCHED_NAME` varchar(120) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `JOB_GROUP` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `DESCRIPTION` varchar(250) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `NEXT_FIRE_TIME` bigint DEFAULT NULL,
  `PREV_FIRE_TIME` bigint DEFAULT NULL,
  `PRIORITY` int DEFAULT NULL,
  `TRIGGER_STATE` varchar(16) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `TRIGGER_TYPE` varchar(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `START_TIME` bigint NOT NULL,
  `END_TIME` bigint DEFAULT NULL,
  `CALENDAR_NAME` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `MISFIRE_INSTR` smallint DEFAULT NULL,
  `JOB_DATA` blob,
  PRIMARY KEY (`SCHED_NAME`,`TRIGGER_NAME`,`TRIGGER_GROUP`) USING BTREE,
  KEY `SCHED_NAME` (`SCHED_NAME`,`JOB_NAME`,`JOB_GROUP`) USING BTREE,
  CONSTRAINT `qrtz_triggers_ibfk_1` FOREIGN KEY (`SCHED_NAME`, `JOB_NAME`, `JOB_GROUP`) REFERENCES `qrtz_job_details` (`SCHED_NAME`, `JOB_NAME`, `JOB_GROUP`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_dxtj` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '姓名',
  `gtime` datetime DEFAULT NULL COMMENT '雇佣日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '职务',
  `jphone` varchar(125) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '家庭电话',
  `birth` datetime DEFAULT NULL COMMENT '出生日期',
  `hukou` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '户口所在地',
  `laddress` varchar(125) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '联系地址',
  `jperson` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '紧急联系人',
  `sex` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'xingbie',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_employee` (
  `id` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `num` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '编号',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '姓名',
  `sex` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '性别',
  `birthday` datetime DEFAULT NULL COMMENT '出生日期',
  `nation` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '民族',
  `political` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '政治面貌',
  `native_place` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '籍贯',
  `height` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '身高',
  `weight` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '体重',
  `health` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '健康状况',
  `id_card` varchar(80) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '身份证号',
  `education` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '学历',
  `school` varchar(80) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '毕业学校',
  `major` varchar(80) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '专业',
  `address` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '联系地址',
  `zip_code` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '邮编',
  `email` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'Email',
  `phone` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '手机号',
  `foreign_language` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '外语语种',
  `foreign_language_level` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '外语水平',
  `computer_level` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '计算机水平',
  `graduation_time` datetime DEFAULT NULL COMMENT '毕业时间',
  `arrival_time` datetime DEFAULT NULL COMMENT '到职时间',
  `positional_titles` varchar(30) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职称',
  `education_experience` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '教育经历',
  `work_experience` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '工作经历',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `del_flag` tinyint(1) DEFAULT NULL COMMENT '删除标识0-正常,1-已删除',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_gongsi` (
  `id` int NOT NULL AUTO_INCREMENT,
  `gname` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '货品名称',
  `gdata` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '返利',
  `tdata` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '备注',
  `didian` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `zhaiyao` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `num` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_jianpiao` (
  `id` int NOT NULL AUTO_INCREMENT,
  `bnum` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `ftime` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `sfkong` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `kaishi` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `jieshu` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `hezairen` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `jpnum` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `shihelv` varchar(125) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `s_id` int NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=87 DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_order_main` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `order_code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '订单编码',
  `order_date` datetime DEFAULT NULL COMMENT '下单时间',
  `descc` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `xiala` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '下拉多选',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rep_demo_order_product` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `product_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '产品名字',
  `price` double(32,0) DEFAULT NULL COMMENT '价格',
  `num` int DEFAULT NULL COMMENT '数量',
  `descc` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `order_fk_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '订单外键ID',
  `pro_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '产品类型',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_announcement` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `titile` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '标题',
  `msg_content` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '内容',
  `start_time` datetime DEFAULT NULL COMMENT '开始时间',
  `end_time` datetime DEFAULT NULL COMMENT '结束时间',
  `sender` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发布人',
  `priority` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '优先级（L低，M中，H高）',
  `msg_category` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '2' COMMENT '消息类型1:通知公告2:系统消息',
  `msg_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '通告对象类型（USER:指定用户，ALL:全体用户）',
  `send_status` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发布状态（0未发布，1已发布，2已撤销）',
  `send_time` datetime DEFAULT NULL COMMENT '发布时间',
  `cancel_time` datetime DEFAULT NULL COMMENT '撤销时间',
  `del_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '删除状态（0，正常，1已删除）',
  `bus_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '业务类型(email:邮件 bpm:流程 tenant_invite:租户邀请)',
  `bus_id` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '业务id',
  `open_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '打开方式(组件：component 路由：url)',
  `open_page` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组件/路由 地址',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `user_ids` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '指定用户',
  `msg_abstract` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '摘要/扩展业务参数',
  `dt_task_id` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '钉钉task_id，用于撤回消息',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `files` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '附件',
  `visits_num` int DEFAULT NULL COMMENT '访问次数',
  `iz_top` int DEFAULT '0' COMMENT '是否置顶（0:否;  1:是）',
  `iz_approval` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否审批（0否 1是）',
  `bpm_status` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '流程状态',
  `msg_classify` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '消息归类',
  `notice_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '通知类型(system:系统消息、file:知识库、flow:流程、plan:日程计划、meeting:会议)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sanno_endtime` (`end_time`) USING BTREE,
  KEY `idx_sanno_start_time` (`start_time`) USING BTREE,
  KEY `idx_sanno_msg_type` (`msg_type`) USING BTREE,
  KEY `idx_sanno_send_status` (`send_status`) USING BTREE,
  KEY `idx_sanno_del_flag` (`del_flag`) USING BTREE,
  KEY `idx_sanno_tenant_id` (`tenant_id`) USING BTREE,
  KEY `idx_sanno_sender` (`sender`) USING BTREE,
  KEY `idx_sanno_create_time` (`create_time`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='系统通告表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_announcement_send` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `annt_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '通告ID',
  `user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户id',
  `read_flag` int DEFAULT NULL COMMENT '阅读状态（0未读，1已读）',
  `read_time` datetime DEFAULT NULL COMMENT '阅读时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `star_flag` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '标星状态( 1为标星 空/0没有标星)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sacm_annt_id` (`annt_id`) USING BTREE,
  KEY `idx_sacm_user_id` (`user_id`) USING BTREE,
  KEY `idx_sacm_read_flag` (`read_flag`) USING BTREE,
  KEY `idx_sacm_star_flag` (`star_flag`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户通告阅读标记表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_category` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `pid` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '父级节点',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型名称',
  `code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '类型编码',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门',
  `has_child` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否有子节点',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `index_scg_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_check_rule` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `rule_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则名称',
  `rule_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则Code',
  `rule_json` varchar(1024) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则JSON',
  `rule_description` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则描述',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_scr_rule_code` (`rule_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_comment` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `table_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表名',
  `table_data_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '数据id',
  `from_user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '来源用户id',
  `to_user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发送给用户id(允许为空)',
  `comment_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '评论id(允许为空，不为空时，则为回复)',
  `comment_content` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '回复内容',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_table_data_id` (`table_name`,`table_data_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='系统评论回复表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_data_log` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人真实名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `data_table` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '表名',
  `data_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据ID',
  `data_content` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '数据内容',
  `data_version` int DEFAULT NULL COMMENT '版本号',
  `type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT 'json' COMMENT '类型',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sdl_data_table_id` (`data_table`,`data_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_data_source` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据源编码',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据源名称',
  `remark` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `db_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据库类型',
  `db_driver` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '驱动类',
  `db_url` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据源地址',
  `db_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '数据库名称',
  `db_username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户名',
  `db_password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '密码',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属部门',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_sdc_rule_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_depart` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'ID',
  `parent_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '父机构ID',
  `depart_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '机构/部门名称',
  `depart_name_en` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '英文名',
  `depart_name_abbr` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '缩写',
  `depart_order` int DEFAULT '0' COMMENT '排序',
  `description` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `org_category` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL DEFAULT '1' COMMENT '机构类别 1公司，2部门，3岗位，4子公司',
  `org_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '树深度层级level',
  `org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '机构编码',
  `mobile` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '手机号',
  `fax` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '传真',
  `address` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '地址',
  `memo` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `status` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '状态（1启用，0不启用）',
  `del_flag` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '删除状态（0，正常，1已删除）',
  `qywx_identifier` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '对接企业微信的ID',
  `ding_identifier` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '对接钉钉部门的ID',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `iz_leaf` tinyint(1) DEFAULT '0' COMMENT '是否有叶子节点: 1是0否',
  `position_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职级id',
  `dep_post_parent_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '上级岗位id',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_depart_org_code` (`org_code`) USING BTREE,
  KEY `idx_sd_parent_id` (`parent_id`) USING BTREE,
  KEY `idx_sd_depart_order` (`depart_order`) USING BTREE,
  KEY `idx_sd_position_id` (`position_id`) USING BTREE,
  KEY `idx_sd_dep_post_parent_id` (`dep_post_parent_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='组织机构表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_depart_permission` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `depart_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门id',
  `permission_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '权限id',
  `data_rule_ids` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据规则id',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='部门权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_depart_role` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `depart_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门id',
  `role_name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门角色名称',
  `role_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门角色编码',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='部门角色表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_depart_role_permission` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `depart_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门id',
  `role_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '角色id',
  `permission_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '权限id',
  `data_rule_ids` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据权限ids',
  `operate_date` datetime DEFAULT NULL COMMENT '操作时间',
  `operate_ip` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '操作ip',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sdrp_role_per_id` (`role_id`,`permission_id`) USING BTREE,
  KEY `idx_sdrp_role_id` (`role_id`) USING BTREE,
  KEY `idx_sdrp_per_id` (`permission_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='部门角色权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_depart_role_user` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户id',
  `drole_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '角色id',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sdr_user_id` (`user_id`) USING BTREE,
  KEY `idx_sdr_role_id` (`drole_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='部门角色用户表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_dict` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `dict_name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典名称',
  `dict_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典编码',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `del_flag` int DEFAULT NULL COMMENT '删除状态',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `type` int(1) unsigned zerofill DEFAULT '0' COMMENT '字典类型0为string,1为number',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  `low_app_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '低代码应用ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_sd_dict_code` (`dict_code`) USING BTREE,
  KEY `uk_sd_tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_dict_item` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `dict_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典id',
  `item_text` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典项文本',
  `item_value` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '字典项值',
  `item_color` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字典项颜色',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `sort_order` int DEFAULT NULL COMMENT '排序',
  `status` int DEFAULT NULL COMMENT '状态（1启用 0不启用）',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `create_time` datetime DEFAULT NULL,
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sditem_role_dict_id` (`dict_id`) USING BTREE,
  KEY `idx_sditem_role_sort_order` (`sort_order`) USING BTREE,
  KEY `idx_sditem_status` (`status`) USING BTREE,
  KEY `idx_sditem_dict_val` (`dict_id`,`item_value`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_files` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `file_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件名称',
  `url` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件地址',
  `file_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文档类型（folder:文件夹 excel:excel doc:word ppt:ppt image:图片  archive:其他文档 video:视频 pdf:pdf）',
  `store_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件上传类型(temp/本地上传(临时文件) manage/知识库)',
  `parent_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '父级id',
  `tenant_id` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '租户id',
  `file_size` double(13,2) DEFAULT NULL COMMENT '文件大小（kb）',
  `iz_folder` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否文件夹(1：是  0：否)',
  `iz_root_folder` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否为1级文件夹，允许为空 (1：是 )',
  `iz_star` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否标星(1：是  0：否)',
  `down_count` int DEFAULT NULL COMMENT '下载次数',
  `read_count` int DEFAULT NULL COMMENT '阅读次数',
  `share_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '分享链接',
  `share_perms` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '分享权限(1.关闭分享 2.允许所有联系人查看 3.允许任何人查看)',
  `enable_down` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否允许下载(1：是  0：否)',
  `enable_updat` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否允许修改(1：是  0：否)',
  `del_flag` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '删除状态(0-正常,1-删除至回收站)',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_tenant_id` (`tenant_id`) USING BTREE,
  KEY `index_del_flag` (`del_flag`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='知识库-文档管理';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_fill_rule` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键ID',
  `rule_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则名称',
  `rule_code` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则Code',
  `rule_class` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则实现类',
  `rule_params` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '规则参数',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_sfr_rule_code` (`rule_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_form_file` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `table_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '表名',
  `table_data_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '数据id',
  `file_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '关联文件id',
  `file_type` varchar(20) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '文件类型(text:文本, excel:excel doc:word ppt:ppt image:图片  archive:其他文档 video:视频 pdf:pdf）)',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_table_form` (`table_name`,`table_data_id`) USING BTREE,
  KEY `index_file_id` (`file_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_gateway_route` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `router_id` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '路由ID',
  `name` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '服务名',
  `uri` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '服务地址',
  `predicates` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '断言',
  `filters` text CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '过滤器',
  `retryable` int DEFAULT NULL COMMENT '是否重试:0-否 1-是',
  `strip_prefix` int DEFAULT NULL COMMENT '是否忽略前缀0-否 1-是',
  `persistable` int DEFAULT NULL COMMENT '是否为保留数据:0-否 1-是',
  `show_api` int DEFAULT NULL COMMENT '是否在接口文档中展示:0-否 1-是',
  `status` int DEFAULT NULL COMMENT '状态:0-无效 1-有效',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门',
  `del_flag` int DEFAULT NULL COMMENT '删除状态',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_log` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `log_type` int DEFAULT NULL COMMENT '日志类型（1登录日志，2操作日志, 3.租户操作日志）',
  `log_content` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '日志内容',
  `operate_type` int DEFAULT NULL COMMENT '操作类型',
  `userid` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '操作用户账号',
  `username` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '操作用户名称',
  `ip` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'IP',
  `method` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求java方法',
  `request_url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求路径',
  `request_param` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '请求参数',
  `request_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '请求类型',
  `cost_time` bigint DEFAULT NULL COMMENT '耗时',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  `client_type` varchar(5) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '客户端类型 pc:电脑端 app:手机端 h5:移动网页端',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sl_userid` (`userid`) USING BTREE,
  KEY `idx_sl_log_type` (`log_type`) USING BTREE,
  KEY `idx_sl_operate_type` (`operate_type`) USING BTREE,
  KEY `idx_sl_create_time` (`create_time`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='系统日志表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_permission` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `parent_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '父id',
  `name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '菜单标题',
  `url` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '路径',
  `component` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组件',
  `is_route` tinyint(1) DEFAULT '1' COMMENT '是否路由菜单: 0:不是  1:是（默认值1）',
  `component_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组件名字',
  `redirect` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '一级菜单跳转地址',
  `menu_type` int DEFAULT NULL COMMENT '菜单类型(0:一级菜单; 1:子菜单:2:按钮权限)',
  `perms` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '菜单权限编码',
  `perms_type` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '权限策略1显示2禁用',
  `sort_no` double(8,2) DEFAULT NULL COMMENT '菜单排序',
  `always_show` tinyint(1) DEFAULT NULL COMMENT '聚合子路由: 1是0否',
  `icon` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '菜单图标',
  `is_leaf` tinyint(1) DEFAULT NULL COMMENT '是否叶子节点:    1是0否',
  `keep_alive` tinyint(1) DEFAULT NULL COMMENT '是否缓存该页面:    1:是   0:不是',
  `hidden` tinyint DEFAULT '0' COMMENT '是否隐藏路由: 0否,1是',
  `hide_tab` tinyint DEFAULT NULL COMMENT '是否隐藏tab: 0否,1是',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `create_by` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `del_flag` int DEFAULT '0' COMMENT '删除状态 0正常 1已删除',
  `rule_flag` int DEFAULT '0' COMMENT '是否添加数据权限1是0否',
  `status` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '按钮权限状态(0无效1有效)',
  `internal_or_external` tinyint(1) DEFAULT NULL COMMENT '外链菜单打开方式 0/内部打开 1/外部打开',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `index_menu_type` (`menu_type`) USING BTREE,
  KEY `index_menu_hidden` (`hidden`) USING BTREE,
  KEY `index_menu_status` (`status`) USING BTREE,
  KEY `index_menu_del_flag` (`del_flag`) USING BTREE,
  KEY `index_menu_url` (`url`) USING BTREE,
  KEY `index_menu_sort_no` (`sort_no`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='菜单权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_permission_data_rule` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'ID',
  `permission_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '菜单ID',
  `rule_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '规则名称',
  `rule_column` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '字段',
  `rule_conditions` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '条件',
  `rule_value` varchar(300) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '规则值',
  `status` varchar(3) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '权限有效状态1有0否',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL,
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_spdr_permission_id` (`permission_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_position` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职务编码',
  `name` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职务级别名称',
  `post_level` int DEFAULT NULL COMMENT '职务等级',
  `company_id` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '公司id',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `sys_org_code` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组织机构编码',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_code` (`code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='职务级别';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_quartz_job` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `del_flag` int DEFAULT NULL COMMENT '删除状态',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  `job_class_name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '任务类名',
  `cron_expression` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'cron表达式',
  `parameter` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '参数',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `status` int DEFAULT NULL COMMENT '状态 0正常 -1停止',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `role_name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '角色名称',
  `role_code` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '角色编码',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_sys_role_role_code` (`role_code`) USING BTREE,
  KEY `idx_sysrole_tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='角色表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role_index` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `role_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '角色编码',
  `url` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '路由地址',
  `component` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '组件',
  `is_route` tinyint(1) DEFAULT '1' COMMENT '是否路由菜单: 0:不是  1:是（默认值1）',
  `priority` int DEFAULT '0' COMMENT '优先级',
  `status` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT '0' COMMENT '状态0:无效 1:有效',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '所属部门',
  `relation_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '关联关系(ROLE:角色 USER:用户)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sri_role_code` (`role_code`) USING BTREE,
  KEY `idx_sri_status` (`status`) USING BTREE,
  KEY `idx_sri_priority` (`priority`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='角色首页表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_role_permission` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `role_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '角色id',
  `permission_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '权限id',
  `data_rule_ids` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '数据权限ids',
  `operate_date` datetime DEFAULT NULL COMMENT '操作时间',
  `operate_ip` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '操作ip',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_srp_role_per_id` (`role_id`,`permission_id`) USING BTREE,
  KEY `idx_srp_role_id` (`role_id`) USING BTREE,
  KEY `idx_srp_permission_id` (`permission_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='角色权限表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_sms` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'ID',
  `es_title` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '消息标题',
  `es_type` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发送方式：参考枚举MessageTypeEnum',
  `es_receiver` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '接收人',
  `es_param` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '发送所需参数Json格式',
  `es_content` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '推送内容',
  `es_send_time` datetime DEFAULT NULL COMMENT '推送时间',
  `es_send_status` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '推送状态 0未推送 1推送成功 2推送失败 -1失败不再发送',
  `es_send_num` int DEFAULT NULL COMMENT '发送次数 超过5次不再发送',
  `es_result` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '推送失败原因',
  `remark` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '备注',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_ss_es_type` (`es_type`) USING BTREE,
  KEY `idx_ss_es_receiver` (`es_receiver`) USING BTREE,
  KEY `idx_ss_es_send_time` (`es_send_time`) USING BTREE,
  KEY `idx_ss_es_send_status` (`es_send_status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_sms_template` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `template_name` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '模板标题',
  `template_code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '模板CODE',
  `template_type` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '模板类型：1短信 2邮件 3微信',
  `template_category` varchar(10) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '模版分类：notice通知公告 other其他',
  `template_content` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '模板内容',
  `template_test_json` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '模板测试json',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `use_status` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否使用中 1是0否',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uk_sst_template_code` (`template_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_table_white_list` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键id',
  `table_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '允许的表名',
  `field_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '允许的字段名，多个用逗号分割',
  `status` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '1' COMMENT '状态，1=启用，0=禁用',
  `create_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_sys_table_white_list_table_name` (`table_name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='系统表白名单';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_tenant` (
  `id` int NOT NULL COMMENT '租户编码',
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '租户名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `create_by` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `begin_date` datetime DEFAULT NULL COMMENT '开始时间',
  `end_date` datetime DEFAULT NULL COMMENT '结束时间',
  `status` int DEFAULT NULL COMMENT '状态 1正常 0冻结',
  `trade` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属行业',
  `company_size` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '公司规模',
  `company_address` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '公司地址',
  `company_logo` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '公司logo',
  `house_number` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '门牌号',
  `work_place` varchar(100) CHARACTER SET utf32 COLLATE utf32_general_ci DEFAULT NULL COMMENT '工作地点',
  `secondary_domain` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '二级域名',
  `login_bkgd_img` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '登录背景图片',
  `position` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '职级',
  `department` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '部门',
  `del_flag` tinyint(1) DEFAULT '0' COMMENT '删除状态(0-正常,1-已删除)',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `apply_status` int DEFAULT NULL COMMENT '允许申请管理员 1允许 0不允许',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='多租户信息表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_tenant_pack` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键id',
  `tenant_id` int DEFAULT NULL COMMENT '租户id',
  `pack_name` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '产品包名',
  `status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '开启状态(0 未开启 1开启)',
  `remarks` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '备注',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` date DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` date DEFAULT NULL COMMENT '更新时间',
  `pack_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '编码,默认添加的三个管理员需要设置编码',
  `pack_type` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT 'custom' COMMENT '产品包类型(default 默认产品包 custom 自定义产品包)',
  `iz_sysn` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '自动分配给用户(0否 1是)',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx__stp_tenant_id_pack_code` (`tenant_id`,`pack_code`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='租户产品包';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_tenant_pack_perms` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键编号',
  `pack_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '租户产品包名称',
  `permission_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '菜单id',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` date DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` date DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_stpp_pack_id` (`pack_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='租户产品包和菜单关系表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_tenant_pack_user` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `pack_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '租户产品包ID',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户ID',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `status` int DEFAULT NULL COMMENT '状态 正常状态1 申请状态0',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_tpu_pack_id` (`pack_id`) USING BTREE,
  KEY `idx_tpu_user_id` (`user_id`) USING BTREE,
  KEY `idx_tpu_tenant_id` (`tenant_id`) USING BTREE,
  KEY `idx_tpu_status` (`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='租户套餐人员表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_third_account` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '编号',
  `sys_user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '第三方登录id',
  `avatar` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '头像',
  `status` tinyint(1) DEFAULT NULL COMMENT '状态(1-正常,2-冻结)',
  `del_flag` tinyint(1) DEFAULT NULL COMMENT '删除状态(0-正常,1-已删除)',
  `realname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '真实姓名',
  `tenant_id` int DEFAULT '0' COMMENT '租户id',
  `third_user_uuid` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '第三方账号',
  `third_user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '第三方app用户账号',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `third_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '登录来源',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_stat_third_type_user_id` (`third_type`,`third_user_id`) USING BTREE,
  UNIQUE KEY `uniq_sta_third_user_id_third_type` (`third_user_id`,`third_type`,`tenant_id`) USING BTREE,
  UNIQUE KEY `uniq_sta_third_user_uuid_third_type` (`third_user_uuid`,`third_type`,`tenant_id`) USING BTREE,
  KEY `idx_sta_sys_user_id_third_type` (`sys_user_id`,`third_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_third_app_config` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `tenant_id` int NOT NULL DEFAULT '0' COMMENT '租户id',
  `agent_id` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '钉钉/企业微信应用id',
  `client_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '钉钉/企业微信 应用id',
  `client_secret` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '钉钉/企业微信应用id对应的秘钥',
  `corp_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '钉钉企业id',
  `third_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '第三方类别(dingtalk 钉钉 wechat_enterprise 企业微信)',
  `status` int DEFAULT '1' COMMENT '是否启用(0-否,1-是)',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_stac_tenant_id` (`tenant_id`) USING BTREE,
  KEY `idx_stac_third_type` (`third_type`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='租户第三方配置表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_ugroup` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `group_name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户组名称',
  `description` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_su_tenant_id` (`tenant_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户组表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_ugroup_user` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户id',
  `group_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户组id',
  `tenant_id` int DEFAULT NULL COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_suu_user_id` (`user_id`) USING BTREE,
  KEY `idx_suu_group_id` (`group_id`) USING BTREE,
  KEY `idx_suu_user_role_id` (`user_id`,`group_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户组关系表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `username` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '登录账号',
  `realname` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '真实姓名',
  `password` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '密码',
  `salt` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'md5密码盐',
  `avatar` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '头像',
  `birthday` date DEFAULT NULL COMMENT '生日',
  `sex` tinyint(1) DEFAULT NULL COMMENT '性别(0-默认未知,1-男,2-女)',
  `email` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '电子邮件',
  `phone` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '电话',
  `org_code` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '登录会话的机构编码',
  `status` tinyint(1) DEFAULT NULL COMMENT '性别(1-正常,2-冻结)',
  `del_flag` tinyint(1) DEFAULT NULL COMMENT '删除状态(0-正常,1-已删除)',
  `third_id` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '第三方登录的唯一标识',
  `third_type` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '第三方类型',
  `activiti_sync` tinyint(1) DEFAULT NULL COMMENT '同步工作流引擎(1-同步,0-不同步)',
  `work_no` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '工号，唯一键',
  `telephone` varchar(45) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '座机号',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  `user_identity` tinyint(1) DEFAULT NULL COMMENT '身份（1普通成员 2上级）',
  `depart_ids` varchar(1000) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '负责部门',
  `client_id` varchar(64) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '设备ID',
  `login_tenant_id` int DEFAULT NULL COMMENT '上次登录选择租户ID',
  `bpm_status` varchar(2) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '流程入职离职状态',
  `sign_enable` tinyint(1) DEFAULT NULL COMMENT '是否启用个性签名（0 否 1是）',
  `sign` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '个性签名',
  `main_dep_post_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '主岗位（部门岗位id）',
  `position_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '职务(字典)',
  `last_pwd_update_time` datetime DEFAULT NULL COMMENT '上一次修改密码的时间',
  `sort` int DEFAULT NULL COMMENT '排序',
  `iz_hide_contact` varchar(1) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '是否隐藏联系方式（0 否 1是）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `uniq_sys_user_work_no` (`work_no`) USING BTREE,
  UNIQUE KEY `uniq_sys_user_username` (`username`) USING BTREE,
  UNIQUE KEY `uniq_sys_user_phone` (`phone`) USING BTREE,
  UNIQUE KEY `uniq_sys_user_email` (`email`) USING BTREE,
  KEY `idx_su_status` (`status`) USING BTREE,
  KEY `idx_su_del_flag` (`del_flag`) USING BTREE,
  KEY `idx_su_del_username` (`username`,`del_flag`) USING BTREE,
  KEY `idx_su_main_dep_post_id` (`main_dep_post_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_dep_post` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户id',
  `dep_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '部门岗位id',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sudp_user_id` (`user_id`) USING BTREE,
  KEY `idx_sudp_dep_id` (`dep_id`) USING BTREE,
  KEY `idx_sudp_user_dep_id` (`user_id`,`dep_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_depart` (
  `ID` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT 'id',
  `user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户id',
  `dep_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '部门id',
  PRIMARY KEY (`ID`) USING BTREE,
  UNIQUE KEY `idx_sud_user_dep_id` (`user_id`,`dep_id`) USING BTREE,
  KEY `idx_sud_user_id` (`user_id`) USING BTREE,
  KEY `idx_sud_dep_id` (`dep_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_position` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户id',
  `position_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '职位id',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建时间',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '修改人',
  `update_time` datetime DEFAULT NULL COMMENT '修改时间',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sup_user_id` (`user_id`) USING BTREE,
  KEY `idx_sup_position_id` (`position_id`) USING BTREE,
  KEY `idx_sup_user_position_id` (`user_id`,`position_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_role` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键id',
  `user_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户id',
  `role_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '角色id',
  `tenant_id` int DEFAULT '0' COMMENT '租户ID',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sur_user_id` (`user_id`) USING BTREE,
  KEY `idx_sur_role_id` (`role_id`) USING BTREE,
  KEY `idx_sur_user_role_id` (`user_id`,`role_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC COMMENT='用户角色表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sys_user_tenant` (
  `id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键id',
  `user_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户id',
  `tenant_id` int DEFAULT NULL COMMENT '租户id',
  `status` varchar(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '状态(1 正常 2 离职 3 待审核 4 拒绝 5 邀请加入)',
  `create_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_sut_user_id` (`user_id`) USING BTREE,
  KEY `idx_sut_tenant_id` (`tenant_id`) USING BTREE,
  KEY `idx_sut_user_rel_tenant` (`user_id`,`tenant_id`) USING BTREE,
  KEY `idx_sut_status` (`status`) USING BTREE,
  KEY `idx_sut_userid_status` (`user_id`,`status`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC COMMENT='用户租户关系表';
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_demo` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人登录名称',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人登录名称',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户名',
  `sex` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '性别',
  `age` int DEFAULT NULL COMMENT '年龄',
  `descc` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `birthday` datetime DEFAULT NULL COMMENT '生日',
  `user_code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户编码',
  `file_kk` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '附件',
  `top_pic` varchar(500) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '头像',
  `chegnshi` varchar(300) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '城市',
  `ceck` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'checkbox',
  `xiamuti` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '下拉多选',
  `search_sel` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '搜索下拉',
  `pop` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '弹窗',
  `sel_table` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '下拉字典表',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_enhance_select` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `province` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '省份',
  `city` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '市',
  `area` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '区',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_note` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属部门',
  `name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '用户名',
  `age` int DEFAULT NULL COMMENT '年龄',
  `sex` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '性别',
  `birthday` datetime DEFAULT NULL COMMENT '生日',
  `contents` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '请假原因',
  `year` date DEFAULT NULL COMMENT '年',
  `sheng` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '地区',
  `month` date DEFAULT NULL COMMENT '月',
  `begin_time` date DEFAULT NULL COMMENT '开始时间',
  `long_ids` bigint DEFAULT NULL COMMENT '长类型',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_online_link` (
  `id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `pid` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'pid',
  `name` varchar(255) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT 'name',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_order_customer` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属部门',
  `name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '客户名字',
  `sex` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '性别',
  `age` int DEFAULT NULL COMMENT '年龄',
  `birthday` date DEFAULT NULL COMMENT '生日',
  `order_id` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '订单id',
  `address` varchar(300) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '地址',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_order_main` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `order_code` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '订单编码',
  `order_date` datetime DEFAULT NULL COMMENT '下单时间',
  `descc` varchar(100) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `xiala` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '下拉多选',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_order_product` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `product_name` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '产品名字',
  `price` double(32,0) DEFAULT NULL COMMENT '价格',
  `num` int DEFAULT NULL COMMENT '数量',
  `descc` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '描述',
  `order_fk_id` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL COMMENT '订单外键ID',
  `pro_type` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '产品类型',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_person` (
  `id` varchar(36) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci NOT NULL,
  `create_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sex` varchar(32) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '性别',
  `name` varchar(200) CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci DEFAULT NULL COMMENT '用户名',
  `content` longtext CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci COMMENT '请假原因',
  `be_date` datetime DEFAULT NULL COMMENT '请假时间',
  `qj_days` int DEFAULT NULL COMMENT '请假天数',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `test_shoptype_tree` (
  `id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '主键',
  `create_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '创建人',
  `create_time` datetime DEFAULT NULL COMMENT '创建日期',
  `update_by` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '更新人',
  `update_time` datetime DEFAULT NULL COMMENT '更新日期',
  `sys_org_code` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '所属部门',
  `type_name` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '商品分类',
  `pic` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '分类图片',
  `pid` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '父级节点',
  `has_child` varchar(3) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT '是否有子节点',
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;
/*!40101 SET character_set_client = @saved_cs_client */;

-- update-end---author:pi---date:2026-08-04---for:[CI fix] V0.0.0 full schema-----------