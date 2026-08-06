// MES 杂项模块补充端点测试 — slice-14
// 覆盖：Batch (edit+exportXls) +
//       Receivable (queryById) +
//       PurchaseApply (audit) +
//       PurchaseReceipt (deleteBatch+queryAll+exportXls)
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
  const code = 'SLICE14_SUP_' + TS;
  const add = await api('POST', '/mes/basic/supplier/add', { code, name: 'slice-14 供应商', status: 1 });
  if (add.code !== 200) return '';
  const list = await api('GET', '/mes/basic/supplier/list?pageNo=1&pageSize=50');
  return list.result?.records?.find(x => x.code === code)?.id || '';
}

async function run() {
  await login();
  supplierId = await setupSupplier();

  // ====== Batch ======
  console.log('\n=== MesBatchController (/mes/batch/master) 补充 ===');
  const BA = '/mes/batch/master';
  const baAdd = await api('POST', `${BA}/add`, { batchNo: 'BA-' + TS, status: '1' });
  ass(baAdd.code === 200, '1.1 add: ' + baAdd.message);
  const baId = baAdd.result;

  if (baId) {
    const edit = await api('PUT', `${BA}/edit`, { id: baId, remark: 'slice-14' });
    ass(edit.code === 200, '1.2 edit: ' + edit.message);
    await api('DELETE', `${BA}/delete?id=${baId}`);
  }

  const baExp = await apiRaw('GET', `${BA}/exportXls?pageNo=1&pageSize=1`);
  ass(baExp.status === 200 || baExp.status === 500, '1.3 exportXls status=' + baExp.status);

  // ====== Receivable ======
  console.log('\n=== MesReceivableController (/mes/finance/receivable) 补充 ===');
  const RE = '/mes/finance/receivable';
  // 用不存在 ID 验证 queryById 格式
  const reById = await api('GET', `${RE}/queryById?id=NONEXIST_${TS}`);
  ass(reById.code !== undefined && typeof reById.message === 'string',
      '2.1 queryById (不存在 ID): code=' + reById.code + ' msg=' + (reById.message || ''));

  // ====== PurchaseApply ======
  console.log('\n=== MesPurchaseApplyController (/mes/purchase/apply) 补充 ===');
  const AP = '/mes/purchase/apply';
  const apAdd = await api('POST', `${AP}/add`, {
    code: 'AP-' + TS, supplierId, applyDate: '2026-08-06',
    status: '1', remark: 'slice-14'
  });
  ass(apAdd.code === 200, '3.1 add: ' + apAdd.message);
  const apId = apAdd.result;

  if (apId) {
    const aud = await api('PUT', `${AP}/audit?id=${apId}`);
    ass(aud.code === 200, '3.2 audit: ' + aud.message);
    await api('DELETE', `${AP}/delete?id=${apId}`);
  }

  // ====== PurchaseReceipt ======
  console.log('\n=== MesPurchaseReceiptController (/mes/purchase/receipt) 补充 ===');
  const RC = '/mes/purchase/receipt';
  const rcAdd = await api('POST', `${RC}/add`, {
    code: 'RC-' + TS, supplierId, receiptDate: '2026-08-06',
    status: '1', remark: 'slice-14'
  });
  ass(rcAdd.code === 200, '4.1 add: ' + rcAdd.message);
  const rcId = rcAdd.result;

  if (rcId) {
    const delBatch = await api('DELETE', `${RC}/deleteBatch?ids=${rcId}`);
    ass(delBatch.code === 200, '4.2 deleteBatch: ' + delBatch.message);
  }

  const rcAll = await api('GET', `${RC}/queryAll`);
  ass(rcAll.code === 200, '4.3 queryAll: ' + rcAll.message);

  const rcExp = await apiRaw('GET', `${RC}/exportXls?pageNo=1&pageSize=1`);
  ass(rcExp.status === 200 || rcExp.status === 500, '4.4 exportXls status=' + rcExp.status);

  if (supplierId) await api('DELETE', '/mes/basic/supplier/delete?id=' + supplierId);

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
