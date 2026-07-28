// MES 其它入库 B+A+ 成本联动 API 测试
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

async function findByCode(token, code) {
  const r = await api('GET', `/mes/stock/otherIn/list?pageNo=1&pageSize=5&code=${code}`, token);
  return r.result.records[0];
}

async function run() {
  let passed = 0, failed = 0;
  const check = (name, ok, detail) => {
    if (ok) { passed++; console.log(`  ✅ ${name}: ${detail}`); }
    else { failed++; console.error(`  ❌ ${name}: ${detail}`); }
  };

  console.log('\n===== MES 其它入库 B+A+ 成本联动测试 =====\n');

  const token = await login();
  console.log('  ✅ 登录成功\n');

  // 准备：造一个测试物料 + 取一个仓库
  const suffix = Date.now();
  const matCode = `MAT_OST_${suffix}`;
  const matRes = await api('POST', '/mes/basic/material/add', token, { code: matCode, name: '成本联动测试料', type: '1' });
  check('创建测试物料', matRes.code === 200, matRes.message);
  const matList = await api('GET', `/mes/basic/material/list?pageNo=1&pageSize=5&code=${matCode}`, token);
  const matId = matList.result.records[0]?.id;

  const whList = await api('GET', '/mes/basic/warehouse/list?pageNo=1&pageSize=1', token);
  const whId = whList.result.records[0]?.id;
  check('获取仓库', !!whId, `id=${whId}`);

  // ---- 场景 1：首次入库初始化移动平均 ----
  console.log('\n--- 场景 1：首次入库 10×25.5 ---');
  const code1 = `OST_${suffix}_01`;
  const add1 = await api('POST', '/mes/stock/otherIn/add', token, {
    code: code1, inType: '2', warehouseId: whId, reason: 'B+A+ 验证', stockDate: '2026-07-28',
    items: [{ materialId: matId, qty: 10, unitCost: 25.5 }]
  });
  check('新增入库单1', add1.code === 200, add1.message);
  const doc1 = await findByCode(token, code1);
  const audit1 = await api('PUT', `/mes/stock/otherIn/audit?id=${doc1.id}`, token);
  check('审核入库单1', audit1.code === 200, audit1.message);

  const cost1 = await api('GET', `/mes/basic/material/queryById?id=${matId}`, token);
  check('移动平均=25.5', cost1.result.movingAvgCost === 25.5, `actual=${cost1.result.movingAvgCost}`);

  // ---- 场景 2：二次入库加权平均 ----
  console.log('\n--- 场景 2：二次入库 10×30，期望 27.75 ---');
  const code2 = `OST_${suffix}_02`;
  await api('POST', '/mes/stock/otherIn/add', token, {
    code: code2, inType: '2', warehouseId: whId, reason: 'B+A+ 验证', stockDate: '2026-07-28',
    items: [{ materialId: matId, qty: 10, unitCost: 30 }]
  });
  const doc2 = await findByCode(token, code2);
  await api('PUT', `/mes/stock/otherIn/audit?id=${doc2.id}`, token);

  const cost2 = await api('GET', `/mes/basic/material/queryById?id=${matId}`, token);
  check('移动平均=27.75', cost2.result.movingAvgCost === 27.75, `actual=${cost2.result.movingAvgCost}`);

  // ---- 场景 3：0 成本跳过 ----
  console.log('\n--- 场景 3：0 成本入库应跳过 ---');
  const code3 = `OST_${suffix}_03`;
  await api('POST', '/mes/stock/otherIn/add', token, {
    code: code3, inType: '2', warehouseId: whId, reason: '0 cost skip', stockDate: '2026-07-28',
    items: [{ materialId: matId, qty: 1, unitCost: 0 }]
  });
  const doc3 = await findByCode(token, code3);
  await api('PUT', `/mes/stock/otherIn/audit?id=${doc3.id}`, token);

  const cost3 = await api('GET', `/mes/basic/material/queryById?id=${matId}`, token);
  check('0成本后平均仍为27.75', cost3.result.movingAvgCost === 27.75, `actual=${cost3.result.movingAvgCost}`);

  // ---- 场景 4：出库不更新成本 ----
  console.log('\n--- 场景 4：出库 3×30，平均应保持 27.75 ---');
  const codeOut = `OSO_${suffix}_01`;
  await api('POST', '/mes/stock/otherOut/add', token, {
    code: codeOut, outType: '2', warehouseId: whId, reason: 'B+A+ 验证', stockDate: '2026-07-28',
    items: [{ materialId: matId, qty: 3, unitCost: 30 }]
  });
  const docOut = await api('GET', `/mes/stock/otherOut/list?pageNo=1&pageSize=5&code=${codeOut}`, token);
  await api('PUT', `/mes/stock/otherOut/audit?id=${docOut.result.records[0].id}`, token);

  const cost4 = await api('GET', `/mes/basic/material/queryById?id=${matId}`, token);
  check('出库后平均仍为27.75', cost4.result.movingAvgCost === 27.75, `actual=${cost4.result.movingAvgCost}`);

  // ---- 场景 5：台账成本差异列 ----
  console.log('\n--- 场景 5：台账差异列 ---');
  const ledger = await api('GET', '/mes/warehouse/ledger/list?pageNo=1&pageSize=10', token);
  const diffRow = ledger.result.records.find(r => r.bizType === '其它出库' && r.unitCost === 30);
  check('手工出库差异=6.75', diffRow && diffRow.costDiff === 6.75, `costDiff=${diffRow?.costDiff}`);

  // ---- 清理 ----
  console.log('\n--- 清理 ---');
  for (const code of [code1, code2, code3]) {
    const doc = await findByCode(token, code);
    if (doc) {
      await api('PUT', `/mes/stock/otherIn/unaudit?id=${doc.id}`, token);
      await api('DELETE', `/mes/stock/otherIn/delete?id=${doc.id}`, token);
    }
  }
  const outDoc = await api('GET', `/mes/stock/otherOut/list?pageNo=1&pageSize=5&code=${codeOut}`, token);
  if (outDoc.result.records[0]) {
    await api('PUT', `/mes/stock/otherOut/unaudit?id=${outDoc.result.records[0].id}`, token);
    await api('DELETE', `/mes/stock/otherOut/delete?id=${outDoc.result.records[0].id}`, token);
  }
  await api('DELETE', `/mes/basic/material/delete?id=${matId}`, token);
  console.log('  ✅ 清理完成\n');

  console.log(`===== 结果: ${passed} 通过, ${failed} 失败 =====`);
  return failed === 0;
}

run().then(ok => process.exit(ok ? 0 : 1)).catch(e => { console.error(e); process.exit(1); });
