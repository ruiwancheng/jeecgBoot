#!/usr/bin/env bash
# ============================================================================
# /debug 库存总览孤儿行清理脚本
# ============================================================================
# 用途：清理 c_mes_inventory 中指向已删除物料的孤儿行
# 时机：diagnose-orphan-inventory.sql 跑完后，按结果分阶段清理
#
# ⚠️⚠️⚠️ 强制约束 ⚠️⚠️⚠️
#   1. 必须先跑 diagnose 脚本，看清规模再动手
#   2. 必须先备份（脚本第 1 步强制）
#   3. 零库存孤儿行可直接清；有库存孤儿行必须人工逐批确认
#   4. 默认 DRY_RUN=1（只打印不执行），需显式 DRY_RUN=0 才真删
#   5. 每次清理写入审计表，可一键回滚
#
# 用法：
#   # 1. 看探针结果（只读）
#   ./cleanup-orphan-inventory.sh probe
#
#   # 2. 备份 + 创建审计表
#   ./cleanup-orphan-inventory.sh backup
#
#   # 3. 清理零库存孤儿行（DRY-RUN）
#   ./cleanup-orphan-inventory.sh clean-zero --dry-run
#
#   # 4. 清理零库存孤儿行（真实执行）
#   ./cleanup-orphan-inventory.sh clean-zero
#
#   # 5. 清理有库存孤儿行（每批 100 行，需 --batch-id 唯一标识）
#   ./cleanup-orphan-inventory.sh clean-nonzero --batch-id biz-sign-2026-08-07 --limit 100
#
#   # 6. 一键回滚（用 batch-id 撤销）
#   ./cleanup-orphan-inventory.sh rollback --batch-id biz-sign-2026-08-07
#
#   # 7. 验证清理效果
#   ./cleanup-orphan-inventory.sh verify
# ============================================================================

set -euo pipefail

# ---------- 配置 ----------
DB_HOST="${MES_DB_HOST:-127.0.0.1}"
DB_PORT="${MES_DB_PORT:-3306}"
DB_NAME="${MES_DB_NAME:-jeecg-boot}"
DB_USER="${MES_DB_USER:-root}"
DB_PASS="${MES_DB_PASS:-}"

MYSQL_CMD="mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} ${DB_NAME}"

# 审计表（用于回滚）
AUDIT_TABLE="c_mes_inventory_cleanup_audit"

# ---------- 工具 ----------
ts() { date +"%Y-%m-%d %H:%M:%S"; }
say() { echo "[$(ts)] $*"; }
die() { say "❌ $*"; exit 1; }

usage() {
  sed -n '2,/^# ====/p' "$0" | grep '^#' | sed 's/^# //;s/^#//'
  exit 1
}

# ---------- 子命令 ----------
cmd_probe() {
  say "🔍 探针：诊断孤儿行（只读，不修改数据）"
  mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} ${DB_NAME} \
    < "$(dirname "$0")/diagnose-orphan-inventory.sql"
}

cmd_backup() {
  local backup_file="backup_c_mes_inventory_$(date +%Y%m%d_%H%M%S).sql"
  say "💾 备份 c_mes_inventory → ${backup_file}"

  mysqldump -h${DB_HOST} -P${DB_PORT} -u${DB_USER} -p${DB_PASS} ${DB_NAME} \
    c_mes_inventory > "${backup_file}"

  say "✅ 备份完成: ${backup_file} ($(du -h ${backup_file} | cut -f1))"
  say "   建议把此文件传到安全存储后再继续"
}

