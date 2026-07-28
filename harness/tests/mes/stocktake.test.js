// MES 盘点单 API 测试（全链路：快照→实盘→审核→自动生成调整单→库存校准）
const { execSync } = require('child_process');
const BASE = 'http://localhost:8080/jeecg-boot';

async function api(method, path, token, body) {
  const opts = { method, headers: { 'Content-Type': 'application/json' } };
  if (token) opts.headers['X-Access-Token'] = token;
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(BASE + path, opts);
  return await res.json();
}

async function login() {
  const r = await api('POST', '/sys/login', null, { username: 'mes_admin', password: '123456' });
  if (r.code !== 200) throw new Error('Login failed: ' + r.message);
  return r.result.token;
}

function dbCleanup(whId, matId, pdCodes) {
  const cond = pdCodes.map(c => `'${c}'`).join(',');
  const sql = `
    DELETE si FROM c_mes_stocktake_item si JOIN c_mes_stocktake s ON si.take_id=s.id WHERE s.code IN (${cond});
    DELETE FROM c_mes_stocktake WHERE code IN (${cond});
    DELETE ii FROM c_mes_other_stock_in_item ii JOIN c_mes_other_stock_in d ON ii.in_id=d.id WHERE d.reason LIKE '盘点单 PD-TEST%';
    DELETE FROM c_mes_other_stock_in WHERE reason LIKE '盘点单 PD-TEST%';
    DELETE oi FROM c_mes_other_stock_out_item oi JOIN c_mes_other_stock_out d ON oi.out_id=d.id WHERE d.reason LIKE '盘点单 PD-TEST%';
    DELETE FROM c_mes_other_stock_out WHERE reason LIKE '盘点单 PD-TEST%';
    DELETE FROM c_mes_inventory WHERE warehouse_id='${whId}';
    DELETE FROM c_mes_inventory_ledger WHERE warehouse_id='${whId}';
    DELETE FROM c_mes_cost_log WHERE warehouse_id='${whId}';
    UPDATE c_mes_material SET moving_avg_cost=0, last_purchase_price=NULL, last_purchase_date=NULL WHERE id='${matId}';
    DELETE FROM c_mes_material WHERE id='${matId}';
    DELETE FROM c_mes_warehouse WHERE id='${whId}';
  `;
  try {
    execSync(`mysql -uroot -proot --host=127.0.0.1 --protocol=TCP jeecg-boot -e "${sql.replace(/\n/g, ' ').replace(/"/g, '\\"')}"`, { stdio: 'pipe' });
  } catch (e) { console.log('  (DB清理跳过:', e.message.slice(0, 60), ')'); }
}

async function findDoc(token, path, code) {
  const r = await api('GET', `${path}?pageNo=1&pageSize=5&code=${code}`, token);
  return r.result?.records?.[0];
}

