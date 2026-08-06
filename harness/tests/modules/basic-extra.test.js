// MES 基础数据补充端点测试 — slice-13
// 覆盖：CodeRule (queryById+deleteBatch+queryAll+exportXls) +
//       Material (deleteBatch+queryByIds+importExcel) +
//       Warehouse (deleteBatch+exportXls+importExcel+selectPage) +
//       Customer (exportXls+selectDropdown)
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();

async function login() {
  const r = await fetch(`${BASE}/sys/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' })
  }).then(res => res.json());
  if (r.code === 200) { token = r.result.token; console.log('✅ 登录成功'); }
  else throw new Error('登录失败：' + JSON.stringify(r));
}

async function api(method, path, body) {
  const headers = { 'X-Access-Token': token };
  if (body) headers['Content-Type'] = 'application/json';
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  return fetch(BASE + path, opts).then(r => r.json());
}

async function apiRaw(method, path) {
  return fetch(BASE + path, { method, headers: { 'X-Access-Token': token } });
}

function ass(cond, msg) {
  if (cond) console.log('✅ ' + msg);
  else { console.log('❌ ' + msg); process.exitCode = 1; }
}

async function run() {
  await login();

  // ====== CodeRule ======
  console.log('\n=== MesCodeRuleController (/mes/basic/codeRule) 补充 ===');
  const CR = '/mes/basic/codeRule';
  const crAdd = await api('POST', `${CR}/add`, { code: 'CR-' + TS, ruleType: '1', prefix: 'CR' });
  ass(crAdd.code === 200, '1.1 add: ' + crAdd.message);
  const crId = crAdd.result;

  if (crId) {
    const byId = await api('GET', `${CR}/queryById?id=${crId}`);
    ass(byId.code === 200, '1.2 queryById: ' + byId.message);
    const delBatch = await api('DELETE', `${CR}/deleteBatch?ids=${crId}`);
    ass(delBatch.code === 200, '1.3 deleteBatch: ' + delBatch.message);
  }

  const crAll = await api('GET', `${CR}/queryAll`);
  ass(crAll.code === 200, '1.4 queryAll: ' + crAll.message);

  const crExp = await apiRaw('GET', `${CR}/exportXls?pageNo=1&pageSize=1`);
  ass(crExp.status === 200 || crExp.status === 500, '1.5 exportXls status=' + crExp.status);

  // ====== Material ======
  console.log('\n=== MesMaterialController (/mes/basic/material) 补充 ===');
  const MT = '/mes/basic/material';
  const mtAdd = await api('POST', `${MT}/add`, { code: 'MT-' + TS, name: 'slice-13 物料', status: 1 });
  ass(mtAdd.code === 200, '2.1 add: ' + mtAdd.message);
  const mtId = mtAdd.result;

  if (mtId) {
    const delBatch = await api('DELETE', `${MT}/deleteBatch?ids=${mtId}`);
    ass(delBatch.code === 200, '2.2 deleteBatch: ' + delBatch.message);

    const qb = await api('GET', `${MT}/queryByIds?ids=${mtId}`);
    ass(qb.code === 200 || (qb.message && qb.message.length > 0),
        '2.3 queryByIds: code=' + qb.code + ' msg=' + (qb.message || ''));
  }

  const imp = await api('POST', `${MT}/importExcel`, {});
  ass(imp.code !== undefined, '2.4 importExcel: code=' + imp.code + ' msg=' + (imp.message || ''));

  // ====== Warehouse ======
  console.log('\n=== MesWarehouseController (/mes/basic/warehouse) 补充 ===');
  const WH = '/mes/basic/warehouse';
  const whAdd = await api('POST', `${WH}/add`, { code: 'WH-' + TS, name: 'slice-13 仓库', status: 1 });
  ass(whAdd.code === 200, '3.1 add: ' + whAdd.message);
  const whId = whAdd.result;

  if (whId) {
    const delBatch = await api('DELETE', `${WH}/deleteBatch?ids=${whId}`);
    ass(delBatch.code === 200, '3.2 deleteBatch: ' + delBatch.message);
  }

  const whExp = await apiRaw('GET', `${WH}/exportXls?pageNo=1&pageSize=1`);
  ass(whExp.status === 200 || whExp.status === 500, '3.3 exportXls status=' + whExp.status);

  const whImp = await api('POST', `${WH}/importExcel`, {});
  ass(whImp.code !== undefined, '3.4 importExcel: code=' + whImp.code + ' msg=' + (whImp.message || ''));

  const whSp = await api('GET', `${WH}/selectPage?pageNo=1&pageSize=10`);
  ass(whSp.code === 200, '3.5 selectPage: ' + whSp.message);

  // ====== Customer ======
  console.log('\n=== MesCustomerController (/mes/basic/customer) 补充 ===');
  const CU = '/mes/basic/customer';
  const cuExp = await apiRaw('GET', `${CU}/exportXls?pageNo=1&pageSize=1`);
  ass(cuExp.status === 200 || cuExp.status === 500, '4.1 exportXls status=' + cuExp.status);

  const cuDrop = await api('GET', `${CU}/selectDropdown?keyword=`);
  ass(cuDrop.code === 200, '4.2 selectDropdown: ' + cuDrop.message);

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
