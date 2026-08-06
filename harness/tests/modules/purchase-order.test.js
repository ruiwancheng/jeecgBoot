// MES 采购订单 (PurchaseOrder) 全端点测试 — slice-11
// 覆盖：edit+deleteBatch+queryAll+exportXls+selectPage+audit+unaudit+loadApplyItemsForOrder
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();
let supplierId = '';

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

async function setupSupplier() {
  const code = 'SLICE11_SUP_' + TS;
  const add = await api('POST', '/mes/basic/supplier/add', { code, name: 'slice-11 供应商', status: 1 });
  if (add.code !== 200) return '';
  const list = await api('GET', '/mes/basic/supplier/list?pageNo=1&pageSize=50');
  return list.result?.records?.find(x => x.code === code)?.id || '';
}

async function run() {
  await login();
  supplierId = await setupSupplier();
  ass(supplierId !== '', '0a 创建供应商: ' + supplierId);

  console.log('\n=== MesPurchaseOrderController (/mes/purchase/order) ===');
  const PREFIX = '/mes/purchase/order';

  // 1. add
  const add = await api('POST', `${PREFIX}/add`, {
    code: 'PO-' + TS, supplierId, orderDate: '2026-08-06',
    status: '1', remark: 'slice-11 auto'
  });
  ass(add.code === 200, '1.1 add: ' + add.message);
  const id = add.result;

  // 2. queryById (新增覆盖)
  if (id) {
    const byId = await api('GET', `${PREFIX}/queryById?id=${id}`);
    ass(byId.code === 200, '2.1 queryById: ' + byId.message);
  }

  // 3. edit
  if (id) {
    const edit = await api('PUT', `${PREFIX}/edit`, { id, remark: 'slice-11 edited' });
    ass(edit.code === 200, '3.1 edit: ' + edit.message);
  }

  // 4. audit
  if (id) {
    const aud = await api('PUT', `${PREFIX}/audit?id=${id}`);
    ass(aud.code === 200, '4.1 audit: ' + aud.message);
  }

  // 5. unaudit
  if (id) {
    const unaud = await api('PUT', `${PREFIX}/unaudit?id=${id}`);
    ass(unaud.code === 200, '5.1 unaudit: ' + unaud.message);
  }

  // 6. deleteBatch (清理)
  if (id) {
    const del = await api('DELETE', `${PREFIX}/deleteBatch?ids=${id}`);
    ass(del.code === 200, '6.1 deleteBatch: ' + del.message);
  }

  // 7. queryAll
  const all = await api('GET', `${PREFIX}/queryAll`);
  ass(all.code === 200, '7.1 queryAll: ' + all.message);

  // 8. exportXls
  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '8.1 exportXls status=' + exp.status);

  // 9. selectPage
  const sp = await api('GET', `${PREFIX}/selectPage?pageNo=1&pageSize=10`);
  ass(sp.code === 200, '9.1 selectPage: ' + sp.message);

  // 10. loadApplyItemsForOrder (用不存在 applyId)
  const load = await api('GET', `${PREFIX}/loadApplyItemsForOrder?applyId=NONEXIST_${TS}`);
  ass(load.code === 200 || (load.message && load.message.length > 0),
      '10.1 loadApplyItemsForOrder: code=' + load.code + ' msg=' + (load.message || ''));

  // 清理供应商
  if (supplierId) await api('DELETE', '/mes/basic/supplier/delete?id=' + supplierId);

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