async function run() {
  let passed = 0, failed = 0;
  const check = (name, ok, detail) => {
    if (ok) { passed++; console.log(`  ✅ ${name}: ${detail}`); }
    else { failed++; console.error(`  ❌ ${name}: ${detail}`); }
  };

  console.log('\n===== MES 盘点单 API 测试 =====\n');
  const token = await login();
  console.log('  ✅ 登录成功\n');

  const suffix = Date.now();
  const whCode = `WH_STT_${suffix}`;
  const matCode = `MAT_STT_${suffix}`;
  await api('POST', '/mes/basic/warehouse/add', token, { code: whCode, name: '盘点测试仓', status: 1 });
  await api('POST', '/mes/basic/material/add', token, { code: matCode, name: '盘点测试料', type: '1' });
  const whId = (await findDoc(token, '/mes/basic/warehouse/list', whCode))?.id;
  const matId = (await findDoc(token, '/mes/basic/material/list', matCode))?.id;
  check('建仓+造料', !!(whId && matId), `wh=${whId?.slice(-6)} mat=${matId?.slice(-6)}`);

  // 期初入库 100×10
  const inCode = `PDTEST_IN_${suffix}`;
  await api('POST', '/mes/stock/otherIn/add', token, { code: inCode, inType: '2', warehouseId: whId, reason: '期初', stockDate: '2026-07-28', items: [{ materialId: matId, qty: 100, unitCost: 10 }] });
  const inDoc = await findDoc(token, '/mes/stock/otherIn/list', inCode);
  await api('PUT', `/mes/stock/otherIn/audit?id=${inDoc.id}`, token);
  console.log('  ✅ 期初入库 100×10 已审核\n');

  const pdCodes = [`PD-TEST-${suffix}-1`, `PD-TEST-${suffix}-2`, `PD-TEST-${suffix}-3`];

  // ---- 场景1: 全盘创建自动快照 ----
  console.log('--- 场景1: 全盘创建自动快照 ---');
  const add1 = await api('POST', '/mes/stock/stocktake/add', token, { code: pdCodes[0], takeType: '1', warehouseId: whId, takeDate: '2026-07-28' });
  check('创建全盘盘点单', add1.code === 200, add1.message);
  const pd1 = await findDoc(token, '/mes/stock/stocktake/list', pdCodes[0]);
  const detail1 = await api('GET', `/mes/stock/stocktake/queryById?id=${pd1.id}`, token);
  const item1 = detail1.result.items[0];
  check('快照明细 book=100', Number(item1.bookQty) === 100, `book=${item1.bookQty}`);
  check('快照 actual 默认=账面', Number(item1.actualQty) === 100, `actual=${item1.actualQty}`);
  check('快照成本=移动平均10', Number(item1.unitCost) === 10, `cost=${item1.unitCost}`);
  check('snapshotTime 已记录', !!detail1.result.snapshotTime, detail1.result.snapshotTime);

  // ---- 场景2: 实盘95 → 审核 → 盘亏出库 ----
  console.log('\n--- 场景2: 实盘95 盘亏 ---');
  await api('PUT', '/mes/stock/stocktake/edit', token, { id: pd1.id, code: pdCodes[0], takeType: '1', warehouseId: whId, takeDate: '2026-07-28', items: [{ materialId: matId, bookQty: 100, actualQty: 95, unitCost: 10 }] });
  const audit1 = await api('PUT', `/mes/stock/stocktake/audit?id=${pd1.id}`, token);
  check('审核生成盘亏单', audit1.code === 200 && audit1.message.includes('盘亏出库单'), audit1.message);
  const inv1 = await api('GET', `/mes/warehouse/inventory/list?pageNo=1&pageSize=5&warehouseId=${whId}`, token);
  check('库存 100→95', Number(inv1.result.records[0].current_qty) === 95, `qty=${inv1.result.records[0].current_qty}`);
  const mat1 = await api('GET', `/mes/basic/material/queryById?id=${matId}`, token);
  check('移动平均不变=10', Number(mat1.result.movingAvgCost) === 10, `avg=${mat1.result.movingAvgCost}`);
  const detail1b = await api('GET', `/mes/stock/stocktake/queryById?id=${pd1.id}`, token);
  check('generatedOutId 已回写', !!detail1b.result.items[0].generatedOutId, detail1b.result.items[0].generatedOutId?.slice(-6));

  // ---- 场景3: 实盘98 → 审核 → 盘盈入库 ----
  console.log('\n--- 场景3: 实盘98 盘盈 ---');
  await api('POST', '/mes/stock/stocktake/add', token, { code: pdCodes[1], takeType: '1', warehouseId: whId, takeDate: '2026-07-28' });
  const pd2 = await findDoc(token, '/mes/stock/stocktake/list', pdCodes[1]);
  await api('PUT', '/mes/stock/stocktake/edit', token, { id: pd2.id, code: pdCodes[1], takeType: '1', warehouseId: whId, takeDate: '2026-07-28', items: [{ materialId: matId, bookQty: 95, actualQty: 98, unitCost: 10 }] });
  const audit2 = await api('PUT', `/mes/stock/stocktake/audit?id=${pd2.id}`, token);
  check('审核生成盘盈单', audit2.code === 200 && audit2.message.includes('盘盈入库单'), audit2.message);
  const inv2 = await api('GET', `/mes/warehouse/inventory/list?pageNo=1&pageSize=5&warehouseId=${whId}`, token);
  check('库存 95→98', Number(inv2.result.records[0].current_qty) === 98, `qty=${inv2.result.records[0].current_qty}`);

  // ---- 场景4: 守卫 ----
  console.log('\n--- 场景4: 守卫 ---');
  const delAudited = await api('DELETE', `/mes/stock/stocktake/delete?id=${pd1.id}`, token);
  check('已审核单禁止删除', delAudited.code !== 200, delAudited.message);
  await api('POST', '/mes/stock/stocktake/add', token, { code: pdCodes[2], takeType: '1', warehouseId: whId, takeDate: '2026-07-28' });
  const pd3 = await findDoc(token, '/mes/stock/stocktake/list', pdCodes[2]);
  const delDraft = await api('DELETE', `/mes/stock/stocktake/delete?id=${pd3.id}`, token);
  check('草稿可删除', delDraft.code === 200, delDraft.message);

  // ---- 清理（含期初入库单）----
  console.log('\n--- 清理 ---');
  await api('PUT', `/mes/stock/otherIn/unaudit?id=${inDoc.id}`, token);
  await api('DELETE', `/mes/stock/otherIn/delete?id=${inDoc.id}`, token);
  dbCleanup(whId, matId, pdCodes);
  console.log('  ✅ 清理完成\n');

  console.log(`===== 结果: ${passed} 通过, ${failed} 失败 =====`);
  return failed === 0;
}

run().then(ok => process.exit(ok ? 0 : 1)).catch(e => { console.error(e); process.exit(1); });
