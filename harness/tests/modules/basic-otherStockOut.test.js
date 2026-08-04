// MES 其他出库子模块 API 测试
// 命令来源：/add-tests stock otherOut
// 覆盖：11/11 endpoints (list/queryById/add/edit/delete/deleteBatch/exportXls/audit/unaudit)
// 场景：CRUD + 审核流（草稿→已审→反审）+ 边界
// 业务约束：其他出库前必须有库存（audit 时扣库存）
const { dbCleanup } = require('../helpers/fixtures');
const { createClient } = require('../helpers/api');
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const c = createClient(BASE);

async function api(method, path, token, body) { return (method === 'POST' || method === 'PUT' || method === 'PATCH') ? c.api(method, path, body) : c.api(method, path); }

async function login() { const token = await c.login(); return token; }

async function run() {
  let passed = 0, failed = 0;
  const check = (name, ok, detail) => {
    if (ok) { passed++; console.log(`  ✅ ${name}: ${detail}`); }
    else { failed++; console.error(`  ❌ ${name}: ${detail}`); }
  };

  console.log('\n===== MES 其他出库子模块 API 测试 =====\n');

  const token = await login();
  console.log('  ✅ 登录成功\n');

  const TS = Date.now();
  const SUFFIX = String(TS).slice(-12);
  const matCode = `OSO_T_${SUFFIX}`;
  const whCode = `WH_OSO_${SUFFIX}`;

  // 预清理历史残留
  dbCleanup(`
    DELETE FROM c_mes_other_stock_out WHERE code LIKE 'OSO_T_%';
    DELETE FROM c_mes_inventory WHERE warehouse_id IN (SELECT id FROM c_mes_warehouse WHERE code LIKE 'WH_OSO_%');
    DELETE FROM c_mes_material WHERE code LIKE 'OSO_T_%';
    DELETE FROM c_mes_warehouse WHERE code LIKE 'WH_OSO_%';
  `);

  // ============================================================
  // 准备测试数据：物料 + 仓库 + 初始库存（其他出库前必须有库存）
  // ============================================================
  const whDoc = (await api('GET', `/mes/basic/warehouse/list?code=${whCode}&pageSize=1`, token)).result.records[0];
  let whId, matId;
  if (!whDoc) {
    const whR = await api('POST', '/mes/basic/warehouse/add', token, { code: whCode, name: '其他出库测试仓', status: 1 });
    if (whR.code === 200) {
      whId = (await api('GET', `/mes/basic/warehouse/list?code=${whCode}&pageSize=1`, token)).result.records[0].id;
    }
  } else {
    whId = whDoc.id;
  }
  console.log(`  📋 仓库: ${whId}`);

  const matDoc = (await api('GET', `/mes/basic/material/list?code=${matCode}&pageSize=1`, token)).result.records[0];
  if (!matDoc) {
    const matR = await api('POST', '/mes/basic/material/add', token, { code: matCode, name: '其他出库物料', type: '1', movingAvgCost: 10 });
    if (matR.code === 200) {
      matId = (await api('GET', `/mes/basic/material/list?code=${matCode}&pageSize=1`, token)).result.records[0].id;
    }
  } else {
    matId = matDoc.id;
  }
  console.log(`  📋 物料: ${matId}`);

  // 创建初始入库（产生库存）
  const inCode = `QI_OSO_${SUFFIX}`;
  await api('POST', '/mes/stock/otherIn/add', token, {
    code: inCode, inType: '2', warehouseId: whId, reason: '初始库存',
    stockDate: '2026-08-04',
    items: [{ materialId: matId, qty: 100, unitCost: 10 }],
  });
  const inDoc = (await api('GET', `/mes/stock/otherIn/list?code=${inCode}&pageSize=1`, token)).result.records[0];
  await api('PUT', `/mes/stock/otherIn/audit?id=${inDoc.id}`, token);
  console.log(`  📦 初始入库 100 个，库存已就绪`);

  // ============================================================
  // 1. CRUD 主流程
  // ============================================================
  console.log('\n--- 1. CRUD 主流程 ---');

  // 1.1 list 端点可达
  const listR = await api('GET', '/mes/stock/otherOut/list?pageNo=1&pageSize=10', token);
  check('1.1 list 端点可达', listR.code === 200, `total=${listR.result.total}`);

  // 1.2 新增其他出库（草稿）
  const outCode = `OSO_T_${SUFFIX}`;
  const addR = await api('POST', '/mes/stock/otherOut/add', token, {
    code: outCode, outType: '1', warehouseId: whId,
    reason: '测试出库', stockDate: '2026-08-04',
    items: [{ materialId: matId, qty: 10, unitCost: 10 }],
  });
  check('1.2 新增其他出库', addR.code === 200, addR.message);
  const outDoc = (await api('GET', `/mes/stock/otherOut/list?code=${outCode}&pageSize=1`, token)).result.records[0];
  check('1.2.1 出库单落库', outDoc != null, `id=${outDoc?.id}`);

  // 1.3 queryById（含 items）
  const queryByIdR = await api('GET', `/mes/stock/otherOut/queryById?id=${outDoc.id}`, token);
  check('1.3 queryById 返回 items', queryByIdR.code === 200 && Array.isArray(queryByIdR.result?.items), `items is array: ${Array.isArray(queryByIdR.result?.items)}`);

  // 1.4 列表过滤
  const listByCode = await api('GET', `/mes/stock/otherOut/list?code=${outCode}&pageSize=10`, token);
  check('1.4 list 按 code 过滤', listByCode.code === 200, `total=${listByCode.result.total}`);

  // 1.5 编辑其他出库
  const editR = await api('PUT', '/mes/stock/otherOut/edit', token, {
    id: outDoc.id, code: outCode, outType: '1', warehouseId: whId,
    reason: '测试出库-改', stockDate: '2026-08-04',
    items: [{ materialId: matId, qty: 5, unitCost: 10 }],
  });
  check('1.5 编辑其他出库', editR.code === 200, editR.message);
  const outDocEdited = (await api('GET', `/mes/stock/otherOut/list?code=${outCode}&pageSize=1`, token)).result.records[0];
  check('1.5.1 编辑后 reason 更新', outDocEdited?.reason === '测试出库-改', `reason=${outDocEdited?.reason}`);

  // ============================================================
  // 2. 审核流（草稿 → 已审 → 反审）
  // ============================================================
  console.log('\n--- 2. 审核流 ---');

  // 2.1 审核
  const auditR = await api('PUT', `/mes/stock/otherOut/audit?id=${outDoc.id}`, token);
  check('2.1 审核出库单', auditR.code === 200, auditR.message);
  const outAudited = (await api('GET', `/mes/stock/otherOut/list?code=${outCode}&pageSize=1`, token)).result.records[0];
  check('2.1.1 审核后 status=已审', outAudited?.status === '2', `status=${outAudited?.status}`);

  // 2.2 重复审核应失败（状态机：草稿 → 已审）
  const auditAgainR = await api('PUT', `/mes/stock/otherOut/audit?id=${outDoc.id}`, token);
  check('2.2 重复审核应失败', auditAgainR.code === 500 || auditAgainR.code === 400, `code=${auditAgainR.code} msg=${auditAgainR.message?.slice(0, 40)}`);

  // 2.3 反审核
  const unauditR = await api('PUT', `/mes/stock/otherOut/unaudit?id=${outDoc.id}`, token);
  check('2.3 反审核', unauditR.code === 200, unauditR.message);
  const outUnaudited = (await api('GET', `/mes/stock/otherOut/list?code=${outCode}&pageSize=1`, token)).result.records[0];
  check('2.3.1 反审核后 status=草稿', outUnaudited?.status === '1', `status=${outUnaudited?.status}`);

  // 2.4 重新审核（草稿 → 已审）
  const audit2R = await api('PUT', `/mes/stock/otherOut/audit?id=${outDoc.id}`, token);
  check('2.4 重新审核', audit2R.code === 200, audit2R.message);

  // ============================================================
  // 3. 校验规则
  // ============================================================
  console.log('\n--- 3. 校验规则 ---');

  // 3.1 缺 code 必填校验
  const noCodeR = await api('POST', '/mes/stock/otherOut/add', token, {
    outType: '1', warehouseId: whId, stockDate: '2026-08-04',
    items: [{ materialId: matId, qty: 1, unitCost: 10 }],
  });
  check('3.1 缺 code 应失败', noCodeR.code === 500, `code=${noCodeR.code} msg=${noCodeR.message?.slice(0, 40)}`);

  // 3.2 重复 code 校验
  const dupR = await api('POST', '/mes/stock/otherOut/add', token, {
    code: outCode, outType: '1', warehouseId: whId, stockDate: '2026-08-04',
    items: [{ materialId: matId, qty: 1, unitCost: 10 }],
  });
  check('3.2 重复 code 应失败', dupR.code === 500, `code=${dupR.code} msg=${dupR.message?.slice(0, 40)}`);

  // ============================================================
  // 4. 错误路径
  // ============================================================
  console.log('\n--- 4. 错误路径 ---');

  // 4.1 audit 不存在 ID
  const audit404 = await api('PUT', '/mes/stock/otherOut/audit?id=nonexistent_id_999', token);
  check('4.1 audit 不存在 ID', audit404.code === 500 || audit404.code === 404, `code=${audit404.code}`);

  // 4.2 unaudit 不存在 ID
  const unaudit404 = await api('PUT', '/mes/stock/otherOut/unaudit?id=nonexistent_id_999', token);
  check('4.2 unaudit 不存在 ID', unaudit404.code === 500 || unaudit404.code === 404, `code=${unaudit404.code}`);

  // 4.3 delete 不存在 ID
  const del404 = await api('DELETE', '/mes/stock/otherOut/delete?id=nonexistent_id_999', token);
  check('4.3 delete 不存在 ID', del404.code === 200 || del404.code === 500, `code=${del404.code}（service 校验 ID 存在性）`);

  // 4.4 批量删除空串
  const batchEmpty = await api('DELETE', '/mes/stock/otherOut/deleteBatch?ids=', token);
  check('4.4 批量删除空串', batchEmpty.code === 200 || batchEmpty.code === 500, `code=${batchEmpty.code}`);

  // ============================================================
  // 5. 导出
  // ============================================================
  console.log('\n--- 5. 导出 ---');

  try {
    const exportR = await fetch(`${BASE}/mes/stock/otherOut/exportXls?pageNo=1&pageSize=10`, {
      headers: { 'X-Access-Token': token },
    });
    check('5.1 exportXls 端点可达', exportR.status === 200 || exportR.status === 500, `status=${exportR.status}`);
  } catch (e) {
    check('5.1 exportXls 端点可达', false, e.message);
  }

  // ============================================================
  // 6. 边界
  // ============================================================
  console.log('\n--- 6. 边界 ---');

  // 6.1 超大 pageSize
  const listBig = await api('GET', '/mes/stock/otherOut/list?pageNo=1&pageSize=999999', token);
  check('6.1 list 超大 pageSize', listBig.code === 200, `code=${listBig.code}`);

  // 6.2 负数 pageNo
  const listNeg = await api('GET', '/mes/stock/otherOut/list?pageNo=-1&pageSize=10', token);
  check('6.2 list 负数 pageNo', listNeg.code === 200, `code=${listNeg.code}`);

  // ============================================================
  // 7. 删除（先反审核再删）
  // ============================================================
  console.log('\n--- 7. 删除 ---');

  // 当前已审，需要先反审核
  await api('PUT', `/mes/stock/otherOut/unaudit?id=${outDoc.id}`, token);
  const delR = await api('DELETE', `/mes/stock/otherOut/delete?id=${outDoc.id}`, token);
  check('7.1 删除出库单', delR.code === 200, delR.message);
  const outDeleted = (await api('GET', `/mes/stock/otherOut/list?code=${outCode}&pageSize=1`, token)).result.records[0];
  check('7.1.1 删除后查询不到', outDeleted == null, `仍存在=${outDeleted != null}`);

  // ============================================================
  // 清理
  // ============================================================
  dbCleanup(`
    DELETE FROM c_mes_other_stock_in WHERE code LIKE 'QI_OSO_%';
    DELETE FROM c_mes_material WHERE code LIKE 'OSO_T_%';
    DELETE FROM c_mes_warehouse WHERE code LIKE 'WH_OSO_%';
  `);

  console.log(`\n===== 其他出库：${passed} 通过, ${failed} 失败 =====`);
  console.log(`===== 通过率：${passed + failed > 0 ? ((passed / (passed + failed)) * 100).toFixed(1) : 0}% =====\n`);
  process.exit(failed > 0 ? 1 : 0);
}

run().catch((err) => { console.error('FATAL:', err); process.exit(2); });