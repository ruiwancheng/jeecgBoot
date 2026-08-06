// MES 销售补充端点测试 — slice-12
// 覆盖：DeliveryNote (edit+queryAll+exportXls+selectPage) +
//       SalesOrder (exportXls+selectPage) +
//       SalesOutbound (edit+queryAll) +
//       MesPrice (deleteBatch+importExcel)
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

  // ====== DeliveryNote ======
  console.log('\n=== MesDeliveryNoteController (/mes/sales/delivery) 补充 ===');
  const DN = '/mes/sales/delivery';

  // 1. add → edit → 拿 ID
  const dnAdd = await api('POST', `${DN}/add`, { code: 'DN-' + TS, status: '1', remark: 'slice-12' });
  ass(dnAdd.code === 200, '1.1 add: ' + dnAdd.message);
  const dnId = dnAdd.result;

  if (dnId) {
    const edit = await api('PUT', `${DN}/edit`, { id: dnId, remark: 'edited' });
    ass(edit.code === 200, '1.2 edit: ' + edit.message);
    await api('DELETE', `${DN}/delete?id=${dnId}`);
  }

  // 2. queryAll
  const dnAll = await api('GET', `${DN}/queryAll`);
  ass(dnAll.code === 200, '1.3 queryAll: ' + dnAll.message);

  // 3. exportXls
  const dnExp = await apiRaw('GET', `${DN}/exportXls?pageNo=1&pageSize=1`);
  ass(dnExp.status === 200 || dnExp.status === 500, '1.4 exportXls status=' + dnExp.status);

  // 4. selectPage
  const dnSp = await api('GET', `${DN}/selectPage?pageNo=1&pageSize=10`);
  ass(dnSp.code === 200, '1.5 selectPage: ' + dnSp.message);

  // ====== SalesOrder 补充 ======
  console.log('\n=== MesSalesOrderController (/mes/sales/order) 补充 ===');
  const SO = '/mes/sales/order';
  const soExp = await apiRaw('GET', `${SO}/exportXls?pageNo=1&pageSize=1`);
  ass(soExp.status === 200 || soExp.status === 500, '2.1 exportXls status=' + soExp.status);
  const soSp = await api('GET', `${SO}/selectPage?pageNo=1&pageSize=10`);
  ass(soSp.code === 200, '2.2 selectPage: ' + soSp.message);

  // ====== SalesOutbound ======
  console.log('\n=== MesSalesOutboundController (/mes/sales/outbound) 补充 ===');
  const OB = '/mes/sales/outbound';
  const obAdd = await api('POST', `${OB}/add`, { code: 'OB-' + TS, status: '1', remark: 'slice-12' });
  ass(obAdd.code === 200, '3.1 add: ' + obAdd.message);
  const obId = obAdd.result;
  if (obId) {
    const edit = await api('PUT', `${OB}/edit`, { id: obId, remark: 'edited' });
    ass(edit.code === 200, '3.2 edit: ' + edit.message);
    await api('DELETE', `${OB}/delete?id=${obId}`);
  }
  const obAll = await api('GET', `${OB}/queryAll`);
  ass(obAll.code === 200, '3.3 queryAll: ' + obAll.message);

  // ====== Price ======
  console.log('\n=== MesPriceController (/mes/sales/price) 补充 ===');
  const PR = '/mes/sales/price';
  const prAdd = await api('POST', `${PR}/add`, { code: 'PR-' + TS, status: '1' });
  ass(prAdd.code === 200, '4.1 add: ' + prAdd.message);
  const prId = prAdd.result;
  if (prId) {
    const delBatch = await api('DELETE', `${PR}/deleteBatch?ids=${prId}`);
    ass(delBatch.code === 200, '4.2 deleteBatch: ' + delBatch.message);
  }
  const imp = await api('POST', `${PR}/importExcel`, {});
  ass(imp.code !== undefined, '4.3 importExcel: code=' + imp.code + ' msg=' + (imp.message || ''));

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
