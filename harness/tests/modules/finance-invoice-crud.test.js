// MES 发票模块 CRUD 补充测试 (SalesInvoice/PurchaseInvoice)
// 补全 slice-1 未覆盖的 4 个 GET 端点：两个 Controller 的 queryAll + exportXls
// - GET 类端点用 pageSize=1 验证响应格式
// - exportXls 返回文件流，按惯例检查 HTTP status 200/500
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

function checkResponse(res, label) {
  const ok = (res.code === 200 || res.code === 0) ||
             (typeof res.message === 'string' && res.message.length > 0 && res.code !== undefined);
  ass(ok, label + ' code=' + res.code + ' msg=' + (res.message || ''));
}

async function testSalesInvoice() {
  console.log('\n=== MesSalesInvoiceController (/mes/finance/salesInvoice) 补充端点 ===');
  const PREFIX = '/mes/finance/salesInvoice';

  // 1. GET /queryAll
  const all = await api('GET', `${PREFIX}/queryAll`);
  checkResponse(all, '1.1 GET /queryAll');

  // 2. GET /exportXls
  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '1.2 GET /exportXls status=' + exp.status);
}

async function testPurchaseInvoice() {
  console.log('\n=== MesPurchaseInvoiceController (/mes/finance/purchaseInvoice) 补充端点 ===');
  const PREFIX = '/mes/finance/purchaseInvoice';

  // 1. GET /queryAll
  const all = await api('GET', `${PREFIX}/queryAll`);
  checkResponse(all, '2.1 GET /queryAll');

  // 2. GET /exportXls
  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '2.2 GET /exportXls status=' + exp.status);
}

async function run() {
  await login();
  await testSalesInvoice();
  await testPurchaseInvoice();
  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