cmd_ensure_audit_table() {
  say "📋 确保审计表 ${AUDIT_TABLE} 存在"
  ${MYSQL_CMD} <<SQL
CREATE TABLE IF NOT EXISTS ${AUDIT_TABLE} (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    batch_id        VARCHAR(64)     NOT NULL COMMENT '清理批次 ID（人工签字确认）',
    inventory_id    VARCHAR(32)     NOT NULL COMMENT '被删库存行 ID',
    material_id     VARCHAR(32)     COMMENT '原物料 ID',
    warehouse_id    VARCHAR(32)     COMMENT '仓库 ID',
    current_qty     DECIMAL(18,4)   COMMENT '删除时库存',
    risk_type       VARCHAR(16)     COMMENT 'A1/A2/B1/B2',
    operator        VARCHAR(64)     NOT NULL COMMENT '操作人',
    cleaned_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rolled_back     TINYINT(1)      DEFAULT 0 COMMENT '是否已回滚',
    rollback_at     DATETIME        COMMENT '回滚时间',
    INDEX idx_batch (batch_id),
    INDEX idx_inventory (inventory_id),
    INDEX idx_cleaned (cleaned_at)
) ENGINE=InnoDB COMMENT='孤儿库存清理审计表（用于回滚）';
SQL
}

