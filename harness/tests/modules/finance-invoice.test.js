// MES 发票模块 CRUD 测试 — P1-2
// PurchaseInvoice + SalesInvoice 真实写入测试
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();

async function login() {
  const r = await fetch(`${BASE}/sys/login`, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: '123456' })
  }).then(res => res.json());
  if (r.code === 200) { token = r.result.token; console.log('✅ 登录成功'); }
  else throw new Error('登录失败');
}

async function api(method, path, body) {
  const headers = { 'X-Access-Token': token };
  if (body) headers['Content-Type'] = 'application/json';
  const opts = { method, headers };
  if (body) opts.body = JSON.stringify(body);
  return fetch(BASE + path, opts).then(r => r.json());
}

function ass(cond, msg) {
  if (cond) console.log('✅ ' + msg);
  else { console.log('❌ ' + msg); process.exitCode = 1; }
}

async function run() {
  await login();

  // ====== 准备客户 + 供应商（发票依赖） ======
  const custAdd = await api('POST', '/mes/basic/customer/add', { code: 'INV_CUST_' + TS, name: '发票测试客户', status: 1 });
  const custId = custAdd.code === 200
    ? (await api('GET', '/mes/basic/customer/list?pageNo=1&pageSize=20')).result?.records?.find(x => x.code === 'INV_CUST_' + TS)?.id || ''
    : '';
  ass(custId !== '', '0a 创建客户: ' + custId);

  const supAdd = await api('POST', '/mes/basic/supplier/add', { code: 'INV_SUP_' + TS, name: '发票测试供应商', status: 1 });
  const supId = supAdd.code === 200
    ? (await api('GET', '/mes/basic/supplier/list?pageNo=1&pageSize=20')).result?.records?.find(x => x.code === 'INV_SUP_' + TS)?.id || ''
    : '';
  ass(supId !== '', '0b 创建供应商: ' + supId);

  // ====== 1. SalesInvoice CRUD ======
  console.log('\n=== 销项发票 SalesInvoice CRUD ===');
  const siCode = 'SI-' + TS;

  // 1.1 add
  const siAdd = await api('POST', '/mes/finance/salesInvoice/add', {
    code: siCode, customerId: custId, invoiceNo: 'INV-NO-' + TS,
    invoiceDate: '2026-08-06', amount: 1000, taxAmount: 130, status: '1'
  });
  ass(siAdd.code === 200, '1.1 SalesInvoice add: ' + siAdd.message);

  // 1.2 list 查到
  const siList = await api('GET', '/mes/finance/salesInvoice/list?pageNo=1&pageSize=20');
  const si = siList.result?.records?.find(x => x.code === siCode);
  ass(si, '1.2 SalesInvoice list 查到: ' + siCode);
  const siId = si?.id || '';

  // 1.3 queryById
  if (siId) {
    const siGet = await api('GET', '/mes/finance/salesInvoice/queryById?id=' + siId);
    ass(siGet.code === 200 && siGet.result?.code === siCode, '1.3 queryById: ' + siGet.result?.code);
  }

  // 1.4 edit
  if (siId) {
    const siEdit = await api('PUT', '/mes/finance/salesInvoice/edit', { id: siId, amount: 2000 });
    ass(siEdit.code === 200, '1.4 edit amount→2000: ' + siEdit.message);
  }

  // 1.5 delete
  if (siId) {
    const siDel = await api('DELETE', '/mes/finance/salesInvoice/delete?id=' + siId);
    ass(siDel.code === 200, '1.5 delete: ' + siDel.message);
  }

  // ====== 2. PurchaseInvoice CRUD ======
  console.log('\n=== 进项发票 PurchaseInvoice CRUD ===');
  const piCode = 'PI-' + TS;

  // 2.1 add
  const piAdd = await api('POST', '/mes/finance/purchaseInvoice/add', {
    code: piCode, supplierId: supId, invoiceNo: 'PI-NO-' + TS,
    invoiceDate: '2026-08-06', amount: 500, taxAmount: 65, status: '1'
  });
  ass(piAdd.code === 200, '2.1 PurchaseInvoice add: ' + piAdd.message);

  // 2.2 list 查到
  const piList = await api('GET', '/mes/finance/purchaseInvoice/list?pageNo=1&pageSize=20');
  const pi = piList.result?.records?.find(x => x.code === piCode);
  ass(pi, '2.2 PurchaseInvoice list 查到: ' + piCode);
  const piId = pi?.id || '';

  // 2.3 queryById
  if (piId) {
    const piGet = await api('GET', '/mes/finance/purchaseInvoice/queryById?id=' + piId);
    ass(piGet.code === 200 && piGet.result?.code === piCode, '2.3 queryById: ' + piGet.result?.code);
  }

  // 2.4 edit
  if (piId) {
    const piEdit = await api('PUT', '/mes/finance/purchaseInvoice/edit', { id: piId, amount: 1000 });
    ass(piEdit.code === 200, '2.4 edit amount→1000: ' + piEdit.message);
  }

  // 2.5 delete
  if (piId) {
    const piDel = await api('DELETE', '/mes/finance/purchaseInvoice/delete?id=' + piId);
    ass(piDel.code === 200, '2.5 delete: ' + piDel.message);
  }

  // ====== 3. 清理 ======
  if (custId) await api('DELETE', '/mes/basic/customer/delete?id=' + custId);
  if (supId) await api('DELETE', '/mes/basic/supplier/delete?id=' + supId);
  console.log('✅ 清理完成');

  console.log(process.exitCode ? '❌ 有失败项' : '✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
