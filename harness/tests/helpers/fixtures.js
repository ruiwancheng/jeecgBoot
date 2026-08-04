// harness 测试共享 fixture（测试数据创建与清理）
// 原则: 唯一编码(后缀) + API 清理优先 + DB 清理走 SQL 文件(绕开 Windows 引号)
const { execSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

/** mysql 可执行文件解析（Windows 全路径兜底，execSync 无 PATH 也能跑） */
function mysqlBin() {
  if (os.platform() === 'win32') {
    const full = 'C:/Program Files/MySQL/MySQL Server 8.4/bin/mysql.exe';
    if (fs.existsSync(full)) return `"${full}"`;
  }
  return 'mysql';
}

/** 造仓库，返回 {id, code} */
async function createWarehouse(c, suffix, name = '测试仓') {
  const code = `WH_T_${suffix}`;
  await c.api('POST', '/mes/basic/warehouse/add', { code, name, status: 1 });
  const doc = await c.findDoc('/mes/basic/warehouse/list', code);
  return { id: doc?.id, code };
}

/** 造物料，返回 {id, code} */
async function createMaterial(c, suffix, name = '测试料') {
  const code = `MAT_T_${suffix}`;
  await c.api('POST', '/mes/basic/material/add', { code, name, type: '1' });
  const doc = await c.findDoc('/mes/basic/material/list', code);
  return { id: doc?.id, code };
}

/** 造供应商，返回 {id, code} */
async function createSupplier(c, suffix, name = '测试供应商') {
  const code = `SUP_T_${suffix}`;
  await c.api('POST', '/mes/basic/supplier/add', { code, name });
  const doc = await c.findDoc('/mes/basic/supplier/list', code);
  return { id: doc?.id, code };
}

/** 其它入库并审核（期初库存），返回单号 */
async function createAndAuditStockIn(c, { whId, matId, qty, unitCost, suffix }) {
  const code = `FIXIN_${suffix}`;
  await c.api('POST', '/mes/stock/otherIn/add', {
    code, inType: '2', warehouseId: whId, reason: '测试期初',
    stockDate: new Date().toISOString().slice(0, 10),
    items: [{ materialId: matId, qty, unitCost }],
  });
  const doc = await c.findDoc('/mes/stock/otherIn/list', code);
  await c.api('PUT', `/mes/stock/otherIn/audit?id=${doc.id}`);
  return { id: doc.id, code };
}

/** 安全删单据（先尝试反审核再删，忽略失败） */
async function safeDeleteDoc(c, basePath, id) {
  if (!id) return;
  try { await c.api('PUT', `${basePath}/unaudit?id=${id}`); } catch (e) {}
  try { await c.api('DELETE', `${basePath}/delete?id=${id}`); } catch (e) {}
}

/**
 * DB 级清理（仅本地库可用；服务器库无权限时自动跳过）
 * 用 SQL 文件执行，绕开 Windows 命令行引号问题
 */
function dbCleanup(sqlStatements) {
  //update-begin---author:pi---date:2026-08-05---for:[BUG-5-R 修复] dbCleanup 失败时记录错误到 stderr（不静默吞错）-----------
  const f = path.join(os.tmpdir(), `harness-cleanup-${Date.now()}.sql`);
  try {
    fs.writeFileSync(f, sqlStatements, 'utf8');
    execSync(`${mysqlBin()} -uroot -proot --host=127.0.0.1 --protocol=TCP --default-character-set=utf8mb4 jeecg-boot < "${f}"`, { stdio: 'pipe' });
    return true;
  } catch (e) {
    // 不再静默吞错：打印 SQL + 错误信息到 stderr，方便 CI log 排查
    process.stderr.write(`[dbCleanup FAILED] SQL:\n${sqlStatements}\n`);
    process.stderr.write(`[dbCleanup ERROR] ${e.message}\n`);
    return false;
  } finally {
    try { fs.unlinkSync(f); } catch (e) {}
  }
  //update-end---author:pi---date:2026-08-05---for:[BUG-5-R 修复] dbCleanup 失败时记录错误到 stderr（不静默吞错）-----------
}

/** 常用清理：仓+料+库存+台账+成本日志（本地库） */
function cleanupWarehouseScope(whId, matId) {
  return dbCleanup(`
    DELETE FROM c_mes_inventory WHERE warehouse_id='${whId}';
    DELETE FROM c_mes_inventory_ledger WHERE warehouse_id='${whId}';
    DELETE FROM c_mes_cost_log WHERE warehouse_id='${whId}';
    UPDATE c_mes_material SET moving_avg_cost=0, last_purchase_price=NULL, last_purchase_date=NULL WHERE id='${matId}';
    DELETE FROM c_mes_material WHERE id='${matId}';
    DELETE FROM c_mes_warehouse WHERE id='${whId}';
  `);
}

module.exports = { createWarehouse, createMaterial, createSupplier, createAndAuditStockIn, safeDeleteDoc, dbCleanup, cleanupWarehouseScope };