cmd_clean_zero() {
  local dry_run="${DRY_RUN:-1}"
  local batch_id="zero-$(date +%Y%m%d-%H%M%S)"

  cmd_ensure_audit_table

  say "🧹 清理零库存孤儿行（batch_id=${batch_id}, DRY_RUN=${dry_run}）"

  # 1. 先列出要清理的 ID
  local target_ids
  target_ids=$(${MYSQL_CMD} -N -e "
    SELECT GROUP_CONCAT(i.id)
    FROM c_mes_inventory i
    LEFT JOIN c_mes_material m ON i.material_id = m.id
    WHERE (m.id IS NULL OR m.del_flag = 1)
      AND i.current_qty = 0;
  " 2>/dev/null || echo "")

  if [[ -z "${target_ids}" ]]; then
    say "✅ 无零库存孤儿行，无需清理"
    return 0
  fi

  local target_count
  target_count=$(${MYSQL_CMD} -N -e "
    SELECT COUNT(*)
    FROM c_mes_inventory i
    LEFT JOIN c_mes_material m ON i.material_id = m.id
    WHERE (m.id IS NULL OR m.del_flag = 1)
      AND i.current_qty = 0;
  ")
  say "   待清理行数：${target_count}"

  if [[ "${dry_run}" == "1" ]]; then
    say "🔸 DRY-RUN 模式：以下 SQL 不会执行，仅展示"
    cat <<SQL
-- 实际执行会做：
START TRANSACTION;

-- 写审计
INSERT INTO ${AUDIT_TABLE} (batch_id, inventory_id, material_id, warehouse_id, current_qty, risk_type, operator)
SELECT '${batch_id}', i.id, i.material_id, i.warehouse_id, i.current_qty,
       CASE WHEN m.id IS NULL THEN 'A2' ELSE 'B2' END,
       '${USER:-unknown}'
FROM c_mes_inventory i
LEFT JOIN c_mes_material m ON i.material_id = m.id
WHERE (m.id IS NULL OR m.del_flag = 1) AND i.current_qty = 0;

-- 删库存
DELETE FROM c_mes_inventory
WHERE id IN (${target_ids});

COMMIT;
SQL
    say "✅ 确认无误后，设 DRY_RUN=0 再跑一次"
    return 0
  fi

  # 真实执行
  ${MYSQL_CMD} <<SQL
START TRANSACTION;

INSERT INTO ${AUDIT_TABLE} (batch_id, inventory_id, material_id, warehouse_id, current_qty, risk_type, operator)
SELECT '${batch_id}', i.id, i.material_id, i.warehouse_id, i.current_qty,
       CASE WHEN m.id IS NULL THEN 'A2' ELSE 'B2' END,
       '${USER:-unknown}'
FROM c_mes_inventory i
LEFT JOIN c_mes_material m ON i.material_id = m.id
WHERE (m.id IS NULL OR m.del_flag = 1) AND i.current_qty = 0;

DELETE FROM c_mes_inventory
WHERE (material_id NOT IN (SELECT id FROM c_mes_material WHERE del_flag = 0))
  AND current_qty = 0;

COMMIT;
SQL

  local deleted
  deleted=$(${MYSQL_CMD} -N -e "SELECT COUNT(*) FROM ${AUDIT_TABLE} WHERE batch_id='${batch_id}'")
  say "✅ 已清理 ${deleted} 行零库存孤儿行（batch_id=${batch_id}）"
  say "   回滚命令：$0 rollback --batch-id ${batch_id}"
}

cmd_clean_nonzero() {
  local dry_run="${DRY_RUN:-1}"
  local batch_id="${BATCH_ID:-}"
  local limit="${LIMIT:-100}"

  if [[ -z "${batch_id}" ]]; then
    die "必须有 --batch-id 参数（业务签字确认的批次号）"
  fi

  cmd_ensure_audit_table

  say "⚠️  清理有库存孤儿行（batch_id=${batch_id}, limit=${limit}, DRY_RUN=${dry_run}）"
  say "   ⚠️  ⚠️  ⚠️  此操作需业务人员签字确认！�️  ⚠️  ⚠️"

  # 列出本批要清理的行
  local target_rows
  target_rows=$(${MYSQL_CMD} -e "
    SELECT i.id, i.material_id, i.warehouse_id, i.current_qty,
           CASE WHEN m.id IS NULL THEN 'A1' ELSE 'B1' END AS risk
    FROM c_mes_inventory i
    LEFT JOIN c_mes_material m ON i.material_id = m.id
    WHERE (m.id IS NULL OR m.del_flag = 1)
      AND i.current_qty > 0
    ORDER BY i.current_qty DESC
    LIMIT ${limit};
  " 2>/dev/null)

  if [[ -z "${target_rows}" || "$target_rows" == "id *" ]]; then
    say "✅ 无更多有库存孤儿行，全部清理完成"
    return 0
  fi

  echo "${target_rows}"
  echo ""
  say "🔸 上面是本批 ${limit} 行清单，请业务人员核对："
  say "   1. 仓库是否真无此物料（盘点结果）"
  say "   2. 库存数是否可核销（账实差异说明）"
  read -p "   确认清理？输入 YES 继续，其他取消: " confirm

  if [[ "${confirm}" != "YES" ]]; then
    say "❌ 已取消"
    return 1
  fi

  if [[ "${dry_run}" == "1" ]]; then
    say "🔸 DRY-RUN 模式：未实际执行"
    return 0
  fi

  ${MYSQL_CMD} <<SQL
START TRANSACTION;

INSERT INTO ${AUDIT_TABLE} (batch_id, inventory_id, material_id, warehouse_id, current_qty, risk_type, operator)
SELECT '${batch_id}', i.id, i.material_id, i.warehouse_id, i.current_qty,
       CASE WHEN m.id IS NULL THEN 'A1' ELSE 'B1' END,
       '${USER:-unknown}'
FROM c_mes_inventory i
LEFT JOIN c_mes_material m ON i.material_id = m.id
WHERE (m.id IS NULL OR m.del_flag = 1)
  AND i.current_qty > 0
ORDER BY i.current_qty DESC
LIMIT ${limit};

DELETE FROM c_mes_inventory
WHERE id IN (
  SELECT inventory_id FROM (
    SELECT inventory_id FROM ${AUDIT_TABLE}
    WHERE batch_id='${batch_id}' AND rolled_back=0
  ) t
);

COMMIT;
SQL

  local deleted
  deleted=$(${MYSQL_CMD} -N -e "SELECT COUNT(*) FROM ${AUDIT_TABLE} WHERE batch_id='${batch_id}'")
  say "✅ 本批已清理 ${deleted} 行（batch_id=${batch_id}）"
  say "   回滚命令：$0 rollback --batch_id ${batch_id}"

  # 提示下一批
  local remaining
  remaining=$(${MYSQL_CMD} -N -e "
    SELECT COUNT(*) FROM c_mes_inventory i
    LEFT JOIN c_mes_material m ON i.material_id = m.id
    WHERE (m.id IS NULL OR m.del_flag = 1) AND i.current_qty > 0;
  ")
  if [[ ${remaining} -gt 0 ]]; then
    say "📋 还剩 ${remaining} 行有库存孤儿行，继续下一批："
    say "   $0 clean-nonzero --batch-id <新批次号> --limit ${limit}"
  else
    say "🎉 所有有库存孤儿行清理完毕"
  fi
}

cmd_rollback() {
  local batch_id="${BATCH_ID:-}"

  if [[ -z "${batch_id}" ]]; then
    die "必须指定 --batch-id"
  fi

  say "🔙 回滚 batch_id=${batch_id}"

  local rollback_count
  rollback_count=$(${MYSQL_CMD} -N -e "
    SELECT COUNT(*) FROM ${AUDIT_TABLE}
    WHERE batch_id='${batch_id}' AND rolled_back=0;
  ")

  if [[ ${rollback_count} -eq 0 ]]; then
    say "�️  该批次无待回滚记录（可能已回滚或不存在）"
    return 1
  fi

  say "   待回滚行数：${rollback_count}"

  ${MYSQL_CMD} <<SQL
START TRANSACTION;

-- 恢复库存行（仅恢复未回滚的）
INSERT INTO c_mes_inventory (id, material_id, warehouse_id, current_qty, create_by, create_time, update_by, update_time)
SELECT inventory_id, material_id, warehouse_id, current_qty,
       'rollback-${USER}', NOW(), 'rollback-${USER}', NOW()
FROM ${AUDIT_TABLE}
WHERE batch_id='${batch_id}' AND rolled_back=0
ON DUPLICATE KEY UPDATE update_by='rollback-${USER}', update_time=NOW();

-- 标记审计
UPDATE ${AUDIT_TABLE}
SET rolled_back=1, rollback_at=NOW()
WHERE batch_id='${batch_id}' AND rolled_back=0;

COMMIT;
SQL

  say "✅ 已回滚 ${rollback_count} 行"
}

cmd_verify() {
  say "🔍 验证清理效果"

  ${MYSQL_CMD} <<SQL
SELECT '--- 当前孤儿行统计 ---' AS info;

SELECT
    COUNT(*) AS 剩余孤儿行,
    SUM(CASE WHEN i.current_qty > 0 THEN 1 ELSE 0 END) AS 有库存剩余,
    SUM(CASE WHEN i.current_qty = 0 THEN 1 ELSE 0 END) AS 零库存剩余,
    SUM(i.current_qty) AS 剩余库存合计
FROM c_mes_inventory i
LEFT JOIN c_mes_material m ON i.material_id = m.id
WHERE m.id IS NULL OR m.del_flag = 1;

SELECT '--- 最近 10 次清理记录 ---' AS info;

SELECT batch_id, risk_type, COUNT(*) AS cleaned_rows, cleaned_at
FROM ${AUDIT_TABLE}
WHERE rolled_back = 0
GROUP BY batch_id, risk_type, cleaned_at
ORDER BY cleaned_at DESC
LIMIT 10;
SQL
}

# ---------- 入口 ----------
[[ $# -lt 1 ]] && usage
SUBCMD="$1"; shift

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --batch-id) BATCH_ID="$2"; shift 2 ;;
    --limit) LIMIT="$2"; shift 2 ;;
    *) die "未知参数: $1" ;;
  esac
done

case "${SUBCMD}" in
  probe)        cmd_probe ;;
  backup)       cmd_backup ;;
  clean-zero)   cmd_clean_zero ;;
  clean-nonzero) cmd_clean_nonzero ;;
  rollback)     cmd_rollback ;;
  verify)       cmd_verify ;;
  *) usage ;;
esac
