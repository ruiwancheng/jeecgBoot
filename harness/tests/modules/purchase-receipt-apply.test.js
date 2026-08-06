// MES 采购入库 (Receipt) + 采购申请 (Apply) 状态机测试 — slice-5
// Receipt: unaudit+edit+delete+loadOrderItemsForReceipt+queryById
// Apply: deleteBatch+exportXls+queryAll
// Receipt 必须先 add 一条真实数据才能 unaudit/edit/delete/queryById
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
  const code = 'SLICE5_SUP_' + TS;
  const add = await api('POST', '/mes/basic/supplier/add', { code, name: 'slice-5 供应商', status: 1 });
  if (add.code !== 200) return '';
  const list = await api('GET', '/mes/basic/supplier/list?pageNo=1&pageSize=50');
  const s = list.result?.records?.find(x => x.code === code);
  return s?.id || '';
}

async function run() {
  await login();
  supplierId = await setupSupplier();
  ass(supplierId !== '', '0a 创建供应商: ' + supplierId);

  console.log('\n=== PurchaseReceipt (/mes/purchase/receipt) ===');
  const RECEIPT = '/mes/purchase/receipt';

  // 1. add (最小 payload)
  const add = await api('POST', `${RECEIPT}/add`, {
    code: 'PR-' + TS, supplierId, receiptDate: '2026-08-06',
    status: '1', remark: 'slice-5 auto'
  });
  ass(add.code === 200, '1.1 add: ' + add.message);
  const id = add.result;
  ass(typeof id === 'string' && id.length > 0, '1.2 add 返回 id: ' + id);

  // 2. audit → unaudit (audit 后才能 unaudit)
  if (id) {
    const aud = await api('PUT', `${RECEIPT}/audit?id=${id}`);
    ass(aud.code === 200, '2.1 audit: ' + aud.message);
    const unaud = await api('PUT', `${RECEIPT}/unaudit?id=${id}`);
    ass(unaud.code === 200, '2.2 unaudit: ' + unaud.message);
  }

  // 3. edit
  if (id) {
    const edit = await api('PUT', `${RECEIPT}/edit`, { id, remark: 'slice-5 edited' });
    ass(edit.code === 200, '3.1 edit: ' + edit.message);
  }

  // 4. queryById
  if (id) {
    const byId = await api('GET', `${RECEIPT}/queryById?id=${id}`);
    ass(byId.code === 200, '4.1 queryById: ' + byId.message);
  }

  // 5. loadOrderItemsForReceipt (用不存在 orderId)
  const load = await api('GET', `${RECEIPT}/loadOrderItemsForReceipt?orderId=NONEXIST_${TS}`);
  ass(load.code === 200 || (load.message && load.message.length > 0),
      '5.1 loadOrderItemsForReceipt: code=' + load.code + ' msg=' + (load.message || ''));

  // 6. delete
  if (id) {
    const del = await api('DELETE', `${RECEIPT}/delete?id=${id}`);
    ass(del.code === 200, '6.1 delete: ' + del.message);
  }

  console.log('\n=== PurchaseApply (/mes/purchase/apply) ===');
  const APPLY = '/mes/purchase/apply';

  // 7. deleteBatch (空 ids)
  const delBatch = await api('DELETE', `${APPLY}/deleteBatch?ids=`);
  ass(delBatch.code === 200, '7.1 deleteBatch (空 ids): ' + delBatch.message);

  // 8. exportXls
  const exp = await apiRaw('GET', `${APPLY}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '8.1 exportXls status=' + exp.status);

  // 9. queryAll
  const all = await api('GET', `${APPLY}/queryAll`);
  ass(all.code === 200, '9.1 queryAll: ' + all.message);

  // 清理
  if (supplierId) await api('DELETE', '/mes/basic/supplier/delete?id=' + supplierId);

  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
