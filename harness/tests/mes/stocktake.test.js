// MES 盘点单 API 测试（全链路：快照→实盘→审核→自动生成调整单→库存校准）
const { dbCleanup: sqlFileCleanup } = require('../helpers/fixtures');
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

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
  const ok = sqlFileCleanup(`
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
  `);
  if (!ok) console.log('  (DB清理不可用，非本地库或 mysql 缺失)');
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

  const pdCodes = [`PD-TEST-${suffix}-1`, `PD-TEST-${suffix}-2`, `PD-TEST-${suffix}-3`, `PD-TEST-${suffix}-4`, `PD-TEST-${suffix}-5`, `PD-TEST-${suffix}-6`, `PD-TEST-${suffix}-7`, `PD-TEST-${suffix}-8`];

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

  // ---- 场景3b: 断言加强（评审建议：generatedInId+金额对账+avg不变+已审核编辑拦截）----
  const detail2b = await api('GET', `/mes/stock/stocktake/queryById?id=${pd2.id}`, token);
  const genInId = detail2b.result.items[0].generatedInId;
  check('generatedInId 已回写', !!genInId, genInId?.slice(-6));
  const genInDoc = await api('GET', `/mes/stock/otherIn/queryById?id=${genInId}`, token);
  check('盘盈入库金额=diffAmount(3×10=30)', Number(genInDoc.result.items[0].amount) === 30, `amount=${genInDoc.result.items[0].amount}`);
  check('盘盈入库单已审核', genInDoc.result.status === '2', `status=${genInDoc.result.status}`);
  const mat2 = await api('GET', `/mes/basic/material/queryById?id=${matId}`, token);
  check('盘盈后移动平均仍不变=10', Number(mat2.result.movingAvgCost) === 10, `avg=${mat2.result.movingAvgCost}`);
  const editAudited = await api('PUT', '/mes/stock/stocktake/edit', token, { id: pd2.id, code: pdCodes[1], takeType: '1', warehouseId: whId, takeDate: '2026-07-28', items: [{ materialId: matId, bookQty: 95, actualQty: 97, unitCost: 10 }] });
  check('已审核单编辑被拒', editAudited.code !== 200, editAudited.message);

  // ---- 场景4: 守卫 ----
  console.log('\n--- 场景4: 守卫 ---');
  const delAudited = await api('DELETE', `/mes/stock/stocktake/delete?id=${pd1.id}`, token);
  check('已审核单禁止删除', delAudited.code !== 200, delAudited.message);
  await api('POST', '/mes/stock/stocktake/add', token, { code: pdCodes[2], takeType: '1', warehouseId: whId, takeDate: '2026-07-28' });
  const pd3 = await findDoc(token, '/mes/stock/stocktake/list', pdCodes[2]);
  const delDraft = await api('DELETE', `/mes/stock/stocktake/delete?id=${pd3.id}`, token);
  check('草稿可删除', delDraft.code === 200, delDraft.message);

  // ---- 场景5: 抽盘校验（评审 P1 盲区）----
  console.log('\n--- 场景5: 抽盘 book_qty 校验 ---');
  const tamperAdd = await api('POST', '/mes/stock/stocktake/add', token, { code: pdCodes[3], takeType: '2', warehouseId: whId, takeDate: '2026-07-28', items: [{ materialId: matId, bookQty: 999, actualQty: 50, unitCost: 10 }] });
  check('抽盘篡改bookQty=999被拒', tamperAdd.code !== 200, tamperAdd.message);
  const validAdd = await api('POST', '/mes/stock/stocktake/add', token, { code: pdCodes[3], takeType: '2', warehouseId: whId, takeDate: '2026-07-28', items: [{ materialId: matId, bookQty: 98, actualQty: 98, unitCost: 10 }] });
  check('抽盘正确bookQty=98通过', validAdd.code === 200, validAdd.message);
  const pd4 = await findDoc(token, '/mes/stock/stocktake/list', pdCodes[3]);
  await api('DELETE', `/mes/stock/stocktake/delete?id=${pd4.id}`, token);

  // ---- 场景6: refreshItems 保留（评审 P1 盲区）----
  console.log('\n--- 场景6: refreshItems 保留实盘数+手工成本 ---');
  await api('POST', '/mes/stock/stocktake/add', token, { code: pdCodes[4], takeType: '1', warehouseId: whId, takeDate: '2026-07-28' });
  const pd5 = await findDoc(token, '/mes/stock/stocktake/list', pdCodes[4]);
  await api('PUT', '/mes/stock/stocktake/edit', token, { id: pd5.id, code: pdCodes[4], takeType: '1', warehouseId: whId, takeDate: '2026-07-28', items: [{ materialId: matId, bookQty: 98, actualQty: 96, unitCost: 12 }] });
  // 出库5制造快照过期（98→93）
  const outCode = `PDTEST_OUT_${suffix}`;
  await api('POST', '/mes/stock/otherOut/add', token, { code: outCode, outType: '3', warehouseId: whId, reason: '领用', stockDate: '2026-07-28', items: [{ materialId: matId, qty: 5, unitCost: 10 }] });
  const outDoc = await findDoc(token, '/mes/stock/otherOut/list', outCode);
  await api('PUT', `/mes/stock/otherOut/audit?id=${outDoc.id}`, token);
  await api('POST', `/mes/stock/stocktake/refreshItems?id=${pd5.id}`, token);
  const detail5 = await api('GET', `/mes/stock/stocktake/queryById?id=${pd5.id}`, token);
  const item5 = detail5.result.items[0];
  check('刷新后book=当前库存93', Number(item5.bookQty) === 93, `book=${item5.bookQty}`);
  check('刷新保留actualQty=96', Number(item5.actualQty) === 96, `actual=${item5.actualQty}`);
  check('刷新保留手工成本=12', Number(item5.unitCost) === 12, `cost=${item5.unitCost}`);
  await api('DELETE', `/mes/stock/stocktake/delete?id=${pd5.id}`, token);
  await api('PUT', `/mes/stock/otherOut/unaudit?id=${outDoc.id}`, token);
  await api('DELETE', `/mes/stock/otherOut/delete?id=${outDoc.id}`, token);

  // ---- 场景7: batchAudit 单事务（评审 P0 盲区）----
  console.log('\n--- 场景7: batchAudit ---');
  await api('POST', '/mes/stock/stocktake/add', token, { code: pdCodes[5], takeType: '1', warehouseId: whId, takeDate: '2026-07-28' });
  const pdA = await findDoc(token, '/mes/stock/stocktake/list', pdCodes[5]);
  await api('POST', '/mes/stock/stocktake/add', token, { code: pdCodes[6], takeType: '1', warehouseId: whId, takeDate: '2026-07-28' });
  const pdB = await findDoc(token, '/mes/stock/stocktake/list', pdCodes[6]);
  const batchOk = await api('POST', '/mes/stock/stocktake/batchAudit', token, { ids: [pdA.id, pdB.id] });
  check('批量审核2条全绿', batchOk.code === 200, batchOk.message);
  const pdAAfter = await api('GET', `/mes/stock/stocktake/queryById?id=${pdA.id}`, token);
  const pdBAfter = await api('GET', `/mes/stock/stocktake/queryById?id=${pdB.id}`, token);
  check('两条均已审核', pdAAfter.result.status === '2' && pdBAfter.result.status === '2', `${pdAAfter.result.status}/${pdBAfter.result.status}`);
  // 混批（已审核+草稿）→ 整体失败且草稿回滚
  await api('POST', '/mes/stock/stocktake/add', token, { code: pdCodes[7], takeType: '1', warehouseId: whId, takeDate: '2026-07-28' });
  const pdC = await findDoc(token, '/mes/stock/stocktake/list', pdCodes[7]);
  const batchMix = await api('POST', '/mes/stock/stocktake/batchAudit', token, { ids: [pdA.id, pdC.id] });
  check('混批(已审核+草稿)失败', batchMix.code !== 200, batchMix.message);
  const pdCAfter = await api('GET', `/mes/stock/stocktake/queryById?id=${pdC.id}`, token);
  check('草稿回滚保持status=1', pdCAfter.result.status === '1', `status=${pdCAfter.result.status}`);
  await api('DELETE', `/mes/stock/stocktake/delete?id=${pdC.id}`, token);

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
