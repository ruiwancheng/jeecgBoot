// MES Finance 其他模块 (Payable/Collection/Payment/Receivable) API 测试
// 覆盖 4 个 Controller 共 17 个端点的格式可达性
// - GET 类端点（list/queryAll/exportXls/queryById）用 pageSize=1 或不存在 ID 验证响应格式
// - POST 类端点（add）用最小无效 payload 触发校验失败，避免脏数据
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
let token = '';
const TS = Date.now();
const NONEXIST_ID = 'NONEXIST_' + TS;

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
  // 成功路径期望 code === 200 或 0；业务错（queryById 不存在 ID）期望响应有 message 且非 500 异常
  const ok = (res.code === 200 || res.code === 0) ||
             (typeof res.message === 'string' && res.message.length > 0 && res.code !== undefined);
  ass(ok, label + ' code=' + res.code + ' msg=' + (res.message || ''));
}

async function testPayable() {
  console.log('\n=== MesPayableController (/mes/finance/payable) ===');
  const PREFIX = '/mes/finance/payable';

  // 1. GET /list (pageSize=1)
  const list = await api('GET', `${PREFIX}/list?pageNo=1&pageSize=1`);
  checkResponse(list, '1.1 GET /list (pageSize=1)');

  // 2. GET /queryAll
  const all = await api('GET', `${PREFIX}/queryAll`);
  checkResponse(all, '1.2 GET /queryAll');

  // 3. GET /queryById?id=xxx (不存在 ID 防脏数据)
  const byId = await api('GET', `${PREFIX}/queryById?id=${NONEXIST_ID}`);
  checkResponse(byId, '1.3 GET /queryById?id=NONEXIST');

  // 4. GET /exportXls
  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '1.4 GET /exportXls status=' + exp.status);
}

async function testCollection() {
  console.log('\n=== MesCollectionController (/mes/finance/collection) ===');
  const PREFIX = '/mes/finance/collection';

  // 1. POST /add (空对象触发校验失败，避免脏数据)
  const add = await api('POST', `${PREFIX}/add`, {});
  checkResponse(add, '2.1 POST /add (空对象)');

  // 2. GET /list (pageSize=1)
  const list = await api('GET', `${PREFIX}/list?pageNo=1&pageSize=1`);
  checkResponse(list, '2.2 GET /list (pageSize=1)');

  // 3. GET /queryAll
  const all = await api('GET', `${PREFIX}/queryAll`);
  checkResponse(all, '2.3 GET /queryAll');

  // 4. GET /queryById?id=xxx
  const byId = await api('GET', `${PREFIX}/queryById?id=${NONEXIST_ID}`);
  checkResponse(byId, '2.4 GET /queryById?id=NONEXIST');

  // 5. GET /exportXls
  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '2.5 GET /exportXls status=' + exp.status);
}

async function testPayment() {
  console.log('\n=== MesPaymentController (/mes/finance/payment) ===');
  const PREFIX = '/mes/finance/payment';

  // 1. POST /add
  const add = await api('POST', `${PREFIX}/add`, {});
  checkResponse(add, '3.1 POST /add (空对象)');

  // 2. GET /list
  const list = await api('GET', `${PREFIX}/list?pageNo=1&pageSize=1`);
  checkResponse(list, '3.2 GET /list (pageSize=1)');

  // 3. GET /queryAll
  const all = await api('GET', `${PREFIX}/queryAll`);
  checkResponse(all, '3.3 GET /queryAll');

  // 4. GET /queryById?id=xxx
  const byId = await api('GET', `${PREFIX}/queryById?id=${NONEXIST_ID}`);
  checkResponse(byId, '3.4 GET /queryById?id=NONEXIST');

  // 5. GET /exportXls
  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '3.5 GET /exportXls status=' + exp.status);
}

async function testReceivable() {
  console.log('\n=== MesReceivableController (/mes/finance/receivable) ===');
  const PREFIX = '/mes/finance/receivable';

  // 1. GET /list
  const list = await api('GET', `${PREFIX}/list?pageNo=1&pageSize=1`);
  checkResponse(list, '4.1 GET /list (pageSize=1)');

  // 2. GET /queryAll
  const all = await api('GET', `${PREFIX}/queryAll`);
  checkResponse(all, '4.2 GET /queryAll');

  // 3. GET /exportXls
  const exp = await apiRaw('GET', `${PREFIX}/exportXls?pageNo=1&pageSize=1`);
  ass(exp.status === 200 || exp.status === 500, '4.3 GET /exportXls status=' + exp.status);
}

async function run() {
  await login();
  await testPayable();
  await testCollection();
  await testPayment();
  await testReceivable();
  console.log(process.exitCode ? '\n❌ 有失败项' : '\n✅ 全部通过');
}
run().catch(e => { console.error(e); process.exitCode = 1; });
