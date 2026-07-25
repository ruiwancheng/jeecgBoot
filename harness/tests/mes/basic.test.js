// MES 基础设置 API 测试
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

async function run() {
  let passed = 0, failed = 0;
  const check = (name, ok, detail) => {
    if (ok) { passed++; console.log(`  ✅ ${name}: ${detail}`); }
    else { failed++; console.error(`  ❌ ${name}: ${detail}`); }
  };

  console.log('\n===== MES 基础设置 API 测试 =====\n');

  // ---- 登录 ----
  const token = await login();
  console.log('  ✅ 登录成功\n');

  // ---- 仓库管理 ----
  console.log('--- 仓库管理 ---');

  // 1. 列表查询（空数据）
  const r1 = await api('GET', '/mes/basic/warehouse/list?pageNo=1&pageSize=10', token);
  check('仓库列表(空)', r1.code === 200 && r1.result.total === 0, `total=${r1.result.total}`);

  // 2. 新增仓库
  const r2 = await api('POST', '/mes/basic/warehouse/add', token, { code: 'TEST_WH01', name: '测试原料仓', type: '1', status: 1 });
  check('新增仓库', r2.code === 200, r2.message);

  // 3. 重复编码校验
  const r3 = await api('POST', '/mes/basic/warehouse/add', token, { code: 'TEST_WH01', name: '重复编码测试', type: '2', status: 1 });
  check('重复编码校验', r3.code === 500, r3.message);

  // 4. 新增第二个仓库
  const r4 = await api('POST', '/mes/basic/warehouse/add', token, { code: 'TEST_WH02', name: '测试成品仓', type: '2', status: 1 });
  check('新增第二个仓库', r4.code === 200, r4.message);

  // 5. 查询全部（用于树）
  const r5 = await api('GET', '/mes/basic/warehouse/queryAll', token);
  check('queryAll', r5.code === 200 && r5.result.length >= 2, `count=${r5.result.length}`);

  // 获取两个仓库的ID
  const list = await api('GET', '/mes/basic/warehouse/list?pageNo=1&pageSize=10', token);
  const wh1 = list.result.records.find(r => r.code === 'TEST_WH01');
  const wh2 = list.result.records.find(r => r.code === 'TEST_WH02');
  const wh1Id = wh1.id, wh2Id = wh2.id;

  // 6. 编辑仓库
  const r6 = await api('PUT', '/mes/basic/warehouse/edit', token, { id: wh1Id, code: 'TEST_WH01', name: '测试原料仓-改', type: '1', status: 1 });
  check('编辑仓库', r6.code === 200, r6.message);

  // ---- 库位管理 ----
  console.log('\n--- 库位管理 ---');

  // 7. 列表查询
  const r7 = await api('GET', '/mes/basic/location/list?pageNo=1&pageSize=10', token);
  check('库位列表(空)', r7.code === 200, `total=${r7.result.total}`);

  // 8. 新增库位
  const r8 = await api('POST', '/mes/basic/location/add', token, { warehouseId: wh1Id, code: 'A-01-01', name: 'A区01排', type: '1', status: 1 });
  check('新增库位', r8.code === 200, r8.message);

  // 9. 同仓库重复编码
  const r9 = await api('POST', '/mes/basic/location/add', token, { warehouseId: wh1Id, code: 'A-01-01', type: '1', status: 1 });
  check('库位重复编码', r9.code === 500, r9.message);

  // 10. 批量生成
  const r10 = await api('POST', '/mes/basic/location/generate', token, { warehouseId: wh1Id, area: 'B', channelRows: 2, channelCols: 2, shelfRows: 2, shelfCols: 2 });
  check('批量生成(B区2x2x2x2)', r10.code === 200 && r10.result.length === 16, `${r10.result.length}条, 首条=${r10.result[0]}`);

  // 11. 按仓库筛选
  const r11 = await api('GET', `/mes/basic/location/list?pageNo=1&pageSize=20&warehouseId=${wh1Id}`, token);
  check('按仓库筛选库位', r11.code === 200 && r11.result.total === 17, `total=${r11.result.total}`);

  // 12. 库位编辑
  const loc = r11.result.records[0];
  const r12 = await api('PUT', '/mes/basic/location/edit', token, { id: loc.id, warehouseId: wh1Id, code: loc.code, name: '改后库位', type: '1', status: 1 });
  check('编辑库位', r12.code === 200, r12.message);

  // ---- 删除保护 ----
  console.log('\n--- 删除保护 ---');

  // 13. 删除有库位的仓库(应拒绝)
  const r13 = await api('DELETE', `/mes/basic/warehouse/delete?id=${wh1Id}`, token);
  check('删除有库位仓库(拒绝)', r13.code === 500, r13.message);

  // 14. 删除无库位仓库(应成功)
  const r14 = await api('DELETE', `/mes/basic/warehouse/delete?id=${wh2Id}`, token);
  check('删除无库位仓库(成功)', r14.code === 200, r14.message);

  // ---- 报告 ----
  console.log(`\n===== 结果: ${passed} 通过, ${failed} 失败 =====`);
  return failed === 0;
}

run().then(ok => process.exit(ok ? 0 : 1)).catch(e => { console.error(e); process.exit(1); });
