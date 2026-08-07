#!/usr/bin/env bash
# ============================================================================
# 库存孤儿行清理审计表 - 月度归档
# 默认只输出 SQL；cron 中显式设置 DRY_RUN=0 才会写库。
# ============================================================================
set -euo pipefail

DB_HOST="${MES_DB_HOST:-127.0.0.1}"
DB_PORT="${MES_DB_PORT:-3306}"
DB_NAME="${MES_DB_NAME:-jeecg-boot}"
DB_USER="${MES_DB_USER:-root}"
DB_PASS="${MES_DB_PASS:-}"
DRY_RUN="${DRY_RUN:-1}"
TTL_DAYS="${TTL_DAYS:-90}"

[[ "${DRY_RUN}" == 0 || "${DRY_RUN}" == 1 ]] || { echo "DRY_RUN 必须为 0 或 1" >&2; exit 2; }
[[ "${TTL_DAYS}" =~ ^[1-9][0-9]*$ ]] || { echo "TTL_DAYS 必须为正整数" >&2; exit 2; }

mysql_args=(-h "${DB_HOST}" -P "${DB_PORT}" -u "${DB_USER}" "${DB_NAME}")
[[ -n "${DB_PASS}" ]] && mysql_args+=(-p"${DB_PASS}")
mysql_query() { mysql "${mysql_args[@]}" "$@"; }

echo "=== 审计表月度归档 ==="
echo "DB: ${DB_NAME} | TTL: ${TTL_DAYS} 天 | DRY_RUN: ${DRY_RUN}"

count="$(mysql_query -N -e "SELECT COUNT(*) FROM c_mes_inventory_cleanup_audit WHERE cleaned_at < DATE_SUB(NOW(), INTERVAL ${TTL_DAYS} DAY)")"
echo "[1] 待归档行数：${count}"
[[ "${count}" == 0 ]] && { echo "无待归档数据"; exit 0; }

archive_sql=$(cat <<SQL
START TRANSACTION;
INSERT INTO c_mes_inventory_cleanup_audit_his
  (id, batch_id, inventory_id, material_id, warehouse_id, current_qty, risk_type, operator, cleaned_at, rolled_back, rollback_at)
SELECT id, batch_id, inventory_id, material_id, warehouse_id, current_qty, risk_type, operator, cleaned_at, rolled_back, rollback_at
FROM c_mes_inventory_cleanup_audit
WHERE cleaned_at < DATE_SUB(NOW(), INTERVAL ${TTL_DAYS} DAY);
DELETE FROM c_mes_inventory_cleanup_audit
WHERE cleaned_at < DATE_SUB(NOW(), INTERVAL ${TTL_DAYS} DAY);
COMMIT;
SQL
)

if [[ "${DRY_RUN}" == 1 ]]; then
  echo "[2] DRY-RUN：以下 SQL 未执行"
  printf '%s\n' "${archive_sql}"
  exit 0
fi

echo "[2] 执行归档..."
printf '%s\n' "${archive_sql}" | mysql_query
active="$(mysql_query -N -e 'SELECT COUNT(*) FROM c_mes_inventory_cleanup_audit')"
history="$(mysql_query -N -e 'SELECT COUNT(*) FROM c_mes_inventory_cleanup_audit_his')"
echo "归档完成：活跃表 ${active} 行，历史表 ${history} 行"
