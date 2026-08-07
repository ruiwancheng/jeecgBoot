-- ============================================================
-- 孤儿库存清理审计表 + 历史归档表
-- Plan: hermes/plan/inventory-orphan-cleanup-2026-08-07.md § 四
-- Impl: hermes/plan/inventory-orphan-cleanup-impl-2026-08-07.md § B.3
-- ============================================================

CREATE TABLE IF NOT EXISTS c_mes_inventory_cleanup_audit (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '自增主键',
    batch_id        VARCHAR(64)     NOT NULL                COMMENT '清理批次 ID（ui-single/ui-batch/sql-emergency）',
    inventory_id    VARCHAR(32)     NOT NULL                COMMENT '被清理的 c_mes_inventory.id',
    material_id     VARCHAR(32)                             COMMENT '物料 ID（可空）',
    warehouse_id    VARCHAR(32)                             COMMENT '仓库 ID（可空）',
    current_qty     DECIMAL(18,4)                           COMMENT '清理时的 current_qty',
    risk_type       VARCHAR(16)                             COMMENT '风险类型 A2=硬删 B2=软删',
    operator        VARCHAR(64)     NOT NULL                COMMENT '操作人',
    cleaned_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '清理时间',
    rolled_back     TINYINT(1)      DEFAULT 0               COMMENT '是否已回滚 0/1',
    rollback_at     DATETIME                                 COMMENT '回滚时间',
    INDEX idx_batch (batch_id),
    INDEX idx_inventory (inventory_id),
    INDEX idx_cleaned (cleaned_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='孤儿库存清理审计表';

-- 历史归档表：清理 90 天前的审计记录（运维 Runbook 阶段 6 任务）
CREATE TABLE IF NOT EXISTS c_mes_inventory_cleanup_audit_his (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '自增主键',
    batch_id        VARCHAR(64)     NOT NULL                COMMENT '清理批次 ID',
    inventory_id    VARCHAR(32)     NOT NULL                COMMENT '被清理的 c_mes_inventory.id',
    material_id     VARCHAR(32)                             COMMENT '物料 ID（可空）',
    warehouse_id    VARCHAR(32)                             COMMENT '仓库 ID（可空）',
    current_qty     DECIMAL(18,4)                           COMMENT '清理时的 current_qty',
    risk_type       VARCHAR(16)                             COMMENT '风险类型 A2/B2',
    operator        VARCHAR(64)     NOT NULL                COMMENT '操作人',
    cleaned_at      DATETIME        NOT NULL                COMMENT '原始清理时间',
    rolled_back     TINYINT(1)      DEFAULT 0               COMMENT '是否已回滚 0/1',
    rollback_at     DATETIME                                 COMMENT '回滚时间',
    archived_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '归档时间',
    INDEX idx_batch (batch_id),
    INDEX idx_inventory (inventory_id),
    INDEX idx_archived (archived_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='孤儿库存清理审计历史归档表（>90 天）';
